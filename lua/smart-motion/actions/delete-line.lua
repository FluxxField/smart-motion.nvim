---@type SmartMotionActionModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local row = target.end_pos.row
	local bufnr = target.metadata.bufnr

	-- Delete the entire line the target is on
	vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, {})
end

return M
