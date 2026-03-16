local log = require("smart-motion.core.log")
local pair_defs = require("smart-motion.utils.pair_defs")

---@type SmartMotionCollectorModuleEntry
local M = {}

--- Scans visible lines for matching delimiter pairs using a stack-based approach.
--- @param bufnr integer
--- @param start_line integer 0-indexed
--- @param end_line integer 0-indexed (inclusive)
--- @param open_char string
--- @param close_char string
--- @return table[] List of pair data objects
local function scan_pairs_pattern(bufnr, start_line, end_line, open_char, close_char)
	local results = {}
	local is_symmetric = (open_char == close_char)

	if is_symmetric then
		-- For symmetric delimiters (quotes), find pairs on the same line
		for line_num = start_line, end_line do
			local line = vim.api.nvim_buf_get_lines(bufnr, line_num, line_num + 1, false)[1]
			if line then
				local positions = {}
				local i = 1
				while i <= #line do
					local ch = line:sub(i, i)
					-- Skip escaped delimiters
					if i > 1 and line:sub(i - 1, i - 1) == "\\" then
						i = i + 1
						goto continue
					end
					if ch == open_char then
						table.insert(positions, i - 1) -- 0-indexed col
					end
					i = i + 1
					::continue::
				end

				-- Pair them up: 1st with 2nd, 3rd with 4th, etc.
				for j = 1, #positions - 1, 2 do
					local open_col = positions[j]
					local close_col = positions[j + 1]
					local content = line:sub(open_col + 2, close_col) -- between delimiters
					table.insert(results, {
						open_pos = {
							start = { row = line_num, col = open_col },
							["end"] = { row = line_num, col = open_col + #open_char },
						},
						close_pos = {
							start = { row = line_num, col = close_col },
							["end"] = { row = line_num, col = close_col + #close_char },
						},
						pair_open = open_char,
						pair_close = close_char,
						content_text = content,
						full_text = open_char .. content .. close_char,
					})
				end
			end
		end
	else
		-- For asymmetric delimiters, use a stack-based scanner
		local stack = {}

		for line_num = start_line, end_line do
			local line = vim.api.nvim_buf_get_lines(bufnr, line_num, line_num + 1, false)[1]
			if line then
				for col = 0, #line - 1 do
					local ch = line:sub(col + 1, col + 1)
					if ch == open_char then
						table.insert(stack, { row = line_num, col = col })
					elseif ch == close_char and #stack > 0 then
						local open = table.remove(stack)
						-- Get content between delimiters
						local content_lines = vim.api.nvim_buf_get_text(
							bufnr,
							open.row,
							open.col + #open_char,
							line_num,
							col,
							{}
						)
						local content = table.concat(content_lines, "\n")
						table.insert(results, {
							open_pos = {
								start = { row = open.row, col = open.col },
								["end"] = { row = open.row, col = open.col + #open_char },
							},
							close_pos = {
								start = { row = line_num, col = col },
								["end"] = { row = line_num, col = col + #close_char },
							},
							pair_open = open_char,
							pair_close = close_char,
							content_text = content,
							full_text = open_char .. content .. close_char,
						})
					end
				end
			end
		end
	end

	return results
end

--- Collects matching delimiter pairs in visible buffer.
--- Reads motion_state.pair_chars to know which pair to find.
--- @return thread A coroutine generator yielding pair data objects
function M.run()
	return coroutine.create(function(ctx, cfg, motion_state)
		local bufnr = ctx.bufnr
		local pair_chars = motion_state.pair_chars

		if not pair_chars or #pair_chars == 0 then
			log.debug("Pairs collector: no pair_chars specified in motion_state")
			return
		end

		-- Determine visible range
		local winid = ctx.winid or 0
		local start_line = vim.fn.line("w0", winid) - 1 -- 0-indexed
		local end_line = vim.fn.line("w$", winid) - 1

		for _, pair in ipairs(pair_chars) do
			local open_char = pair[1]
			local close_char = pair[2]

			-- Try treesitter first for better accuracy, but fall back to
			-- pattern scanning if the tree has errors (common while editing)
			local ts_results = nil
			local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
			if ok and parser then
				local trees = parser:parse()
				if trees and trees[1] then
					local root = trees[1]:root()
					if not root:has_error() then
						ts_results = {}
						M._collect_ts_pairs(root, bufnr, open_char, close_char, start_line, end_line, ts_results)
					end
				end
			end

			local results = ts_results and #ts_results > 0 and ts_results
				or scan_pairs_pattern(bufnr, start_line, end_line, open_char, close_char)

			for _, result in ipairs(results) do
				coroutine.yield(result)
			end
		end
	end)
end

--- Recursively collects delimiter pairs from treesitter nodes.
--- Looks for nodes whose first/last children match the delimiter chars.
--- @param node TSNode
--- @param bufnr integer
--- @param open_char string
--- @param close_char string
--- @param start_line integer
--- @param end_line integer
--- @param results table[]
function M._collect_ts_pairs(node, bufnr, open_char, close_char, start_line, end_line, results)
	local child_count = node:child_count()

	if child_count >= 2 then
		local first = node:child(0)
		local last = node:child(child_count - 1)

		if first and last then
			local first_text = vim.treesitter.get_node_text(first, bufnr)
			local last_text = vim.treesitter.get_node_text(last, bufnr)

			if first_text == open_char and last_text == close_char then
				local fsr, fsc, fer, fec = first:range()
				local lsr, lsc, ler, lec = last:range()

				-- Only include if within visible range
				if fsr >= start_line and ler <= end_line then
					-- Get content between delimiters
					local content_lines = vim.api.nvim_buf_get_text(bufnr, fer, fec, lsr, lsc, {})
					local content = table.concat(content_lines, "\n")

					table.insert(results, {
						open_pos = {
							start = { row = fsr, col = fsc },
							["end"] = { row = fer, col = fec },
						},
						close_pos = {
							start = { row = lsr, col = lsc },
							["end"] = { row = ler, col = lec },
						},
						pair_open = open_char,
						pair_close = close_char,
						content_text = content,
						full_text = open_char .. content .. close_char,
					})
				end
			end
		end
	end

	-- Recurse into children
	for child in node:iter_children() do
		M._collect_ts_pairs(child, bufnr, open_char, close_char, start_line, end_line, results)
	end
end

M.metadata = {
	label = "Pairs Collector",
	description = "Collects matching delimiter pairs from the visible buffer",
}

return M
