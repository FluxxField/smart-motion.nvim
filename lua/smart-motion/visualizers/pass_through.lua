local log = require("smart-motion.core.log")

local EXIT_TYPE = require("smart-motion.consts").EXIT_TYPE

---@type SmartMotionModifierModuleEntry
local M = {}

function M.run(ctx, cfg, motion_state)
	motion_state.exit_type = EXIT_TYPE.AUTO_SELECT
	return
end

M.metadata = {
	label = "Default Passthrough",
	description = "Returns no targets",
}

return M

