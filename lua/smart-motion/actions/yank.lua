local M = {}

function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local line = vim.api.nvim_buf_get_lines(target.bufnr, target.end_pos.row, target.end_pos.row + 1, false)[1] or ""

	if target.end_pos.col == #line then
		vim.cmd("normal! Y")
	else
		vim.api.nvim_buf_set_mark(0, ">", target.end_pos.row + 1, target.end_pos.col, {})
		vim.cmd("normal! y`>")
	end

	-- Clear mark
	vim.api.nvim_buf_del_mark(target.bufnr, ">")
end

return M
