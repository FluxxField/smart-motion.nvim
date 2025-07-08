local exit = require("smart-motion.core.events.exit")
local log = require("smart-motion.core.log")

local EXIT_TYPE = require("smart-motion.consts").EXIT_TYPE

---@type SmartMotionModifierModuleEntry
local M = {}

function M.run(ctx, cfg, motion_state)
	exit.throw(EXIT_TYPE.AUTO_SELECT)
end

M.metadata = {
	label = "Default Passthrough",
	description = "Returns no targets",
	motion_state = {
		dim_background = false,
	},
}

return M
