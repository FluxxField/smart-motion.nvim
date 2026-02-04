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
	local start_row, start_col, end_row, end_col = resolve_range(ctx, motion_state)

	if target.type == "lines" and not motion_state.exclude_target then
		local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
		vim.fn.setreg('"', table.concat(lines, "\n"), "l")
	else
		local text = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
		vim.fn.setreg('"', table.concat(text, "\n"), "c")
	end

	vim.highlight.on_yank({
		higroup = "IncSearch",
		timeout = 150,
		on_visual = false,
	})
end

return M
