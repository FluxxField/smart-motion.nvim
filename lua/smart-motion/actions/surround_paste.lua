local log = require("smart-motion.core.log")

---@type SmartMotionActionModuleEntry
local M = {}

--- Standalone surround paste: wrap target with previously yanked pair.
--- Reads pair from vim.g.smart_motion_surround_pair (set by ysi( etc.).
--- Mapped to `gzp` in normal mode.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	if not target then
		log.debug("surround_paste: no selected target")
		return
	end

	local stored = vim.g.smart_motion_surround_pair
	if not stored or #stored < 2 then
		log.debug("surround_paste: no stored surround pair (use ysi( first)")
		return
	end

	local bufnr = target.metadata.bufnr
	local sr = target.start_pos.row
	local sc = target.start_pos.col
	local er = target.end_pos.row
	local ec = target.end_pos.col

	-- Extract open and close from stored pair string
	local open_char = stored:sub(1, 1)
	local close_char = stored:sub(2, 2)

	-- Join both edits into one undo step (pcall: may fail after undo)
	pcall(vim.cmd, "undojoin")

	-- Insert close delimiter first (preserves start positions)
	vim.api.nvim_buf_set_text(bufnr, er, ec, er, ec, { close_char })

	vim.cmd("undojoin")

	-- Insert open delimiter
	vim.api.nvim_buf_set_text(bufnr, sr, sc, sr, sc, { open_char })

	log.debug(string.format("surround_paste: wrapped with '%s%s'", open_char, close_char))
end

return M
