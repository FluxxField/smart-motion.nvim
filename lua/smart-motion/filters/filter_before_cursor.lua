---@type SmartMotionFilterModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@param opts table
---@return nil
function M.run(ctx, cfg, motion_state, opts)
	local cursor_row, cursor_col = ctx.cursor_line, ctx.cursor_col

	motion_state.jump_targets = vim.tbl_filter(function()
		return target.start_pos.row < cursor_row
			or (target.start_pos.row == cursor_row and target.start_pos.col <= cursor_col)
	end, motion_state.jump_targets)
end

return M
