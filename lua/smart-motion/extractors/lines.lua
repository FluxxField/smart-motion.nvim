local consts = require("smart-motion.consts")

---@type SmartMotionExtractorModuleEntry
local M = {}

--- Extracts valid line jump targets from the given lines collector.
--- @param collector thread
--- @param opts table Arbitrary options passed through the pipeline
--- @return thread Coroutine yielding SmartMotionJumpTarget
function M.run(collector, opts)
	return coroutine.create(function(ctx, cfg, motion_state)
		while true do
			local ok, line_data = coroutine.resume(collector, ctx, cfg, motion_state)

			if not ok or not line_data then
				break
			end

			local line_text, line_number = line_data.text, line_data.line_number
			local col

			if motion_state.ignore_whitespace then
				local first_non_ws = line_text:find("%S")
				col = first_non_ws and (first_non_ws - 1) or 0
			end

			---@type SmartMotionJumpTarget
			coroutine.yield({
				row = line_number,
				col = col,
				text = line_text,
				start_pos = { row = line_number, col = col },
				end_pos = { row = line_number, col = #line_text },
				type = consts.TARGET_TYPES.LINES,
			})
		end
	end)
end

return M
