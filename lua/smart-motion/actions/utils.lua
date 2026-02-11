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
--- When exclude_target is set (until mode), the range is from cursor to target start (exclusive).
--- When cursor_to_target is set (find mode), the range is from cursor to target end (inclusive).
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

	if motion_state.cursor_to_target then
		local cursor_before = ctx.cursor_line < target.start_pos.row
			or (ctx.cursor_line == target.start_pos.row and ctx.cursor_col < target.start_pos.col)

		if cursor_before then
			-- Forward find: cursor → target end (inclusive of target)
			return ctx.cursor_line, ctx.cursor_col, target.end_pos.row, target.end_pos.col
		else
			-- Backward find: target start → cursor (inclusive of target)
			return target.start_pos.row, target.start_pos.col, ctx.cursor_line, ctx.cursor_col
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
	-- Note: nvim_buf_set_mark only works for a-z/A-Z marks, not special marks like '[ and ']
	-- Must use setpos() for these special marks
	vim.fn.setpos("'[", { bufnr, start_row + 1, start_col + 1, 0 })
	vim.fn.setpos("']", { bufnr, end_row + 1, end_col, 0 })

	-- Convert regtype for v:event (setreg uses "l"/"c", v:event uses "V"/"v")
	local event_regtype = regtype == "l" and "V" or "v"

	-- Fire TextYankPost for user autocmds that don't rely on vim.v.event
	-- Note: nvim_exec_autocmds does NOT populate vim.v.event, so autocmds
	-- that call vim.hl.on_yank() won't work. We call it directly below.
	vim.api.nvim_exec_autocmds("TextYankPost", {
		pattern = "*",
		data = {
			operator = operator,
			regtype = event_regtype,
			regcontents = vim.split(text, "\n"),
			regname = "",
		},
	})

	-- Highlight the yanked region directly
	-- Note: vim.highlight.on_yank() checks vim.v.event internally and returns early
	-- if it's empty, so we must create the highlight ourselves using the marks
	if operator == "y" then
		local ns = vim.api.nvim_create_namespace("smart_motion_yank")
		local pos1 = vim.fn.getpos("'[")
		local pos2 = vim.fn.getpos("']")
		-- getpos returns [bufnum, lnum, col, off] with 1-indexed line and col
		local start_line = pos1[2] - 1
		local start_col = pos1[3] - 1
		local end_line = pos2[2] - 1
		local end_col = pos2[3] -- exclusive end, so no -1

		-- Handle linewise vs characterwise
		if regtype == "l" then
			-- Linewise: highlight full lines
			for line = start_line, end_line do
				vim.api.nvim_buf_add_highlight(bufnr, ns, "IncSearch", line, 0, -1)
			end
		else
			-- Characterwise
			if start_line == end_line then
				vim.api.nvim_buf_add_highlight(bufnr, ns, "IncSearch", start_line, start_col, end_col)
			else
				-- Multi-line characterwise
				vim.api.nvim_buf_add_highlight(bufnr, ns, "IncSearch", start_line, start_col, -1)
				for line = start_line + 1, end_line - 1 do
					vim.api.nvim_buf_add_highlight(bufnr, ns, "IncSearch", line, 0, -1)
				end
				vim.api.nvim_buf_add_highlight(bufnr, ns, "IncSearch", end_line, 0, end_col)
			end
		end

		-- Clear after timeout
		local config = require("smart-motion.config")
		local duration = config.validated and config.validated.yank_highlight_duration or 150
		vim.defer_fn(function()
			if vim.api.nvim_buf_is_valid(bufnr) then
				vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
			end
		end, duration)
	end
end

return M
