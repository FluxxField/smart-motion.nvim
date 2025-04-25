---@type SmartMotionFilterModuleEntry
local M = {}

function M.run(input_gen)
	return coroutine.create(function(ctx, cfg, motion_state)
		local cursor_row = ctx.cursor_line

		while true do
			local ok, target = coroutine.resume(input_gen, ctx, cfg, motion_state)
			if not ok or not target then
				break
			end

			if target.start_pos.row < cursor_row then
				coroutine.yield(target)
			end
		end
	end)
end

return M
