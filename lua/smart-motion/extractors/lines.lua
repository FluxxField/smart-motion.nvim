local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

---@type SmartMotionExtractorModuleEntry
local M = {}

--- Extracts valid line jump targets from the given lines collector.
--- @param collector thread
--- @param opts table Arbitrary options passed through the pipeline
--- @return thread Coroutine yielding SmartMotionJumpTarget
function M.run(collector, opts)
	return coroutine.create(function(ctx, cfg, motion_state)
		---@type SmartMotionContext
		ctx = ctx
		---@type SmartMotionConfig
		cfg = cfg
		---@type SmartMotionMotionState
		motion_state = motion_state

		while true do
			local ok, line_data = coroutine.resume(collector, ctx, cfg, motion_state)

			if not ok or not line_data then
				break
			end

			local line_text, line_number = line_data.text, line_data.line_number

			-- Skip the cursor's current line.
			if line_number == ctx.cursor_line then
				goto continue
			end

			local hint_col

			if motion_state.hint_position == consts.HINT_POSITION.START then
				if motion_state.ignore_whitespace then
					local first_non_ws = line_text:find("%S")

					hint_col = first_non_ws and (first_non_ws - 1) or 0
				else
					hint_col = 0
				end
			elseif motion_state.hint_position == consts.HINT_POSITION.END then
				hint_col = #line_text
			end

			---@type SmartMotionJumpTarget
			local target = {
				row = line_number,
				col = hint_col,
				text = line_text,
				start_pos = { row = line_number, col = 0 },
				end_pos = { row = line_number, col = #line_text },
				type = consts.TARGET_TYPES.LINES,
			}

			coroutine.yield(target)

			::continue::
		end
	end)
end

return M
