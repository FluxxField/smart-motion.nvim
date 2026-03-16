local log = require("smart-motion.core.log")

---@type SmartMotionCollectorModuleEntry
local M = {}

--- Pattern-based scanner for HTML/XML tag pairs in visible lines.
--- @param bufnr integer
--- @param start_line integer 0-indexed
--- @param end_line integer 0-indexed (inclusive)
--- @return table[] List of tag pair data objects
local function scan_tags_pattern(bufnr, start_line, end_line)
	local results = {}
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)

	-- First pass: collect all opening and closing tags with positions
	local open_tags = {} -- { { name, row, col_start, col_end }, ... }
	local close_tags = {} -- { { name, row, col_start, col_end }, ... }

	for i, line in ipairs(lines) do
		local row = start_line + i - 1

		-- Find opening tags: <tagname ...> (not self-closing, not closing)
		local pos = 1
		while pos <= #line do
			local s, e, tag_name = line:find("<([%w_%-%.]+)[^>]*>", pos)
			if not s then
				break
			end
			-- Skip closing tags and self-closing tags
			local full = line:sub(s, e)
			if not full:match("^</") and not full:match("/>$") then
				table.insert(open_tags, {
					name = tag_name,
					row = row,
					col_start = s - 1, -- 0-indexed
					col_end = e, -- exclusive
				})
			end
			pos = e + 1
		end

		-- Find closing tags: </tagname>
		pos = 1
		while pos <= #line do
			local s, e, tag_name = line:find("</([%w_%-%.]+)%s*>", pos)
			if not s then
				break
			end
			table.insert(close_tags, {
				name = tag_name,
				row = row,
				col_start = s - 1, -- 0-indexed
				col_end = e, -- exclusive
			})
			pos = e + 1
		end
	end

	-- Match open tags to close tags using stack-based matching
	local stack = {}
	-- Combine and sort all tags by position
	local all_tags = {}
	for _, t in ipairs(open_tags) do
		table.insert(all_tags, { type = "open", data = t })
	end
	for _, t in ipairs(close_tags) do
		table.insert(all_tags, { type = "close", data = t })
	end
	table.sort(all_tags, function(a, b)
		if a.data.row ~= b.data.row then
			return a.data.row < b.data.row
		end
		return a.data.col_start < b.data.col_start
	end)

	for _, tag in ipairs(all_tags) do
		if tag.type == "open" then
			table.insert(stack, tag.data)
		elseif tag.type == "close" then
			-- Find matching open tag (search stack from top)
			for j = #stack, 1, -1 do
				if stack[j].name == tag.data.name then
					local open = table.remove(stack, j)
					local close = tag.data
					-- Get content between tags
					local content_lines = vim.api.nvim_buf_get_text(
						bufnr,
						open.row,
						open.col_end,
						close.row,
						close.col_start,
						{}
					)
					local content = table.concat(content_lines, "\n")

					table.insert(results, {
						open_pos = {
							start = { row = open.row, col = open.col_start },
							["end"] = { row = open.row, col = open.col_end },
						},
						close_pos = {
							start = { row = close.row, col = close.col_start },
							["end"] = { row = close.row, col = close.col_end },
						},
						pair_open = "<" .. open.name .. ">",
						pair_close = "</" .. close.name .. ">",
						tag_name = open.name,
						content_text = content,
						full_text = "<" .. open.name .. ">" .. content .. "</" .. close.name .. ">",
					})
					break
				end
			end
		end
	end

	return results
end

--- Collects matching HTML/XML tag pairs in visible buffer.
--- @return thread A coroutine generator yielding tag pair data objects
function M.run()
	return coroutine.create(function(ctx, cfg, motion_state)
		local bufnr = ctx.bufnr

		-- Determine visible range
		local winid = ctx.winid or 0
		local start_line = vim.fn.line("w0", winid) - 1
		local end_line = vim.fn.line("w$", winid) - 1

		-- Try treesitter first for HTML/JSX/TSX files
		local ts_results = nil
		local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
		if ok and parser then
			local trees = parser:parse()
			if trees and trees[1] then
				local root = trees[1]:root()
				if not root:has_error() then
					ts_results = {}
					M._collect_ts_tags(root, bufnr, start_line, end_line, ts_results)
				end
			end
		end

		local results = ts_results and #ts_results > 0 and ts_results
			or scan_tags_pattern(bufnr, start_line, end_line)

		for _, result in ipairs(results) do
			coroutine.yield(result)
		end
	end)
end

--- Recursively collects tag pairs from treesitter nodes.
--- @param node TSNode
--- @param bufnr integer
--- @param start_line integer
--- @param end_line integer
--- @param results table[]
function M._collect_ts_tags(node, bufnr, start_line, end_line, results)
	local node_type = node:type()

	-- HTML element, JSX element, etc.
	local is_element = node_type == "element"
		or node_type == "jsx_element"
		or node_type == "tsx_element"

	if is_element then
		local open_tag = nil
		local close_tag = nil

		for child in node:iter_children() do
			local child_type = child:type()
			if child_type == "start_tag" or child_type == "jsx_opening_element" or child_type == "tsx_opening_element" then
				open_tag = child
			elseif child_type == "end_tag" or child_type == "jsx_closing_element" or child_type == "tsx_closing_element" then
				close_tag = child
			end
		end

		if open_tag and close_tag then
			local osr, osc, oer, oec = open_tag:range()
			local csr, csc, cer, cec = close_tag:range()

			if osr >= start_line and cer <= end_line then
				-- Extract tag name from the opening tag
				local tag_name = nil
				for child in open_tag:iter_children() do
					if child:type() == "tag_name" or child:type() == "identifier" then
						tag_name = vim.treesitter.get_node_text(child, bufnr)
						break
					end
				end

				if tag_name then
					local content_lines = vim.api.nvim_buf_get_text(bufnr, oer, oec, csr, csc, {})
					local content = table.concat(content_lines, "\n")
					local open_text = vim.treesitter.get_node_text(open_tag, bufnr)
					local close_text = vim.treesitter.get_node_text(close_tag, bufnr)

					table.insert(results, {
						open_pos = {
							start = { row = osr, col = osc },
							["end"] = { row = oer, col = oec },
						},
						close_pos = {
							start = { row = csr, col = csc },
							["end"] = { row = cer, col = cec },
						},
						pair_open = open_text,
						pair_close = close_text,
						tag_name = tag_name,
						content_text = content,
						full_text = open_text .. content .. close_text,
					})
				end
			end
		end
	end

	-- Recurse into children
	for child in node:iter_children() do
		M._collect_ts_tags(child, bufnr, start_line, end_line, results)
	end
end

M.metadata = {
	label = "Tags Collector",
	description = "Collects matching HTML/XML tag pairs from the visible buffer",
}

return M
