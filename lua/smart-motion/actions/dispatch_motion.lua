local log = require("smart-motion.core.log")

---@type SmartMotionActionModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local dispatcher = require("smart-motion.core.dispatcher")
	local trigger = motion_state.motion.infer and dispatcher.trigger_action or dispatcher.trigger_motion

	trigger(motion_state.selected_jump_target.motion.trigger_key)
end

M.metadata = {
	label = "Dispatch Motion",
	description = "Dispatch Motion using target data",
}

return M
