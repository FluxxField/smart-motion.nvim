local log = require("smart-motion.core.log")

---@type SmartMotionModifierModuleEntry
local M = {}

function M.run(ctx, cfg, motion_state, target)
 return target
end

M.metadata = {
	label = "Default Passthrough",
	description = "Yields all targets unchanged",
}

return M
