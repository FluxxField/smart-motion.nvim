---@type SmartMotionModifierModuleEntry
local M = {}

function M.run(ctx, cfg, motion_state, target)
	local cursor_row, cursor_col = ctx.cursor_line, ctx.cursor_col
	local target_row = target.start_pos.row
	local target_col = target.start_pos.col
	local dist = math.abs(target_row - cursor_row) + math.abs(target_col - cursor_col)

	target.metadata = target.metadata or {}
	target.metadata.sort_weight = dist

	return target
end

M.metadata = {
	label = "Weight Distance",
	description = "Adds a `sort_weight` field to each target's metadata based on Manhattan distance from the cursor.",
	motion_state = {
		sort_by = "sort_weight",
		sort_descending = false,
	},
}

return M
