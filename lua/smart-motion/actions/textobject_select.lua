local log = require("smart-motion.core.log")

---@type SmartMotionActionModuleEntry
local M = {}

--- Sets a charwise visual selection spanning the target's range.
--- Works in both visual mode (replaces selection) and operator-pending mode
--- (the pending operator applies to the visual selection).
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local sr = target.start_pos.row
	local sc = target.start_pos.col
	local er = target.end_pos.row
	local ec = target.end_pos.col

	-- If in visual mode, escape first to replace selection (not extend)
	local mode = vim.fn.mode(true)
	if mode:find("[vV\22]") then
		vim.cmd("normal! \27")
	end

	-- Set charwise visual selection
	vim.api.nvim_win_set_cursor(ctx.winid or 0, { sr + 1, sc })
	vim.cmd("normal! v")

	-- Handle ec==0 edge case (node ends at start of next line)
	if ec == 0 and er > sr then
		local prev_line = vim.api.nvim_buf_get_lines(ctx.bufnr, er - 1, er, false)[1]
		vim.api.nvim_win_set_cursor(ctx.winid or 0, { er, math.max(#prev_line - 1, 0) })
	else
		vim.api.nvim_win_set_cursor(ctx.winid or 0, { er + 1, math.max(ec - 1, 0) })
	end

	log.debug(string.format("textobject_select: visual %d:%d to %d:%d", sr, sc, er, ec))
end

return M
