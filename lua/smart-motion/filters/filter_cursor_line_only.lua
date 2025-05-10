local log = require("smart-motion.core.log")

---@type SmartMotionFilterModuleEntry
local M = {}

--- Cursor Line Only Filter
--- Keeps only targets that are on the same line as the cursor.
---@type SmartMotionFilterModuleEntry
function M.run(ctx, cfg, motion_state, target)
	local cursor_row = ctx.cursor_line

	if target.start_pos.row == cursor_row then
		return target
	end
end

return M
