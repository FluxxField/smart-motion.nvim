local pair_defs = require("smart-motion.utils.pair_defs")
local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

---@type SmartMotionActionModuleEntry
local M = {}

--- Visual surround: wrap visual selection with prompted delimiter.
--- Mapped to `S` in visual mode.
function M.run()
	-- Exit visual mode to set marks, then read them
	vim.cmd("normal! \27")

	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")
	local sr = start_pos[2] - 1 -- 0-indexed
	local sc = start_pos[3] - 1
	local er = end_pos[2] - 1
	local ec = end_pos[3] -- exclusive end for nvim_buf_set_text

	local bufnr = vim.api.nvim_get_current_buf()

	-- Highlight the selection so the user sees what will be wrapped
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
		log.debug("surround_visual: invalid pair character '" .. char .. "'")
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

	-- Insert close delimiter after selection end first (preserves start positions)
	vim.api.nvim_buf_set_text(bufnr, er, ec, er, ec, { close_text })

	vim.cmd("undojoin")

	-- Insert open delimiter before selection start
	vim.api.nvim_buf_set_text(bufnr, sr, sc, sr, sc, { open_text })

	log.debug(string.format("surround_visual: wrapped selection with '%s%s'", open_text, close_text))
end

return M
