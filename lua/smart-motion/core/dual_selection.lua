--- Shared helper for features needing two sequential label picks.
--- Used by visual range selection and argument swap.
local consts = require("smart-motion.consts")
local state = require("smart-motion.core.state")
local highlight = require("smart-motion.core.highlight")
local hints = require("smart-motion.visualizers.hints")
local selection = require("smart-motion.core.selection")

local M = {}

--- Runs two rounds of label selection on the same target set.
--- Returns (first, second) or (nil, nil) on cancel.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@param opts? { filter_second?: fun(targets: table[], first: table): table[] }
---@return table|nil, table|nil
function M.run(ctx, cfg, motion_state, opts)
	-- Round 1: show labels and let user pick first target
	hints.run(ctx, cfg, motion_state)
	selection.wait_for_hint_selection(ctx, cfg, motion_state)

	if not motion_state.selected_jump_target then
		highlight.clear(ctx, cfg, motion_state)
		vim.cmd("redraw")
		return nil, nil
	end

	local first = vim.deepcopy(motion_state.selected_jump_target)

	-- Save all targets before reset
	local all_targets = motion_state.jump_targets

	-- Reset selection state for round 2
	highlight.clear(ctx, cfg, motion_state)
	state.reset(motion_state)

	-- Filter targets for round 2
	local remaining
	if opts and opts.filter_second then
		remaining = opts.filter_second(all_targets, first)
	else
		remaining = vim.tbl_filter(function(t)
			return not (t.start_pos.row == first.start_pos.row
				and t.start_pos.col == first.start_pos.col
				and t.end_pos.row == first.end_pos.row
				and t.end_pos.col == first.end_pos.col)
		end, all_targets)
	end

	if #remaining == 0 then
		vim.cmd("redraw")
		return first, nil
	end

	motion_state.jump_targets = remaining
	state.finalize_motion_state(ctx, cfg, motion_state)

	-- Highlight first pick so user sees what they selected
	local first_bufnr = first.metadata and first.metadata.bufnr or ctx.bufnr
	vim.api.nvim_buf_set_extmark(first_bufnr, consts.ns_id, first.start_pos.row, first.start_pos.col, {
		end_col = first.end_pos.col,
		hl_group = cfg.highlight.hint or "SmartMotionHint",
	})
	motion_state.affected_buffers = motion_state.affected_buffers or {}
	motion_state.affected_buffers[first_bufnr] = true

	-- Round 2: show labels on remaining targets
	hints.run(ctx, cfg, motion_state)
	selection.wait_for_hint_selection(ctx, cfg, motion_state)

	local second = motion_state.selected_jump_target
		and vim.deepcopy(motion_state.selected_jump_target)
		or nil

	highlight.clear(ctx, cfg, motion_state)
	vim.cmd("redraw")

	return first, second
end

return M
