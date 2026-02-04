--- Module for gathering buffer, window, and cursor context.
local log = require("smart-motion.core.log")

---@type SmartMotionContext
local M = {}

--- Validates the collected context (for internal debugging).
---@param ctx SmartMotionContext
local function validate(ctx)
	if ctx.cursor_line < 0 or ctx.cursor_line >= ctx.last_line then
		log.debug(string.format("Cursor line %d is out of range (0 to %d)", ctx.cursor_line, ctx.last_line - 1))
	end

	if ctx.cursor_col < 0 then
		log.debug(string.format("Cursor column is negative: %d", ctx.cursor_col))
	end
end

--- Collects context for the current buffer, window, and cursor.
---@return SmartMotionContext
function M.get()
	local bufnr = vim.api.nvim_get_current_buf()
	local winid = vim.api.nvim_get_current_win()
	local cursor = vim.api.nvim_win_get_cursor(winid)

	local ctx = {
		bufnr = bufnr,
		winid = winid,
		cursor_line = cursor[1] - 1,
		cursor_col = cursor[2],
		last_line = vim.api.nvim_buf_line_count(bufnr),
		mode = vim.fn.mode(true),
	}

	-- Collect all visible non-floating windows in current tabpage
	ctx.windows = {}
	for _, wid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local win_config = vim.api.nvim_win_get_config(wid)
		if win_config.relative == "" then
			local buf = vim.api.nvim_win_get_buf(wid)
			local cur = vim.api.nvim_win_get_cursor(wid)
			local entry = {
				winid = wid,
				bufnr = buf,
				cursor_line = cur[1] - 1,
				cursor_col = cur[2],
				last_line = vim.api.nvim_buf_line_count(buf),
			}
			if wid == winid then
				table.insert(ctx.windows, 1, entry)
			else
				table.insert(ctx.windows, entry)
			end
		end
	end

	log.debug(
		string.format(
			"Context collected: buf=%d, win=%d, cursor_line=%d, cursor_col=%d, last_line=%d, mode=%s, windows=%d",
			ctx.bufnr,
			ctx.winid,
			ctx.cursor_line,
			ctx.cursor_col,
			ctx.last_line,
			ctx.mode,
			#ctx.windows
		)
	)

	validate(ctx)

	return ctx
end

return M
