---@type SmartMotionFilterModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@param opts table
---@return nil
function M.run(ctx, cfg, motion_state, opts)
	local top_line = vim.fn.line("w0", ctx.winid) - 1
	local bottom_line = vim.fn.line("w$", ctx.winid) - 1

	motion_state.jump_targets = vim.tbl_filter(function(t)
		return t.row >= top_line and t.row <= bottom_line
	end, motion_state.jump_targets)
end

return M
