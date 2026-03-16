local utils = require("smart-motion.actions.utils")

---@type SmartMotionActionModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local bufnr = target.metadata.bufnr
	local winid = target.metadata.winid
	local start_row, start_col, end_row, end_col = utils.resolve_range(ctx, motion_state)

	local text, regtype
	if target.type == "lines" and not motion_state.exclude_target then
		local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
		text = table.concat(lines, "\n")
		regtype = "l"
		utils.set_register(bufnr, start_row, start_col, end_row, end_col, text, regtype, "c")
		-- Preserve indentation of the first line
		local indent = lines[1] and lines[1]:match("^(%s*)") or ""
		vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, { indent })
		vim.api.nvim_win_set_cursor(winid, { start_row + 1, #indent })
	else
		local lines = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
		text = table.concat(lines, "\n")
		regtype = "c"
		utils.set_register(bufnr, start_row, start_col, end_row, end_col, text, regtype, "c")
		vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, { "" })
		vim.api.nvim_win_set_cursor(winid, { start_row + 1, start_col })
	end

	vim.cmd("startinsert")
end

return M
