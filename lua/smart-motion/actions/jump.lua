local HINT_POSITION = require("smart-motion.consts").HINT_POSITION
local log = require("smart-motion.core.log")

---@type SmartMotionActionModuleEntry
local M = {}

--- Executes the actual cursor movement to the given target.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local bufnr = target.metadata.bufnr
	local winid = target.metadata.winid
	local col = target.start_pos.col
	local row = target.start_pos.row

	if motion_state.hint_position == HINT_POSITION.END then
		col = target.end_pos.col - 1
		row = target.end_pos.row
	end

	-- Till offset: exclude_target stops one position before the match
	if motion_state.exclude_target then
		if motion_state.direction == "after_cursor" then
			col = col - 1
		elseif motion_state.direction == "before_cursor" then
			col = col + 1
		end
	end

	if type(target) ~= "table" or not row or not col then
		log.error("jump_to_target called with invalid target table: " .. vim.inspect(motion_state.selected_jump_target))

		return
	end

	-- Save current position to jumplist before moving
	vim.cmd("normal! m'")

	local current_winid = vim.api.nvim_get_current_win()
	if winid and winid ~= current_winid then
		vim.api.nvim_set_current_win(winid)
	end

	local pos = { row + 1, math.max(col, 0) }
	local success, err = pcall(vim.api.nvim_win_set_cursor, winid or 0, pos)

	if not success then
		log.error("Failed to move cursor: " .. tostring(err))
		return
	end

	-- Open any folds at the target position
	vim.cmd("normal! zv")

	log.debug(string.format("Cursor moved to line %d, col %d", row, col))
end

return M
