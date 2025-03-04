local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local M = {}

--- Fetches lines based on motion direction.
---@param ctx table Motion context (bufnr, cursor_line, direction, etc.)
---@param cfg table Validated config.
---@param motion_state table Current motion state.
---@return string[] List of lines to scan.
function M.get_lines_for_motion(ctx, cfg, motion_state)
	local lines = {}

	log.debug(
		string.format(
			"Fetching lines - bufnr: %d, cursor_line: %d, direction: %s",
			ctx.bufnr,
			ctx.cursor_line,
			motion_state.direction
		)
	)

	if not vim.api.nvim_buf_is_valid(ctx.bufnr) then
		log.error("get_lines_for_motion received invalid buffer: " .. tostring(ctx.bufnr))

		motion_state.lines = lines
		return lines
	end

	local last_line = vim.api.nvim_buf_line_count(ctx.bufnr)

	if motion_state.direction == consts.DIRECTION.AFTER_CURSOR then
		-- Fetch from the cursor to either max_lines forward, or the end of the file.
		local max_lines = math.min(motion_state.max_lines, last_line - ctx.cursor_line + 1)

		log.debug(string.format("Scanning after cursor - max_lines: %d (last_line: %d)", max_lines, last_line))

		lines = vim.api.nvim_buf_get_lines(ctx.bufnr, ctx.cursor_line, ctx.cursor_line + max_lines, false)
	elseif motion_state.direction == consts.DIRECTION.BEFORE_CURSOR then
		-- Fetch from the start of the file (line 0) or max_lines before the cursor to cursor_line (inclusive)
		local start_line = math.max(ctx.cursor_line - motion_state.max_lines, 0)

		log.debug(string.format("Scanning before cursor - start_line: %d", start_line))

		lines = vim.api.nvim_buf_get_lines(ctx.bufnr, start_line, ctx.cursor_line + 1, false)

		-- Reverse the order so first processed is closest to cursor.
		lines = vim.fn.reverse(lines)
	end

	motion_state.lines = lines
	return lines
end

return M
