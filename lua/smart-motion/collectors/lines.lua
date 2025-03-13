local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local M = {}

--- Collects lines from buffer based on motion direction.
---@return thread A coroutine generator yielding lines one at a time.
function M.init()
	return coroutine.create(function(ctx, cfg, motion_state)
		if not vim.api.nvim_buf_is_valid(ctx.bufnr) then
			log.error("lines_collector received an invalid buffer: " .. tostring(ctx.bufnr))

			return
		end

		local last_line = vim.api.nvim_buf_line_count(ctx.bufnr)

		if motion_state.direction == consts.DIRECTION.AFTER_CURSOR then
			-- Get lines from cursor to max_lines
			local max_lines = math.min(motion_state.max_lines, last_line - (ctx.cursor_line + 1))

			for line_number = ctx.cursor_line, ctx.cursor_line + max_lines do
				local line = vim.api.nvim_buf_get_lines(ctx.bufnr, line_number, line_number + 1, false)[1]

				if line then
					coroutine.yield({ line_number = line_number, text = line })
				end
			end
		elseif motion_state.direction == consts.DIRECTION.BEFORE_CURSOR then
			-- Fetch max_lines before cursor.
			local start_line = math.max(ctx.cursor_line - motion_state.max_lines, 0)

			log.debug(string.format("Fetching before cursor - start_line: %d", start_line))

			-- Get all lines first, then reverse them
			local lines = vim.api.nvim_buf_get_lines(ctx.bufnr, start_line, ctx.cursor_line + 1, false)
			lines = vim.fn.reverse(lines)

			for i, text in ipairs(lines) do
				local line_number = ctx.cursor_line - (i - 1)

				coroutine.yield({ line_number = line_number, text = text })
			end
		end
	end)
end

return M
