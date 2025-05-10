local log = require("smart-motion.core.log")
local HINT_POSITION = require("smart-motion.consts").HINT_POSITION

---@type SmartMotionFilterModuleEntry
local M = {}

function M.run(ctx, cfg, motion_state, target)
	local hint_position = motion_state.hint_position
	local cursor_row, cursor_col = ctx.cursor_line, ctx.cursor_col

	if target.start_pos.row ~= cursor_row then
		return target
	else
		if hint_position == HINT_POSITION.END then
			-- Keep if cursor is NOT exactly on the target's end
			if cursor_col ~= target.end_pos.col - 1 then
				return target
			end
		elseif hint_position == HINT_POSITION.START then
			-- Keep if cursor is NOT exactly on the target's start
			if cursor_col ~= target.start_pos.col then
				return target
			end
		else
			-- No hint_position set? Keep by default
			return target
		end
	end
end

return M
