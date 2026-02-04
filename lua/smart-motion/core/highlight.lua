--- Handles virtual text and hint highlighting.
local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local HINT_POSITION = consts.HINT_POSITION

local M = {}

--- Clears all SmartMotion highlights in all affected buffers.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.clear(ctx, cfg, motion_state)
	if motion_state.affected_buffers and next(motion_state.affected_buffers) then
		for bufnr, _ in pairs(motion_state.affected_buffers) do
			if vim.api.nvim_buf_is_valid(bufnr) then
				log.debug("Clearing highlights in buffer " .. bufnr)
				vim.api.nvim_buf_clear_namespace(bufnr, consts.ns_id, 0, -1)
			end
		end
	else
		log.debug("Clearing all highlights in buffer " .. ctx.bufnr)
		vim.api.nvim_buf_clear_namespace(ctx.bufnr, consts.ns_id, 0, -1)
	end
end

--- Applies a single-character hint label at a given position.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@param target Target
---@param label string
---@param options HintOptions
function M.apply_single_hint_label(ctx, cfg, motion_state, target, label)
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
		col = math.max(target.end_pos.col - 1, 0)
	end

	if motion_state.should_show_prefix and motion_state.search_text and #motion_state.search_text >= 1 then
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

	local bufnr = (target.metadata and target.metadata.bufnr) or ctx.bufnr
	motion_state.affected_buffers = motion_state.affected_buffers or {}
	motion_state.affected_buffers[bufnr] = true

	local line_text = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
	if line_text then
		col = math.min(col, #line_text)
	end

	vim.api.nvim_buf_set_extmark(bufnr, consts.ns_id, row, col, {
		virt_text = virt_text,
		virt_text_pos = motion_state.virt_text_pos or "overlay",
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
		col = math.max(target.end_pos.col - 1, 0)
	end

	if motion_state.should_show_prefix and motion_state.search_text and #motion_state.search_text >= 1 then
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

	local bufnr = (target.metadata and target.metadata.bufnr) or ctx.bufnr
	motion_state.affected_buffers = motion_state.affected_buffers or {}
	motion_state.affected_buffers[bufnr] = true

	local line_text = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
	if line_text then
		col = math.min(col, #line_text)
	end

	vim.api.nvim_buf_set_extmark(bufnr, consts.ns_id, row, col, {
		virt_text = virt_text,
		virt_text_pos = motion_state.virt_text_pos or "overlay",
		hl_mode = "combine",
	})
end

--- Dims the background for the entire buffer.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.dim_background(ctx, cfg, motion_state)
	-- NOTE: Rename config to dim_background
	if cfg.disable_dim_background ~= false or motion_state.dim_background == false then
		return
	end

	-- Collect unique buffers to dim
	local buffers_to_dim = { [ctx.bufnr] = true }
	if motion_state.multi_window and ctx.windows then
		for _, win in ipairs(ctx.windows) do
			buffers_to_dim[win.bufnr] = true
		end
	end

	motion_state.affected_buffers = motion_state.affected_buffers or {}

	for bufnr, _ in pairs(buffers_to_dim) do
		if vim.api.nvim_buf_is_valid(bufnr) then
			motion_state.affected_buffers[bufnr] = true
			local total_lines = vim.api.nvim_buf_line_count(bufnr)
			for line = 0, total_lines - 1 do
				vim.api.nvim_buf_add_highlight(bufnr, consts.ns_id, cfg.highlight.dim or "SmartMotionDim", line, 0, -1)
			end
		end
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
