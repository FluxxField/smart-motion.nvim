local log = require("smart-motion.core.log")

local M = {}

--- Executes the actual cursor movement to the given target.
---@param ctx table  Motion context (must include bufnr).
---@param cfg table  Validated configuration (not used here but part of the signature).
---@param motion_state table  Current motion state (not used here but part of the signature).
function M.execute(ctx, cfg, motion_state)
	local jump_target = motion_state.selected_jump_target

	log.debug(
		string.format(
			"Executing jump to target - row: %d, col: %d, bufnr: %d, start_col: %d, end_col: %d",
			jump_target.row,
			jump_target.col,
			jump_target.bufnr,
			jump_target.start_pos.col,
			jump_target.end_pos.col
		)
	)

	if type(jump_target) ~= "table" or not jump_target.row or not jump_target.col then
		log.error("jump_to_target called with invalid target table: " .. vim.inspect(motion_state.selected_jump_target))

		return
	end

	if jump_target.bufnr ~= vim.api.nvim_get_current_buf() then
		vim.api.nvim_set_current_buf(jump_target.bufnr)
	end

	local pos = { jump_target.row + 1, jump_target.col }

	local success, err = pcall(vim.api.nvim_win_set_cursor, jump_target.winid or 0, pos)

	if not success then
		log.error("Failed to move cursor: " .. tostring(err))
	else
		log.debug(string.format("Cursor moved to line %d, col %d", jump_target.row, jump_target.col))
	end
end

return M
