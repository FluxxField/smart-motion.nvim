---@type SmartMotionActionModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local bufnr = target.bufnr
	local row = target.end_pos.row

	vim.cmd("normal! Y")

	vim.highlight.on_yank({
		higroup = "IncSearch",
		timeout = 150,
		on_visual = false,
	})
end

return M
