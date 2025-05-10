local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local TARGET_TYPES = consts.TARGET_TYPES
local EXIT_TYPE = consts.EXIT_TYPE

---@type SmartMotionExtractorModuleEntry
local M = {}

--- Extracts valid line jump targets from the given lines collector.
--- @param collector thread
--- @return thread Coroutine yielding SmartMotionTarget
function M.run(ctx, cfg, motion_state, data)
	local line_text, line_number = data.text, data.line_number
	local col = 0

	if motion_state.ignore_whitespace then
		local first_non_ws = line_text:find("%S")
		col = first_non_ws and (first_non_ws - 1) or 0
	end

	---@type SmartMotionTarget
	local target = {
		text = line_text,
		start_pos = { row = line_number, col = col },
		end_pos = { row = line_number, col = #line_text },
		type = TARGET_TYPES.LINES,
	}

	return target
end

M.metadata = {
	label = "Line Extractor",
	description = "Extracts lines to generate targets from collector",
	motion_state = {
		ignore_whitespace = true,
	},
}

return M
