local log = require("smart-motion.core.log")

---@type SmartMotionActionModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local engine = require("smart-motion.core.engine")
	engine.run(motion_state.selected_jump_target.motion.trigger_key)
end

M.metadata = {
	label = "Run Motion",
	description = "Run Motion using target data",
}

return M
