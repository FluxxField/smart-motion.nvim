local pair_defs = require("smart-motion.utils.pair_defs")
local consts = require("smart-motion.consts")
local highlight = require("smart-motion.core.highlight")
local log = require("smart-motion.core.log")

---@type SmartMotionActionModuleEntry
local M = {}

--- Surround add: after target is selected, prompt for delimiter and wrap.
--- Used by both `gza` (standalone) and `ys` (infer operator) flows.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	if not target then
		log.debug("surround_add: no selected target")
		return
	end

	local bufnr = target.metadata.bufnr
	local sr = target.start_pos.row
	local sc = target.start_pos.col
	local er = target.end_pos.row
	local ec = target.end_pos.col

	-- Clear hint labels before showing the selected target
	highlight.clear(ctx, cfg, motion_state)

	-- Highlight the target so the user sees what will be wrapped
	local hl_id = vim.api.nvim_buf_set_extmark(bufnr, consts.ns_id, sr, sc, {
		end_row = er,
		end_col = ec,
		hl_group = "SmartMotionSelected",
	})
	vim.cmd("redraw")

	-- Prompt for delimiter character
	local ok, raw = pcall(vim.fn.getchar)

	-- Clean up highlight regardless of outcome
	vim.api.nvim_buf_del_extmark(bufnr, consts.ns_id, hl_id)

	if not ok then
		return
	end
	local char = type(raw) == "number" and vim.fn.nr2char(raw) or raw
	if char == "\027" then
		return
	end -- ESC cancels

	local pair = pair_defs.get_pair(char)
	if not pair then
		log.debug("surround_add: invalid pair character '" .. char .. "'")
		return
	end

	-- Special pairs (tag, function) need a name prompt
	if pair.special then
		local name = vim.fn.input(pair.prompt)
		pair = pair_defs.build_special_pair(pair.special, name)
		if not pair then
			return
		end
	end

	local open_text = pair.pad and (pair.open .. " ") or pair.open
	local close_text = pair.pad and (" " .. pair.close) or pair.close

	-- Join both edits into one undo step (pcall: may fail after undo)
	pcall(vim.cmd, "undojoin")

	-- Insert close delimiter first (preserves start positions)
	vim.api.nvim_buf_set_text(bufnr, er, ec, er, ec, { close_text })

	vim.cmd("undojoin")

	-- Insert open delimiter
	vim.api.nvim_buf_set_text(bufnr, sr, sc, sr, sc, { open_text })

	log.debug(string.format("surround_add: wrapped with '%s%s'", open_text, close_text))
end

return M
