--- Handles virtual text and hint highlighting.
local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

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
---@param jump_target JumpTarget
---@param label string
---@param options HintOptions
function M.apply_single_hint_label(ctx, cfg, motion_state, jump_target, label, options)
	log.debug(string.format("Applying single hint '%s' at line %d, col %d", label, jump_target.row, jump_target.col))

	local hint = cfg.highlight.hint or "SmartMotionHint"

	if options.dim_first_char then
		hint = cfg.highlight.hint_dim or "SmartMotionHintDim"
	end

	vim.api.nvim_buf_set_extmark(ctx.bufnr, consts.ns_id, jump_target.row, jump_target.col, {
		virt_text = { { label, hint } },
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
---@param jump_target JumpTarget
---@param label string
---@param options HintOptions
function M.apply_double_hint_label(ctx, cfg, motion_state, jump_target, label, options)
	options = options or {}

	log.debug(string.format("Extmark for '%s' at row: %d col: %d", label, jump_target.row - 1, jump_target.col))

	local first_char, second_char = label:sub(1, 1), label:sub(2, 2)

	local first_hl = options.dim_first_char and (cfg.highlight.first_char_dim or "SmartMotionFirstCharDim")
		or (cfg.highlight.first_char or "SmartMotionFirstChar")
	local second_hl = options.dim_second_char and (cfg.highlight.second_char_dim or "SmartMotionSecondCharDim")
		or (cfg.highlight.second_char or "SmartMotionSecondChar")

	local hint = cfg.highlight.hint or "SmartMotionHint"

	if faded then
		hint = cfg.highlight.hint_faded or "SmartMotionHintFaded"
	end

	log.debug(
		string.format(
			"Applying double hint '%s%s' at line %d, col %d",
			first_char,
			second_char,
			jump_target.row,
			jump_target.col
		)
	)

	vim.api.nvim_buf_set_extmark(ctx.bufnr, consts.ns_id, jump_target.row, jump_target.col, {
		virt_text = {
			{ first_char, first_hl },
			{ second_char, second_hl },
		},
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
			local jump_target = entry.jump_target
			if not jump_target then
				log.error("filter_double_hints: Missing target for label " .. label)
				goto continue
			end

			M.apply_double_hint_label(ctx, cfg, motion_state, jump_target, label, { dim_first_char = true })

			::continue::
		end
	end

	vim.cmd("redraw")
end

return M
