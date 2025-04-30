local log = require("smart-motion.core.log")

---@type SmartMotionActionModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local bufnr = target.metadata.bufnr
	local col = target.end_pos.col
	local row = target.end_pos.row
	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""

	-- Delete to the end of the line
	if col == #line then
		vim.cmd("normal! D")
	else
		vim.api.nvim_buf_set_mark(bufnr, ">", row + 1, col, {})
		vim.cmd("normal! d`>")
	end

	-- Clear mark
	local ok = pcall(vim.api.nvim_buf_del_mark, bufnr, ">")

	if not ok then
		log.error("Action Delete: del_mark failed")
	end
end

return M
