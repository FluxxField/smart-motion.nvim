--- Handles virtual text and hint highlighting.
local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local HINT_POSITION = consts.HINT_POSITION

local M = {}

--- Clears all SmartMotion highlights in the current buffer.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.clear(ctx, cfg, motion_state)
	log.debug("Clearing all highlights in buffer " .. ctx.bufnr)

	vim.api.nvim_buf_clear_namespace(ctx.bufnr, consts.ns_id, 0, -1)
end

--- Applies a single-character hint label at a given position.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@param target Target
---@param label string
---@param options HintOptions
function M.apply_single_hint_label(ctx, cfg, motion_state, target, label, options)
	options = options or {}

	local row = target.start_pos.row
	local col = target.start_pos.col

	local prefix = ""
	local virt_text = {}

	local highlight = cfg.highlight
	local hint = highlight.hint or "SmartMotionHint"
	local hint_dim = highlight.hint_dim or "SmartMotionHintDim"
	local prefix_highlight = highlight.search_prefix or "SmartMotionSearchPrefix"
	local prefix_dim_highlight = highlight.search_prefix_dim or "SmartMotionSearchPrefixDim"

	local hint_hl = hint
	local prefix_hl = prefix_highlight

	log.debug(string.format("Applying single hint '%s' at line %d, col %d", label, row, col))

	if motion_state.hint_position == HINT_POSITION.END then
		col = max(target.end_pos.col - 1, 0)
	end

	if motion_state.is_searching_mode and motion_state.search_text and #motion_state.search_text >= 1 then
		prefix = motion_state.search_text:sub(1, #motion_state.search_text)
	end

	if motion_state.is_searching_mode then
		col = target.start_pos.col

		hint_hl = hint_dim
		prefix_hl = prefix_dim_highlight
	end

	if #prefix > 0 then
		table.insert(virt_text, { prefix, prefix_hl })
	end

	table.insert(virt_text, { label, hint_hl })

	vim.api.nvim_buf_set_extmark(ctx.bufnr, consts.ns_id, row, col, {
		virt_text = virt_text,
		virt_text_pos = "overlay",
		hl_mode = "combine",
	})
end

--- @class HintOptions
--- @field dim_first_char? boolean
--- @field dim_second_char? boolean

--- Applies a double-character hint label at a given position.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@param target Target
---@param label string
---@param options HintOptions
function M.apply_double_hint_label(ctx, cfg, motion_state, target, label, options)
	options = options or {}

	local row = target.start_pos.row
	local col = target.start_pos.col

	local first_char = label:sub(1, 1)
	local second_char = label:sub(2, 2)
	local prefix = ""
	local virt_text = {}

	local highlight = cfg.highlight
	local two_char_hint = highlight.two_char_hint or "SmartMotionTwoCharHint"
	local two_char_hint_dim = highlight.two_char_hint_dim or "SmartMotionTwoCharHintDim"
	local prefix_highlight = highlight.search_prefix or "SmartMotionSearchPrefix"
	local prefix_dim_highlight = highlight.search_prefix_dim or "SmartMotionSearchPrefixDim"

	local first_hl = two_char_hint
	local second_hl = two_char_hint_dim
	local prefix_hl = prefix_highlight

	log.debug(string.format("Extmark for '%s' at row: %d col: %d", label, row, col))

	if motion_state.hint_position == HINT_POSITION.END then
		col = max(target.end_pos.col - 1, 0)
	end

	if motion_state.is_searching_mode and motion_state.search_text and #motion_state.search_text >= 1 then
		prefix = motion_state.search_text:sub(1, #motion_state.search_text)
	end

	if motion_state.is_searching_mode then
		col = target.start_pos.col

		first_hl = two_char_hint_dim
		second_hl = two_char_hint_dim
		prefix_hl = prefix_dim_highlight
	else
		if options.dim_first_char then
			first_hl = two_char_hint_dim
			second_hl = two_char_hint
		end
	end

	if #prefix > 0 then
		table.insert(virt_text, { prefix, prefix_hl })
	end

	table.insert(virt_text, { first_char, first_hl })
	table.insert(virt_text, { second_char, second_hl })

	vim.api.nvim_buf_set_extmark(ctx.bufnr, consts.ns_id, row, col, {
		virt_text = virt_text,
		virt_text_pos = "overlay",
		hl_mode = "combine",
	})
end

--- Dims the background for the entire buffer.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.dim_background(ctx, cfg, motion_state)
	local total_lines = vim.api.nvim_buf_line_count(ctx.bufnr)

	-- Dim the entire buffer by applying the dim highlight group to every line.
	for line = 0, total_lines - 1 do
		vim.api.nvim_buf_add_highlight(ctx.bufnr, consts.ns_id, cfg.highlight.dim or "SmartMotionDim", line, 0, -1)
	end

	vim.cmd("redraw")
end

--- Filters double-character hints to only show those matching the active prefix.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@param active_prefix string
function M.filter_double_hints(ctx, cfg, motion_state, active_prefix)
	log.debug("Filtering double hints with prefix: " .. active_prefix)

	M.clear(ctx, cfg, motion_state)
	M.dim_background(ctx, cfg, motion_state)

	for label, entry in pairs(motion_state.assigned_hint_labels) do
		if #label == 2 and label:sub(1, 1) == active_prefix then
			local target = entry.target
			if not target then
				log.error("filter_double_hints: Missing target for label " .. label)
				goto continue
			end

			M.apply_double_hint_label(ctx, cfg, motion_state, target, label, { dim_first_char = true })

			::continue::
		end
	end

	vim.cmd("redraw")
end

return M
