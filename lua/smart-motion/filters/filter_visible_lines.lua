---@type SmartMotionFilterModuleEntry
local M = {}

function M.run(input_gen)
	return coroutine.create(function(ctx, cfg, motion_state)
		local top_line = vim.fn.line("w0", ctx.winid) - 1
		local bottom_line = vim.fn.line("w$", ctx.winid) - 1

		while true do
			local ok, target = coroutine.resume(input_gen, ctx, cfg, motion_state)
			if not ok or not target then
				break
			end

			local row = target.start_pos.row

			if row >= top_line and row <= bottom_line then
				coroutine.yield(target)
			end
		end
	end)
end

return M
