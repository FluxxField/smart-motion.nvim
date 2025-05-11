local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

---@class SmartMotionLineData
---@field line_number integer
---@field text string

---@type SmartMotionCollectorModuleEntry
local M = {}

--- Collects lines from buffer based on motion direction.
--- @return thread A coroutine generator yielding SmartMotionLineData objects
function M.run()
	return coroutine.create(function(ctx, cfg, motion_state)
		if not vim.api.nvim_buf_is_valid(ctx.bufnr) then
			log.error("lines_collector received an invalid buffer: " .. tostring(ctx.bufnr))
			return
		end

		local cursor_line = ctx.cursor_line
		local total_lines = vim.api.nvim_buf_line_count(ctx.bufnr)
		local window_size = motion_state.max_lines or 100

		local start_line = math.max(0, cursor_line - window_size)
		local end_line = math.min(total_lines - 1, cursor_line + window_size)

		for line_number = start_line, end_line do
			local line = vim.api.nvim_buf_get_lines(ctx.bufnr, line_number, line_number + 1, false)[1]

			if line then
				coroutine.yield({
					line_number = line_number,
					text = line,
				})
			end
		end
	end)
end

M.metadata = {
	label = "Line Collector",
	description = "Collects full lines forward or backward from the cursor",
}

return M
