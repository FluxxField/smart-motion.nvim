---@type SmartMotionFilterModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@param opts table
---@return nil
function M.run(ctx, cfg, motion_state, opts)
	local cursor_row = ctx.cursor_line

	motion_state.jump_targets = vim.tbl_filter(function()
		return target.row > cursor_row
	end, motion_state.jump_targets)
end

return M
