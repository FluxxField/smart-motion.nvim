local M = {}

function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local bufnr = target.bufnr
	local row = target.end_pos.row
	local col = target.end_pos.col

	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""

	if col >= #line then
		vim.cmd("normal! D")
		vim.cmd("startinsert!")
	else
		vim.api.nvim_buf_set_mark(0, ">", row + 1, col, {})
		vim.cmd("normal! d`>")
		vim.cmd("startinsert")
	end

	-- Clear mark
	pcall(vim.api.nvim_buf_del_mark, bufnr, ">")
end

return M
