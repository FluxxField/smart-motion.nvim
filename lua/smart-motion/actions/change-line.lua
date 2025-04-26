---@type SmartMotionActionModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local row = target.end_pos.row
	local bufnr = target.metadata.bufnr

	-- Delete the line
	vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { "" })

	-- Move cursor to the start of the cleared line
	vim.api.nvim_win_set_cursor(0, { row + 1, 0 })

	-- Enter insert mode
	vim.cmd("startinsert")
end

return M
