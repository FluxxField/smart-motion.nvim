local log = require("smart-motion.core.log")

---@type SmartMotionActionModuleEntry
local M = {}

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local mode = motion_state.paste_mode or "after"
	local key = mode == "before" and "P" or "p"

	vim.cmd("normal! " .. key)
end

return M
