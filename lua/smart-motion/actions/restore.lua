---@type SmartMotionActionModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	vim.api.nvim_win_set_cursor(ctx.winid, { ctx.cursor_line + 1, ctx.cursor_col })
end

return M
