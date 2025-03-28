local M = {}

function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local row = target.end_pos.row
	local bufnr = target.bufnr

	-- Get the line content
	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)

	-- Yank the line to default register
	vim.fn.setreg('"', line[1] .. "\n")
end

return M
