local consts = require("smart-motion.consts")
local highlight = require("smart-motion.core.highlight")
local flow_state = require("smart-motion.core.flow_state")
local log = require("smart-motion.core.log")

local M = {}

--- Compare two positions (row, col). Returns -1, 0, or 1.
local function compare_pos(a_row, a_col, b_row, b_col)
	if a_row < b_row then return -1 end
	if a_row > b_row then return 1 end
	if a_col < b_col then return -1 end
	if a_col > b_col then return 1 end
	return 0
end

--- Sort targets by buffer position (row, then col).
--- Returns a new sorted list and a mapping from sorted index to original.
--- @param jump_targets table[]
--- @return table[] sorted_targets
local function sort_by_position(jump_targets)
	local sorted = {}
	for i, t in ipairs(jump_targets) do
		sorted[i] = t
	end
	table.sort(sorted, function(a, b)
		local cmp = compare_pos(a.start_pos.row, a.start_pos.col, b.start_pos.row, b.start_pos.col)
		return cmp < 0
	end)
	return sorted
end

--- Find the index of the selected target in a sorted target list.
--- @param sorted_targets table[]
--- @param selected table
--- @return integer|nil
local function find_anchor_index(sorted_targets, selected)
	for i, target in ipairs(sorted_targets) do
		if target.start_pos.row == selected.start_pos.row
			and target.start_pos.col == selected.start_pos.col
			and target.end_pos.row == selected.end_pos.row
			and target.end_pos.col == selected.end_pos.col
		then
			return i
		end
	end
	return nil
end

--- Highlight the expansion range between first and last target.
--- @param bufnr integer
--- @param first table Target with start_pos
--- @param last table Target with end_pos
--- @return integer extmark_id
local function highlight_range(bufnr, first, last)
	return vim.api.nvim_buf_set_extmark(bufnr, consts.ns_id, first.start_pos.row, first.start_pos.col, {
		end_row = last.end_pos.row,
		end_col = last.end_pos.col,
		hl_group = "SmartMotionSelected",
	})
end

--- Show dim +/- hints on the spatially adjacent targets.
--- @param bufnr integer
--- @param sorted_targets table[] Targets sorted by buffer position
--- @param anchor integer Current anchor index in sorted list
--- @param forward_extent integer How many targets expanded forward
--- @param backward_extent integer How many targets expanded backward
--- @return integer[] extmark_ids
local function show_expansion_hints(bufnr, sorted_targets, anchor, forward_extent, backward_extent)
	local ids = {}

	-- Show "+" on the next target forward in buffer position
	local next_idx = anchor + forward_extent + 1
	if next_idx <= #sorted_targets then
		local target = sorted_targets[next_idx]
		ids[#ids + 1] = vim.api.nvim_buf_set_extmark(bufnr, consts.ns_id, target.start_pos.row, target.start_pos.col, {
			virt_text = { { "+", "SmartMotionHintDim" } },
			virt_text_pos = "overlay",
			hl_mode = "combine",
		})
	end

	-- Show "-" on the previous target backward in buffer position
	local prev_idx = anchor - backward_extent - 1
	if prev_idx >= 1 then
		local target = sorted_targets[prev_idx]
		ids[#ids + 1] = vim.api.nvim_buf_set_extmark(bufnr, consts.ns_id, target.start_pos.row, target.start_pos.col, {
			virt_text = { { "-", "SmartMotionHintDim" } },
			virt_text_pos = "overlay",
			hl_mode = "combine",
		})
	end

	-- Show "⌫" after the expanded range when there's something to undo
	if forward_extent > 0 or backward_extent > 0 then
		local last_target = sorted_targets[anchor + forward_extent]
		ids[#ids + 1] = vim.api.nvim_buf_set_extmark(bufnr, consts.ns_id, last_target.end_pos.row, last_target.end_pos.col, {
			virt_text = { { " ⌫", "SmartMotionHintDim" } },
			virt_text_pos = "inline",
			hl_mode = "combine",
		})
	end

	return ids
end

--- Clear expansion hint extmarks.
--- @param bufnr integer
--- @param ids integer[]
local function clear_expansion_hints(bufnr, ids)
	for _, id in ipairs(ids) do
		vim.api.nvim_buf_del_extmark(bufnr, consts.ns_id, id)
	end
end

--- Synthesize a merged target spanning from first to last target.
--- @param bufnr integer
--- @param first table First target in range
--- @param last table Last target in range
--- @param original table The originally selected target (for metadata)
--- @return table Merged target
local function synthesize_target(bufnr, first, last, original)
	local lines = vim.api.nvim_buf_get_text(
		bufnr,
		first.start_pos.row,
		first.start_pos.col,
		last.end_pos.row,
		last.end_pos.col,
		{}
	)

	return {
		start_pos = { row = first.start_pos.row, col = first.start_pos.col },
		end_pos = { row = last.end_pos.row, col = last.end_pos.col },
		text = table.concat(lines, "\n"),
		type = original.type,
		metadata = original.metadata,
	}
