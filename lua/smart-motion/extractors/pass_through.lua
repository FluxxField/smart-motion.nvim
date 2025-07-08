local log = require("smart-motion.core.log")

---@type SmartMotionExtractorModuleEntry
local M = {}

function M.run(ctx, cfg, motion_state, data)
	return data
end

M.metadata = {
	label = "Pass Through Extractor",
	description = "Extractor passes data along without mutating it",
}

return M
