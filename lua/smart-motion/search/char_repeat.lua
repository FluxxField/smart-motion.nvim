--- Handles ;/, repeat of the last f/F/t/T char motion.
local consts = require("smart-motion.consts")

local M = {}

--- Repeats the last char motion, optionally reversing direction.
---@param reverse boolean
function M.run(reverse)
	local char_state = require("smart-motion.search.char_state")
	local last = char_state.get()
	if not last then
		return
	end

	local context = require("smart-motion.core.context")
	local state = require("smart-motion.core.state")
	local highlight = require("smart-motion.core.highlight")
	local hints = require("smart-motion.visualizers.hints")
	local selection = require("smart-motion.core.selection")
	local jump = require("smart-motion.actions.jump")
	local cfg_mod = require("smart-motion.config")

	local cfg = cfg_mod.validated
	if not cfg then
		return
	end

	local ctx = context.get()
	local motion_state = state.create_motion_state()
	motion_state.multi_window = true
	motion_state.exclude_target = last.exclude_target

	-- Determine direction: same for ;, reversed for ,
	local direction = last.direction
	if reverse then
		if direction == "after_cursor" then
			direction = "before_cursor"
		else
			direction = "after_cursor"
		end
	end
	motion_state.direction = direction

	-- Find matches using literal search
	local targets = M._find_matches(last.search_text, ctx)
	if #targets == 0 then
		return
	end

	-- Filter by direction
	targets = M._filter_by_direction(targets, ctx, direction)
	if #targets == 0 then
		return
	end

	motion_state.jump_targets = targets
	motion_state.jump_target_count = #targets
	state.finalize_motion_state(ctx, cfg, motion_state)

	-- Render labels
	hints.run(ctx, cfg, motion_state)

	-- Wait for label selection
	selection.wait_for_hint_selection(ctx, cfg, motion_state)

	-- Clean up
	highlight.clear(ctx, cfg, motion_state)
	vim.cmd("redraw")

	-- Jump if selected
	if motion_state.selected_jump_target then
		jump.run(ctx, cfg, motion_state)
	end
end

--- Finds all matches of the literal search text in visible lines across all windows.
---@param search_text string
---@param ctx SmartMotionContext
---@return table[]
function M._find_matches(search_text, ctx)
	local targets = {}
	local pattern = "\\V" .. vim.fn.escape(search_text, "\\")

	for _, win in ipairs(ctx.windows) do
		local winid = win.winid
		local bufnr = win.bufnr

		if not vim.api.nvim_buf_is_valid(bufnr) then
			goto continue
		end

		local top_line = vim.fn.line("w0", winid) - 1
		local bottom_line = vim.fn.line("w$", winid) - 1
		local lines = vim.api.nvim_buf_get_lines(bufnr, top_line, bottom_line + 1, false)

		for i, line_text in ipairs(lines) do
			local line_number = top_line + i - 1
			local col = 0

			while true do
				local ok, match_data = pcall(vim.fn.matchstrpos, line_text, pattern, col)
				if not ok then
					break
				end

				local match, start_col, end_col = match_data[1], match_data[2], match_data[3]
				if start_col == -1 then
					break
				end

				table.insert(targets, {
					text = match,
					start_pos = { row = line_number, col = start_col },
					end_pos = { row = line_number, col = end_col },
					type = "search",
					metadata = { bufnr = bufnr, winid = winid },
				})

				col = end_col + 1
			end
		end

		::continue::
	end

	return targets
end

--- Filters targets by direction relative to cursor.
---@param targets table[]
---@param ctx SmartMotionContext
---@param direction Direction
---@return table[]
function M._filter_by_direction(targets, ctx, direction)
	local filtered = {}

	for _, target in ipairs(targets) do
		-- Cross-window targets pass through
		if target.metadata.winid ~= ctx.winid then
			table.insert(filtered, target)
		elseif direction == "after_cursor" then
			if
				target.start_pos.row > ctx.cursor_line
				or (target.start_pos.row == ctx.cursor_line and target.start_pos.col > ctx.cursor_col)
			then
				table.insert(filtered, target)
			end
		elseif direction == "before_cursor" then
			if
				target.start_pos.row < ctx.cursor_line
				or (target.start_pos.row == ctx.cursor_line and target.start_pos.col < ctx.cursor_col)
			then
				table.insert(filtered, target)
			end
		end
	end

	return filtered
end

return M
