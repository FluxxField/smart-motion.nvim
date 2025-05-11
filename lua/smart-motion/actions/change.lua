local log = require("smart-motion.core.log")

---@type SmartMotionActionModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local bufnr = target.metadata.bufnr
	local winid = target.metadata.winid
	local row = target.end_pos.row
	local col = target.end_pos.col

	if motion_state.exclude then
		col = math.max(0, col - 1)
	end

	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""

	if col >= #line then
		vim.cmd("normal! C")
		vim.cmd("startinsert!")
	else
		local ok, pos = pcall(vim.api.nvim_win_get_cursor, winid)

		if ok and pos then
			local cur_row, cur_col = unpack(pos)

			vim.api.nvim_buf_set_mark(bufnr, ">", row + 1, col, {})
			vim.cmd("normal! c`>")
			vim.api.nvim_win_set_cursor(winid, { cur_row, cur_col })
			vim.cmd("startinsert")
		end
	end

	-- Clear mark
	local ok = pcall(vim.api.nvim_buf_del_mark, bufnr, ">")
	if not ok then
		log.error("Action Change: del_mark failed")
	end
end

return M
