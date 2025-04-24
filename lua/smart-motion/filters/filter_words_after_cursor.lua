local consts = require("smart-motion.consts")
local HINT_POSITION = consts.HINT_POSITION

---@type SmartMotionFilterModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@param opts table
---@return nil
function M.run(ctx, cfg, motion_state, opts)
	local hint_position = motion_state.hint_position
	local cursor_row, cursor_col = ctx.cursor_line, ctx.cursor_col

	motion_state.jump_targets = vim.tbl_filter(function(target)
		if target.row ~= cursor_row then
			return target.row > cursor_row
		end

		if hint_position == HINT_POSITION.START then
			return target.start_pos.col >= cursor_col
		elseif hint_position == HINT_POSITION.END then
			return cursor_col < target.end_pos.col - 1
		end

		return true
	end, motion_state.jump_targets)
end

return M
