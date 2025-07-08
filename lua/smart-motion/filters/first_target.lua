local exit = require("smart-motion.core.events.exit")
local log = require("smart-motion.core.log")

local EXIT_TYPE = require("smart-motion.consts").EXIT_TYPE

---@type SmartMotionFilterModuleEntry
local M = {}

function M.run(ctx, cfg, motion_state, target)
	motion_state.selected_jump_target = target
	exit.throw(EXIT_TYPE.AUTO_SELECT)
end

M.metadata = {
	label = "First Target Only",
	description = "Yields the first target and exits immediately.",
}

return M
