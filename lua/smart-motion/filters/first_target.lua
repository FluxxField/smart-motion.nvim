local EXIT_TYPE = require("smart-motion.consts").EXIT_TYPE

---@type SmartMotionFilterModuleEntry
local M = {}

function M.run(ctx, cfg, motion_state, target)
	motion_state.exit_type = EXIT_TYPE.EARLY_EXIT
	return target
end

M.metadata = {
	label = "First Target Only",
	description = "Yields the first target and exits immediately.",
}

return M
