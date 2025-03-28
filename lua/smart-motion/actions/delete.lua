local M = {}

function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local line = vim.api.nvim_buf_get_lines(target.bufnr, target.end_pos.row, target.end_pos.row + 1, false)[1] or ""

	-- Delete to the end of the line
	if target.end_pos.col == #line then
		vim.cmd("normal! D")
	else
		vim.api.nvim_buf_set_mark(target.bufnr, ">", target.end_pos.row + 1, target.end_pos.col, {})
		vim.cmd("normal! d`>")
	end

	-- Clear mark
	vim.api.nvim_buf_del_mark(target.bufnr, ">")
end

return M