end

--- Run the interactive expansion loop.
--- After a target is selected, allows the user to expand/shrink the range
--- using +/- keys before the action's second step (e.g., typing a delimiter).
---
--- Any key that isn't +/-/BS/ESC is treated as an implicit confirm and is
--- fed back to the input queue so the action receives it (e.g., the delimiter
--- character for surround_add).
---
--- @param ctx SmartMotionContext
--- @param cfg SmartMotionConfig
--- @param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	if not motion_state.expansion_enabled then
		return
	end

	local selected = motion_state.selected_jump_target
	if not selected then
		return
	end

	local jump_targets = motion_state.jump_targets
	if not jump_targets or #jump_targets < 2 then
		return
	end

	-- Sort targets by buffer position so +/- expand spatially
	local sorted = sort_by_position(jump_targets)

	local anchor = find_anchor_index(sorted, selected)
	if not anchor then
		return
	end

	local expansion_keys = cfg.expansion_keys
	if not expansion_keys then
		return
	end

	-- Pause flow state so the timer doesn't expire during expansion
	flow_state.pause_flow()

	-- Clear hint labels and show initial selection
	highlight.clear(ctx, cfg, motion_state)

	local bufnr = (selected.metadata and selected.metadata.bufnr) or ctx.bufnr
	local forward_extent = 0
	local backward_extent = 0
	local expansion_history = {}

	-- Show initial highlight + expansion hints
	local hl_id = highlight_range(bufnr, selected, selected)
	local hint_ids = show_expansion_hints(bufnr, sorted, anchor, forward_extent, backward_extent)
	vim.cmd("redraw")

	while true do
		local ok, char = pcall(vim.fn.getcharstr)
		if not ok then
			-- Error (e.g., Ctrl-C) — cancel
			motion_state.selected_jump_target = nil
			vim.api.nvim_buf_del_extmark(bufnr, consts.ns_id, hl_id)
			clear_expansion_hints(bufnr, hint_ids)
			flow_state.resume_flow()
			return
		end

		-- Check expansion keys (check keytrans for special keys like <BS>)
		local key_name = vim.fn.keytrans(char)
		local action = expansion_keys[key_name] or expansion_keys[char]

		if action == "expand_forward" then
			if anchor + forward_extent < #sorted then
				forward_extent = forward_extent + 1
				table.insert(expansion_history, "forward")
			end
		elseif action == "expand_backward" then
			if anchor - backward_extent > 1 then
				backward_extent = backward_extent + 1
				table.insert(expansion_history, "backward")
			end
		elseif action == "shrink" then
			if #expansion_history > 0 then
				local last_dir = table.remove(expansion_history)
				if last_dir == "forward" then
					forward_extent = forward_extent - 1
				else
					backward_extent = backward_extent - 1
				end
			end
		else
			-- ESC cancels
			if char == "\027" or char == "" then
				motion_state.selected_jump_target = nil
				vim.api.nvim_buf_del_extmark(bufnr, consts.ns_id, hl_id)
				clear_expansion_hints(bufnr, hint_ids)
				flow_state.resume_flow()
				return
			end

			-- Any other key = implicit confirm. Feed the key back so the
			-- action receives it (e.g., the delimiter char for surround_add).
			vim.api.nvim_feedkeys(char, "t", false)
			break
		end

		-- Re-render the range highlight and expansion hints
		vim.api.nvim_buf_del_extmark(bufnr, consts.ns_id, hl_id)
		clear_expansion_hints(bufnr, hint_ids)

		local range_first = sorted[anchor - backward_extent]
		local range_last = sorted[anchor + forward_extent]
		hl_id = highlight_range(bufnr, range_first, range_last)
		hint_ids = show_expansion_hints(bufnr, sorted, anchor, forward_extent, backward_extent)
		vim.cmd("redraw")
	end

	-- Clean up highlights
	vim.api.nvim_buf_del_extmark(bufnr, consts.ns_id, hl_id)
	clear_expansion_hints(bufnr, hint_ids)

	-- Synthesize merged target if range was expanded
	if forward_extent > 0 or backward_extent > 0 then
		local range_first = sorted[anchor - backward_extent]
		local range_last = sorted[anchor + forward_extent]
		motion_state.selected_jump_target = synthesize_target(bufnr, range_first, range_last, selected)
		motion_state.is_expanded_range = true
	end

	flow_state.resume_flow()
end

return M
