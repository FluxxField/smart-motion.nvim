local utils = require("smart-motion.actions.utils")

---@type SmartMotionActionModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local bufnr = target.metadata.bufnr
	local start_row, start_col, end_row, end_col = utils.resolve_range(ctx, motion_state)

	local text, regtype
	if target.type == "lines" and not motion_state.exclude_target then
		local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
		text = table.concat(lines, "\n")
		regtype = "l"
		utils.set_register(bufnr, start_row, start_col, end_row, end_col, text, regtype, "d")
		vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, {})
	else
		local lines = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
		text = table.concat(lines, "\n")
		regtype = "c"
		utils.set_register(bufnr, start_row, start_col, end_row, end_col, text, regtype, "d")
		vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, { "" })
	end
end

return M
