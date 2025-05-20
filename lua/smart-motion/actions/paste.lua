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

	if motion_state.exclude then
		col = math.max(0, col - 1)
	end

	local paste_mode = motion_state.paste_mode or "after" -- default to `p`

	-- Jump to the target and paste in normal mode
	vim.api.nvim_win_set_cursor(0, { row + 1, col })
	local ok, err = pcall(function()
		vim.cmd("normal! " .. (paste_mode == "before" and "P" or "p"))
	end)

	if not ok then
		log.error("Action Paste: " .. tostring(err))
	end
end

return M
