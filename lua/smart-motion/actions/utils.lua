local M = {}

--- Merges multiple action modules into one
--- @param actions SmartMotionActionModuleEntry[]
--- @return SmartMotionActionModuleEntry
function M.merge(actions)
	return function(ctx, cfg, motion_state)
		for _, action in ipairs(actions) do
			action.run(ctx, cfg, motion_state)
		end
	end
end

--- Resolves the operation range for an action.
--- When exclude_target is set (until mode), the range is from cursor to target.
--- Otherwise, the range is the target itself (start_pos to end_pos).
--- Handles both forward and backward directions automatically.
--- @param ctx SmartMotionContext
--- @param motion_state SmartMotionMotionState
--- @return integer start_row, integer start_col, integer end_row, integer end_col
function M.resolve_range(ctx, motion_state)
	local target = motion_state.selected_jump_target

	if motion_state.exclude_target then
		local cursor_before = ctx.cursor_line < target.start_pos.row
			or (ctx.cursor_line == target.start_pos.row and ctx.cursor_col < target.start_pos.col)

		if cursor_before then
			-- Forward until: cursor → target start (exclusive of target char)
			return ctx.cursor_line, ctx.cursor_col, target.start_pos.row, target.start_pos.col
		else
			-- Backward until: target end → cursor (exclusive of target char)
			return target.end_pos.row, target.end_pos.col, ctx.cursor_line, ctx.cursor_col
		end
	end

	return target.start_pos.row, target.start_pos.col, target.end_pos.row, target.end_pos.col
end

return M
