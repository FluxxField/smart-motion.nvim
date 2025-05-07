---@type SmartMotionModifierModuleEntry
local M = {}

function M.run(input_gen)
	return coroutine.create(function(ctx, cfg, motion_state)
		local cursor_row, cursor_col = ctx.cursor_line, ctx.cursor_col

		while true do
			local ok, target = coroutine.resume(input_gen, ctx, cfg, motion_state)
			if not ok or not target then
				break
			end

			local target_row = target.start_pos.row
			local target_col = target.start_pos.col

			local dist = math.abs(target_row - cursor_row) + math.abs(target_col - cursor_col)
			target.metadata = target.metadata or {}
			target.metadata.sort_weight = dist

			coroutine.yield(target)
		end
	end)
end

M.metadata = {
	label = "Distance Metadata",
	description = "Adds a `sort_weight` field to each target's metadata based on Manhattan distance from the cursor.",
	motion_state = {
		sort_by = "sort_weight",
		sort_descending = false,
	},
}

return M
