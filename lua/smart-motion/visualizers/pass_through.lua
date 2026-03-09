local exit = require("smart-motion.core.events.exit")
local log = require("smart-motion.core.log")

local EXIT_TYPE = require("smart-motion.consts").EXIT_TYPE

---@type SmartMotionModifierModuleEntry
local M = {}

function M.run(ctx, cfg, motion_state)
	if not motion_state.selected_jump_target then
		local targets = motion_state.jump_targets or {}
		if #targets > 0 then
			motion_state.selected_jump_target = targets[1]
		else
			exit.throw(EXIT_TYPE.EARLY_EXIT)
		end
	end
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
