local consts = require("smart-motion.consts")

local M = {}

--- Extracts valid line jump targets from the given lines collector.
---@param collector thread The lines collector (yields line data).
---@return thread A coroutine generator yielding line jump targets.
function M.init(collector)
	return coroutine.create(function(ctx, cfg, motion_state)
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

			-- Skip empty lines if ignore_whitespace is true.
			if motion_state.ignore_whitespace and line_text:match("^%s*$") then
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

			-- Yield the jump target.
			coroutine.yield({
				row = line_number,
				col = hint_col,
				text = line_text,
				start_pos = { row = line_number, col = 0 },
				end_pos = { row = line_number, col = #line_text },
				type = consts.TARGET_TYPES.LINES,
			})

			::continue::
		end
	end)
end

return M
