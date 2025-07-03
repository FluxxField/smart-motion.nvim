local log = require("smart-motion.core.log")

---@type SmartMotionActionModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local bufnr = target.metadata.bufnr
	local row = target.end_pos.row
	local col = target.end_pos.col
	local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""

	if col == #line then
		vim.cmd("normal! Y")
	else
		if motion_state.until then
			col = math.max(0, col - 1)
		end

		vim.api.nvim_buf_set_mark(bufnr, ">", row + 1, col, {})
		vim.cmd("normal! y`>")
	end

	vim.highlight.on_yank({
		higroup = "IncSearch",
		timeout = 150,
		on_visual = false,
	})

	-- Clear mark
	local ok = pcall(vim.api.nvim_buf_del_mark, bufnr, ">")
	if not ok then
		log.error("action Yank: del_mark failed")
	end
end

return M
