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

	-- Operator-pending mode: custom mappings are exclusive by default, but
	-- native vim motions (f/F/t/T) are inclusive. Compensate so behavior matches:
	-- - f-style (no exclude_target): move 1 past target so exclusive includes it
	-- - t-style (exclude_target): keep at target pos, let exclusive handle "till"
	local is_op_pending = ctx.mode and ctx.mode:find("o")

	if is_op_pending then
		if not motion_state.exclude_target then
			-- Forward (or unknown direction): nudge cursor 1 right so the
			-- exclusive operator range still includes the target character.
			if motion_state.direction ~= "before_cursor" then
				col = col + 1
			end
		end
		-- exclude_target: no offset needed — exclusive naturally excludes the target
	else
		-- Normal/visual mode: apply till offset for t/T motions
		if motion_state.exclude_target then
			if motion_state.direction == "after_cursor" then
				col = col - 1
			elseif motion_state.direction == "before_cursor" then
				col = col + 1
			end
		end
	end

	if type(target) ~= "table" or not row or not col then
		log.error("jump_to_target called with invalid target table: " .. vim.inspect(motion_state.selected_jump_target))

		return
	end

	-- Save current position to jumplist before moving
	if cfg.save_to_jumplist then
		vim.cmd("normal! m'")
	end

	local current_winid = vim.api.nvim_get_current_win()
	if winid and winid ~= current_winid then
		vim.api.nvim_set_current_win(winid)
	end

	local pos = { row + 1, math.max(col, 0) }

	-- In op-pending mode with col+1 compensation, the target may be past end of
	-- line. Temporarily allow cursor past EOL so the operator range is correct.
	local saved_ve
	if is_op_pending and not motion_state.exclude_target and motion_state.direction ~= "before_cursor" then
		local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
		if col >= #(line or "") then
			saved_ve = vim.o.virtualedit
			vim.o.virtualedit = "onemore"
		end
	end

	local success, err = pcall(vim.api.nvim_win_set_cursor, winid or 0, pos)

	if saved_ve ~= nil then
		vim.schedule(function()
			vim.o.virtualedit = saved_ve
		end)
	end

	if not success then
		log.error("Failed to move cursor: " .. tostring(err))
		return
	end

	-- Open any folds at the target position
	if not is_op_pending and cfg.open_folds_on_jump then
		vim.cmd("normal! zv")
	end

	log.debug(string.format("Cursor moved to line %d, col %d", row, col))
end

return M
