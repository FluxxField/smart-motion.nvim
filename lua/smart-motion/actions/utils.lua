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

--- Sets register with proper clipboard sync, marks, and TextYankPost firing.
--- This ensures native-like behavior for yank/delete/change operations.
--- @param bufnr integer Buffer number
--- @param start_row integer 0-indexed start row
--- @param start_col integer 0-indexed start column
--- @param end_row integer 0-indexed end row
--- @param end_col integer 0-indexed end column
--- @param text string The text to put in the register
--- @param regtype string Register type: "l" for linewise, "c" for characterwise
--- @param operator string The operator: "y", "d", or "c"
function M.set_register(bufnr, start_row, start_col, end_row, end_col, text, regtype, operator)
	-- Set unnamed register
	vim.fn.setreg('"', text, regtype)

	-- Clipboard sync based on clipboard option
	local clipboard = vim.o.clipboard or ""
	if clipboard:find("unnamedplus") then
		vim.fn.setreg("+", text, regtype)
	end
	if clipboard:find("unnamed") then
		vim.fn.setreg("*", text, regtype)
	end

	-- Set change marks (needed for vim.hl.on_yank to know the region)
	vim.api.nvim_buf_set_mark(bufnr, "[", start_row + 1, start_col, {})
	vim.api.nvim_buf_set_mark(bufnr, "]", end_row + 1, end_col, {})

	-- Fire TextYankPost for user autocmds
	vim.api.nvim_exec_autocmds("TextYankPost", {
		pattern = "*",
		data = {
			operator = operator,
			regtype = regtype,
			regcontents = vim.split(text, "\n"),
			regname = "",
		},
	})
end

return M
