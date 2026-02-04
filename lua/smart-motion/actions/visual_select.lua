--- Visual range selection via dual label picks.
--- Triggered by `gs`: pick two word targets, enter visual mode spanning the range.
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

--- Runs visual range selection: pick two targets, enter visual mode.
function M.run()
	local context = require("smart-motion.core.context")
	local state = require("smart-motion.core.state")
	local highlight = require("smart-motion.core.highlight")
	local dual_selection = require("smart-motion.core.dual_selection")
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

	local first, second = dual_selection.run(ctx, cfg, motion_state)

	if not first or not second then
		highlight.clear(ctx, cfg, motion_state)
		vim.cmd("redraw")
		return
	end

	-- Order: ensure first is before second positionally
	if first.start_pos.row > second.start_pos.row
		or (first.start_pos.row == second.start_pos.row
			and first.start_pos.col > second.start_pos.col) then
		first, second = second, first
	end

	-- Switch to first target's window if needed
	local winid = first.metadata and first.metadata.winid or ctx.winid
	if winid ~= vim.api.nvim_get_current_win() then
		vim.api.nvim_set_current_win(winid)
	end

	-- Set cursor to start, enter visual, extend to end
	vim.api.nvim_win_set_cursor(winid, { first.start_pos.row + 1, first.start_pos.col })
	vim.cmd("normal! v")
	vim.api.nvim_win_set_cursor(winid, { second.end_pos.row + 1, math.max(second.end_pos.col - 1, 0) })
end

return M
