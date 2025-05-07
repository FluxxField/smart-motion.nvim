local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

---@type SmartMotionExtractorModuleEntry
local M = {}

--- Extracts valid line jump targets from the given lines collector.
--- @param collector thread
--- @return thread Coroutine yielding SmartMotionTarget
function M.run(collector)
	return coroutine.create(function(ctx, cfg, motion_state)
		while true do
			local ok, data_or_error = coroutine.resume(collector, ctx, cfg, motion_state)

			if not ok then
				log.error("Collector Coroutine Error: " .. tostring(data_or_error))
				break
			end

			if not data_or_error then
				break
			end

			local line_text, line_number = data_or_error.text, data_or_error.line_number
			local col = 0

			if motion_state.ignore_whitespace then
				local first_non_ws = line_text:find("%S")
				col = first_non_ws and (first_non_ws - 1) or 0
			end

			---@type SmartMotionTarget
			coroutine.yield({
				text = line_text,
				start_pos = { row = line_number, col = col },
				end_pos = { row = line_number, col = #line_text },
				type = consts.TARGET_TYPES.LINES,
			})
		end
	end)
end

M.metadata = {
	label = "Line Extractor",
	description = "Extracts lines to generate targets from collector",
	motion_state = {
		ignore_whitespace = true,
	},
}

return M
