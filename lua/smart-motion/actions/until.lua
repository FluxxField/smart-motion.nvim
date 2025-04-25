---@type SmartMotionActionModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local col = target.end_pos.col

	if not target then
		return
	end

	target.end_pos.col = math.max(col - 1, 0)
	motion_state.selected_jump_target = target
end

return M
