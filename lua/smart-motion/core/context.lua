--- Module for gathering buffer, window, and cursor context.
local log = require("smart-motion.core.log")

---@class Context
---@field bufnr integer Buffer number.
---@field winid integer Window ID.
---@field cursor_line integer 0-based cursor line.
---@field cursor_col integer 0-based cursor column.
---@field last_line integer Total line count.

local M = {}

--- Validates the collected context (for internal debugging).
---@param ctx Context
local function validate(ctx)
	if ctx.cursor_line < 0 or ctx.cursor_line >= ctx.last_line then
		log.warn(string.format("Cursor line %d is out of range (0 to %d)", ctx.cursor_line, ctx.last_line - 1))
	end

	if ctx.cursor_col < 0 then
		log.warn(string.format("Cursor column is negative: %d", ctx.cursor_col))
	end
end

--- Collects context for the current buffer, window, and cursor.
---@return Context
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
	}

	log.debug(
		string.format(
			"Context collected: buf=%d, win=%d, cursor_line=%d, cursor_col=%d, last_line=%d",
			ctx.bufnr,
			ctx.winid,
			ctx.cursor_line,
			ctx.cursor_col,
			ctx.last_line
		)
	)

	validate(ctx)

	return ctx
end

return M
