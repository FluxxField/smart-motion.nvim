local HINT_POSITION = require("smart-motion.consts").HINT_POSITION

---@type SmartMotionFilterModuleEntry
local M = {}

function M.run(extractor_gen)
	return coroutine.create(function(ctx, cfg, motion_state)
		local hint_position = motion_state.hint_position
		local cursor_row, cursor_col = ctx.cursor_line, ctx.cursor_col

		while true do
			local ok, target = coroutine.resume(extractor_gen, ctx, cfg, motion_state)

			if not ok then
				log.error("Extractor Coroutine Error: " .. tostring(target))
				break
			end

			if target == nil then
				break
			end

			if target.start_pos.row ~= cursor_row then
				if target.start_pos.row < cursor_row then
					coroutine.yield(target)
				end
			else
				if hint_position == HINT_POSITION.END then
					if target.end_pos.col - 1 < cursor_col then
						coroutine.yield(target)
					end
				elseif hint_position == HINT_POSITION.START then
					if cursor_col > target.start_pos.col then
						coroutine.yield(target)
					end
				else
					coroutine.yield(target)
				end
			end
		end
	end)
end

return M
