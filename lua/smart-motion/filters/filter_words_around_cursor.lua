local HINT_POSITION = require("smart-motion.consts").HINT_POSITION

---@type SmartMotionFilterModuleEntry
local M = {}

function M.run(input_gen)
	return coroutine.create(function(ctx, cfg, motion_state)
		local hint_position = motion_state.hint_position
		local cursor_row, cursor_col = ctx.cursor_line, ctx.cursor_col

		while true do
			local ok, target = coroutine.resume(input_gen, ctx, cfg, motion_state)
			if not ok or not target then
				break
			end

			if target.start_pos.row ~= cursor_row then
				-- Different row? Always keep it
				coroutine.yield(target)
			else
				if hint_position == HINT_POSITION.END then
					-- Keep if cursor is NOT exactly on the target's end
					if cursor_col ~= target.end_pos.col - 1 then
						coroutine.yield(target)
					end
				elseif hint_position == HINT_POSITION.START then
					-- Keep if cursor is NOT exactly on the target's start
					if cursor_col ~= target.start_pos.col then
						coroutine.yield(target)
					end
				else
					-- No hint_position set? Keep by default
					coroutine.yield(target)
				end
			end
		end
	end)
end

return M
