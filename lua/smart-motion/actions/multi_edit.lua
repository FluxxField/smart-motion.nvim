--- Multi-cursor edit: select multiple word targets, then delete or yank them all.
--- Triggered by `gmd` (delete) or `gmy` (yank).
local consts = require("smart-motion.consts")

local M = {}

--- Collects word targets across visible lines in all windows.
---@param ctx SmartMotionContext
---@return table[]
function M._collect_word_targets(ctx)
	local targets = {}
	local pattern = consts.WORD_PATTERN

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
					type = "words",
					metadata = { bufnr = bufnr, winid = winid },
				})

				col = end_col + 1
			end
		end

		::continue::
	end

	return targets
end

--- Runs multi-cursor edit: show labels, toggle-select multiple, then act.
---@param action_type "delete"|"yank"
function M.run(action_type)
	local context = require("smart-motion.core.context")
	local state = require("smart-motion.core.state")
	local highlight = require("smart-motion.core.highlight")
	local hints = require("smart-motion.visualizers.hints")
	local multi_selection = require("smart-motion.core.multi_selection")
	local cfg_mod = require("smart-motion.config")

	local cfg = cfg_mod.validated
	if not cfg then
		return
	end

	local ctx = context.get()
	local motion_state = state.create_motion_state()
	motion_state.multi_window = true

	local targets = M._collect_word_targets(ctx)
	if #targets == 0 then
		return
	end

	motion_state.jump_targets = targets
	state.finalize_motion_state(ctx, cfg, motion_state)

	-- Show initial hints
	hints.run(ctx, cfg, motion_state)

	-- Multi-selection loop (toggle labels, Enter to confirm, ESC to cancel)
	local selected = multi_selection.wait_for_multi_selection(ctx, cfg, motion_state)

	highlight.clear(ctx, cfg, motion_state)
	vim.cmd("redraw")

	if not selected or #selected == 0 then
		return
	end

	if action_type == "delete" then
		-- Delete each selected target (reverse order for position stability)
		for _, target in ipairs(selected) do
			local bufnr = (target.metadata and target.metadata.bufnr) or ctx.bufnr
			vim.api.nvim_buf_set_text(bufnr,
				target.start_pos.row, target.start_pos.col,
				target.end_pos.row, target.end_pos.col, { "" })
		end
	elseif action_type == "yank" then
		-- Collect all selected texts and yank them (newline-separated)
		-- Targets are in reverse order, so reverse to get natural order for yank
		local texts = {}
		for i = #selected, 1, -1 do
			local target = selected[i]
			local bufnr = (target.metadata and target.metadata.bufnr) or ctx.bufnr
			local text = vim.api.nvim_buf_get_text(bufnr,
				target.start_pos.row, target.start_pos.col,
				target.end_pos.row, target.end_pos.col, {})
			table.insert(texts, table.concat(text, "\n"))
		end
		vim.fn.setreg('"', table.concat(texts, "\n"))
	end
end

return M
