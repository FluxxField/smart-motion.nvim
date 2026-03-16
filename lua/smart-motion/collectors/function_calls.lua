local log = require("smart-motion.core.log")

---@type SmartMotionCollectorModuleEntry
local M = {}

--- Treesitter node types that represent function/method calls across languages.
local CALL_NODE_TYPES = {
	"call_expression", -- JS/TS/Rust/Go
	"call", -- Python
	"function_call", -- Lua
	"method_call_expression", -- Java
	"invocation_expression", -- C#
}

--- Pattern-based scanner for function calls: name( ... )
--- @param bufnr integer
--- @param start_line integer 0-indexed
--- @param end_line integer 0-indexed (inclusive)
--- @return table[] List of function call data objects
local function scan_calls_pattern(bufnr, start_line, end_line)
	local results = {}

	for line_num = start_line, end_line do
		local line = vim.api.nvim_buf_get_lines(bufnr, line_num, line_num + 1, false)[1]
		if line then
			local pos = 1
			while pos <= #line do
				-- Match function_name( or obj.method( or obj:method(
				local s, e, func_name = line:find("([%w_%.%:]+)%s*%(", pos)
				if not s then
					break
				end

				-- Find the matching close paren using stack
				local paren_col = line:find("%(", e) or e
				local depth = 1
				local close_row = line_num
				local close_col = nil

				-- Search for closing paren starting from after the open paren
				local search_col = paren_col + 1
				local search_row = line_num
				local all_lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)

				while search_row <= end_line and depth > 0 do
					local search_line = all_lines[search_row - start_line + 1]
					if search_line then
						for c = search_col, #search_line do
							local ch = search_line:sub(c, c)
							if ch == "(" then
								depth = depth + 1
							elseif ch == ")" then
								depth = depth - 1
								if depth == 0 then
									close_row = search_row
									close_col = c - 1 -- 0-indexed
									break
								end
							end
						end
					end
					if depth > 0 then
						search_row = search_row + 1
						search_col = 1
					end
				end

				if close_col then
					local open_col_start = s - 1 -- 0-indexed, start of function name
					local open_col_end = e -- exclusive, after the "("

					-- Get content between parens
					local content_lines = vim.api.nvim_buf_get_text(
						bufnr,
						line_num,
						open_col_end,
						close_row,
						close_col,
						{}
					)
					local content = table.concat(content_lines, "\n")

					table.insert(results, {
						open_pos = {
							start = { row = line_num, col = open_col_start },
							["end"] = { row = line_num, col = open_col_end },
						},
						close_pos = {
							start = { row = close_row, col = close_col },
							["end"] = { row = close_row, col = close_col + 1 },
						},
						pair_open = func_name .. "(",
						pair_close = ")",
						func_name = func_name,
						content_text = content,
						full_text = func_name .. "(" .. content .. ")",
					})
				end

				pos = e + 1
			end
		end
	end

	return results
end

--- Collects function call sites in visible buffer.
--- @return thread A coroutine generator yielding function call data objects
function M.run()
	return coroutine.create(function(ctx, cfg, motion_state)
		local bufnr = ctx.bufnr

		-- Determine visible range
		local winid = ctx.winid or 0
		local start_line = vim.fn.line("w0", winid) - 1
		local end_line = vim.fn.line("w$", winid) - 1

		-- Try treesitter first
		local ts_results = nil
		local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
		if ok and parser then
			local trees = parser:parse()
			if trees and trees[1] then
				local root = trees[1]:root()
				if not root:has_error() then
					ts_results = {}
					M._collect_ts_calls(root, bufnr, start_line, end_line, ts_results)
				end
			end
		end

		local results = ts_results and #ts_results > 0 and ts_results
			or scan_calls_pattern(bufnr, start_line, end_line)

		for _, result in ipairs(results) do
			coroutine.yield(result)
		end
	end)
end

--- Recursively collects function call sites from treesitter nodes.
--- @param node TSNode
--- @param bufnr integer
--- @param start_line integer
--- @param end_line integer
--- @param results table[]
function M._collect_ts_calls(node, bufnr, start_line, end_line, results)
	local node_type = node:type()
	local is_call = false

	for _, call_type in ipairs(CALL_NODE_TYPES) do
		if node_type == call_type then
			is_call = true
			break
		end
	end

	if is_call then
		local nsr, nsc, ner, nec = node:range()

		if nsr >= start_line and ner <= end_line then
			-- Extract function name and argument positions
			local func_name = nil
			local args_node = nil

			for child in node:iter_children() do
				local child_type = child:type()
				-- Function name (various node types across languages)
				if child_type == "identifier"
					or child_type == "field_expression"
					or child_type == "member_expression"
					or child_type == "method"
					or child_type == "attribute"
				then
					func_name = vim.treesitter.get_node_text(child, bufnr)
				end
				-- Arguments
				if child_type == "arguments"
					or child_type == "argument_list"
					or child_type == "call_body"
				then
					args_node = child
				end
			end

			-- Fallback: use first child as name if not identified
			if not func_name and node:child_count() > 0 then
				local first = node:child(0)
				if first then
					func_name = vim.treesitter.get_node_text(first, bufnr)
				end
			end

			if func_name and args_node then
				local asr, asc, aer, aec = args_node:range()

				-- open_pos: from function name start to after opening paren
				-- close_pos: the closing paren
				local content_lines = vim.api.nvim_buf_get_text(bufnr, asr, asc + 1, aer, aec - 1, {})
				local content = table.concat(content_lines, "\n")

				table.insert(results, {
					open_pos = {
						start = { row = nsr, col = nsc },
						["end"] = { row = asr, col = asc + 1 }, -- after "("
					},
					close_pos = {
						start = { row = aer, col = aec - 1 }, -- the ")"
						["end"] = { row = aer, col = aec },
					},
					pair_open = func_name .. "(",
					pair_close = ")",
					func_name = func_name,
					content_text = content,
					full_text = vim.treesitter.get_node_text(node, bufnr),
				})
			end
		end
	end

	-- Recurse into children
	for child in node:iter_children() do
		M._collect_ts_calls(child, bufnr, start_line, end_line, results)
	end
end

M.metadata = {
	label = "Function Calls Collector",
	description = "Collects function call sites from the visible buffer",
}

return M
