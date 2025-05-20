local log = require("smart-motion.core.log")

---@type SmartMotionFilterModuleEntry
local M = {}

function M.run(ctx, cfg, motion_state, target)
	local top_line = vim.fn.line("w0", ctx.winid) - 1
	local bottom_line = vim.fn.line("w$", ctx.winid) - 1
	local row = target.start_pos.row

	if row >= top_line and row <= bottom_line then
		return target
	end
end

M.metadata = {
	label = "Visible Only",
	description = "Filters to targets visible in the current window.",
}

return M
