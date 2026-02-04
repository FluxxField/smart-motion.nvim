local log = require("smart-motion.core.log")
local resolve_range = require("smart-motion.actions.utils").resolve_range

---@type SmartMotionActionModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local bufnr = target.metadata.bufnr
	local winid = target.metadata.winid
	local start_row, start_col, end_row, end_col = resolve_range(ctx, motion_state)

	if target.type == "lines" and not motion_state.exclude_target then
		local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
		vim.fn.setreg('"', table.concat(lines, "\n"), "l")
		vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, { "" })
		vim.api.nvim_win_set_cursor(winid, { start_row + 1, 0 })
	else
		local text = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
		vim.fn.setreg('"', table.concat(text, "\n"), "c")
		vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, { "" })
		vim.api.nvim_win_set_cursor(winid, { start_row + 1, start_col })
	end

	vim.cmd("startinsert")
end

return M
