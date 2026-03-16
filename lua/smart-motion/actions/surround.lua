local pair_defs = require("smart-motion.utils.pair_defs")
local action_utils = require("smart-motion.actions.utils")
local consts = require("smart-motion.consts")
local highlight_mod = require("smart-motion.core.highlight")
local log = require("smart-motion.core.log")

---@type SmartMotionActionModuleEntry
local M = {}

--- Deletes delimiter characters from the buffer.
--- Removes close delimiter first to preserve positions.
--- When the user typed an opening char (e.g. ds( ), also strips inner padding.
--- @param ctx SmartMotionContext
--- @param motion_state SmartMotionMotionState
local function _delete_delimiters(ctx, motion_state)
	local target = motion_state.selected_jump_target
	local meta = target.metadata
	local bufnr = target.metadata.bufnr

	local open_pos = meta.open_pos
	local close_pos = meta.close_pos

	-- Check if the user typed the opening char (pad-aware deletion)
	local pair_info = motion_state.motion_key and pair_defs.get_pair(motion_state.motion_key)
	local strip_padding = pair_info and pair_info.pad

	-- Compute close delete range (optionally strip leading space)
	local close_start_row, close_start_col = close_pos.start.row, close_pos.start.col
	if strip_padding and close_start_col > 0 then
		local line = vim.api.nvim_buf_get_lines(bufnr, close_start_row, close_start_row + 1, false)[1]
		if line and line:sub(close_start_col, close_start_col) == " " then
			close_start_col = close_start_col - 1
		end
	end

	-- Compute open delete range (optionally strip trailing space)
	local open_end_row, open_end_col = open_pos["end"].row, open_pos["end"].col
	if strip_padding then
		local line = vim.api.nvim_buf_get_lines(bufnr, open_end_row, open_end_row + 1, false)[1]
		if line and line:sub(open_end_col + 1, open_end_col + 1) == " " then
			open_end_col = open_end_col + 1
		end
	end

	-- Join both edits into one undo step (pcall: may fail after undo)
	pcall(vim.cmd, "undojoin")

	-- Delete close delimiter first (preserves open positions)
	vim.api.nvim_buf_set_text(
		bufnr,
		close_start_row,
		close_start_col,
		close_pos["end"].row,
		close_pos["end"].col,
		{ "" }
	)

	vim.cmd("undojoin")

	-- Delete open delimiter
	vim.api.nvim_buf_set_text(
		bufnr,
		open_pos.start.row,
		open_pos.start.col,
		open_end_row,
		open_end_col,
		{ "" }
	)

	log.debug(string.format(
		"surround delete: removed '%s' at %d:%d and '%s' at %d:%d",
		meta.pair_open,
		open_pos.start.row,
		open_pos.start.col,
		meta.pair_close,
		close_pos.start.row,
		close_pos.start.col
	))
end

--- Yanks delimiter characters to the register.
--- @param ctx SmartMotionContext
--- @param motion_state SmartMotionMotionState
local function _yank_delimiters(ctx, motion_state)
	local target = motion_state.selected_jump_target
	local meta = target.metadata
	local bufnr = target.metadata.bufnr

	local text = meta.pair_open .. meta.pair_close

	action_utils.set_register(
		bufnr,
		meta.open_pos.start.row,
		meta.open_pos.start.col,
		meta.close_pos["end"].row,
		meta.close_pos["end"].col,
		text,
		"c",
		"y"
	)

	-- Store pair for paste surround
	vim.g.smart_motion_surround_pair = text

	log.debug(string.format("surround yank: yanked '%s'", text))
end

--- Highlights the open and close delimiters with SmartMotionSelected.
--- Returns extmark IDs for cleanup.
--- @param bufnr number
--- @param open_pos table
--- @param close_pos table
--- @return number[] extmark_ids
local function _highlight_delimiters(bufnr, open_pos, close_pos)
	local ids = {}
	ids[#ids + 1] = vim.api.nvim_buf_set_extmark(bufnr, consts.ns_id, open_pos.start.row, open_pos.start.col, {
		end_row = open_pos["end"].row,
		end_col = open_pos["end"].col,
		hl_group = "SmartMotionSelected",
	})
	ids[#ids + 1] = vim.api.nvim_buf_set_extmark(bufnr, consts.ns_id, close_pos.start.row, close_pos.start.col, {
		end_row = close_pos["end"].row,
		end_col = close_pos["end"].col,
		hl_group = "SmartMotionSelected",
	})
	vim.cmd("redraw")
	return ids
end

--- Clears extmarks created by _highlight_delimiters.
--- @param bufnr number
--- @param ids number[]
local function _clear_delimiter_highlights(bufnr, ids)
	for _, id in ipairs(ids) do
		vim.api.nvim_buf_del_extmark(bufnr, consts.ns_id, id)
	end
end

--- Changes delimiter characters by prompting for a replacement.
--- @param ctx SmartMotionContext
--- @param cfg SmartMotionConfig
--- @param motion_state SmartMotionMotionState
local function _change_delimiters(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local meta = target.metadata
	local bufnr = target.metadata.bufnr

	-- Clear hint labels before showing the selected delimiters
	highlight_mod.clear(ctx, cfg, motion_state)

	-- Highlight the selected delimiters so the user sees what they're changing
	local hl_ids = _highlight_delimiters(bufnr, meta.open_pos, meta.close_pos)

	-- Prompt for replacement character
	local ok, raw = pcall(vim.fn.getchar)

	-- Clean up highlights regardless of outcome
	_clear_delimiter_highlights(bufnr, hl_ids)

	if not ok then
		return
	end
	local char = type(raw) == "number" and vim.fn.nr2char(raw) or raw
	if char == "\027" then
		return
	end -- ESC cancels

	local new_pair = pair_defs.get_pair(char)
	if not new_pair then
		log.debug("surround change: invalid pair character '" .. char .. "'")
		return
	end

	-- Special pairs (tag, function) need a name prompt
	if new_pair.special then
		local name = vim.fn.input(new_pair.prompt)
		new_pair = pair_defs.build_special_pair(new_pair.special, name)
		if not new_pair then
			return
		end
	end

	local open_pos = meta.open_pos
	local close_pos = meta.close_pos

	-- Check if the source char (what the user typed for cs) is pad-aware
	local source_info = motion_state.motion_key and pair_defs.get_pair(motion_state.motion_key)
	local strip_padding = source_info and not source_info.special and source_info.pad

	-- New replacement text (opening char of replacement adds padding)
	local open_text = new_pair.pad and (new_pair.open .. " ") or new_pair.open
	local close_text = new_pair.pad and (" " .. new_pair.close) or new_pair.close

	-- Compute close replace range (optionally strip leading space from old delimiter)
	local close_start_row, close_start_col = close_pos.start.row, close_pos.start.col
	if strip_padding and close_start_col > 0 then
		local line = vim.api.nvim_buf_get_lines(bufnr, close_start_row, close_start_row + 1, false)[1]
		if line and line:sub(close_start_col, close_start_col) == " " then
			close_start_col = close_start_col - 1
		end
	end

	-- Compute open replace range (optionally strip trailing space from old delimiter)
	local open_end_row, open_end_col = open_pos["end"].row, open_pos["end"].col
	if strip_padding then
		local line = vim.api.nvim_buf_get_lines(bufnr, open_end_row, open_end_row + 1, false)[1]
		if line and line:sub(open_end_col + 1, open_end_col + 1) == " " then
			open_end_col = open_end_col + 1
		end
	end

	-- Join both edits into one undo step (pcall: may fail after undo)
	pcall(vim.cmd, "undojoin")

	-- Replace close delimiter first (preserves open positions)
	vim.api.nvim_buf_set_text(
		bufnr,
		close_start_row,
		close_start_col,
		close_pos["end"].row,
		close_pos["end"].col,
		{ close_text }
	)

	vim.cmd("undojoin")

	-- Replace open delimiter
	vim.api.nvim_buf_set_text(
		bufnr,
		open_pos.start.row,
		open_pos.start.col,
		open_end_row,
		open_end_col,
		{ open_text }
	)

	log.debug(string.format(
		"surround change: replaced '%s%s' with '%s%s'",
		meta.pair_open,
		meta.pair_close,
		new_pair.open,
		new_pair.close
	))
end

--- Changes a function call name: deletes the name, keeps parens, enters insert mode.
--- @param ctx SmartMotionContext
--- @param cfg SmartMotionConfig
--- @param motion_state SmartMotionMotionState
local function _change_function_name(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local meta = target.metadata
	local bufnr = target.metadata.bufnr
	local winid = target.metadata.winid or 0

	-- open_pos spans "funcname(" — we want to delete just "funcname" (not the paren)
	local open_pos = meta.open_pos
	local name_end_col = open_pos["end"].col - 1 -- exclude the "("

	-- Clear hint labels
	highlight_mod.clear(ctx, cfg, motion_state)

	pcall(vim.cmd, "undojoin")

	-- Delete the function name (keep the paren)
	vim.api.nvim_buf_set_text(
		bufnr,
		open_pos.start.row,
		open_pos.start.col,
		open_pos.start.row,
		name_end_col,
		{ "" }
	)

	-- Position cursor at where the name was and enter insert mode
	vim.api.nvim_win_set_cursor(winid, { open_pos.start.row + 1, open_pos.start.col })
	vim.cmd("startinsert")

	log.debug("surround change function: removed name, entering insert mode")
end

--- Changes an HTML/XML tag name with live sync: as you type in the opening tag,
--- the closing tag mirrors it in real-time (multi-cursor style).
--- @param ctx SmartMotionContext
--- @param cfg SmartMotionConfig
--- @param motion_state SmartMotionMotionState
local function _change_tag_name(ctx, cfg, motion_state)
	local target = motion_state.selected_jump_target
	local meta = target.metadata
	local bufnr = target.metadata.bufnr
	local winid = target.metadata.winid or 0
	local old_name = meta.tag_name

	local open_pos = meta.open_pos
	local close_pos = meta.close_pos

	-- Clear hint labels
	highlight_mod.clear(ctx, cfg, motion_state)

	pcall(vim.cmd, "undojoin")

	local open_row = open_pos.start.row
	local open_name_start = open_pos.start.col + 1 -- after "<"
	local open_name_end = open_name_start + #old_name
	local close_row = close_pos.start.row

	-- Delete close tag name first (preserves open tag positions)
	local close_name_start = close_pos.start.col + 2 -- after "</"
	local close_name_end = close_name_start + #old_name
	vim.api.nvim_buf_set_text(bufnr, close_row, close_name_start, close_row, close_name_end, { "" })

	vim.cmd("undojoin")

	-- Delete open tag name
	vim.api.nvim_buf_set_text(bufnr, open_row, open_name_start, open_row, open_name_end, { "" })

	-- Track what we've synced so far
	local last_synced_name = ""

	--- Find the close tag "</>" name insertion point by scanning the actual line.
	--- Returns the column right after "</" where the name should go.
	local function find_close_name_col()
		local close_line = vim.api.nvim_buf_get_lines(bufnr, close_row, close_row + 1, false)[1]
		if not close_line then
			return nil
		end
		-- Find "</" followed by the current synced name (or empty)
		local pattern = "</" .. vim.pesc(last_synced_name)
		local s = close_line:find(pattern, 1, true)
		if s then
			return s - 1 + 2 -- 0-indexed, after "</"
		end
		return nil
	end

	-- Highlight the close tag
	local init_col = find_close_name_col()
	local close_hl_id = nil
	if init_col then
		close_hl_id = vim.api.nvim_buf_set_extmark(bufnr, consts.ns_id, close_row, init_col, {
			virt_text = { { "|", "SmartMotionSelected" } },
			virt_text_pos = "inline",
		})
	end

	-- Set up live sync: mirror every keystroke to the close tag
	local augroup = vim.api.nvim_create_augroup("SmartMotionTagSync", { clear = true })

	vim.api.nvim_create_autocmd({ "TextChangedI", "TextChangedP" }, {
		group = augroup,
		buffer = bufnr,
		callback = function()
			-- Read current name from opening tag
			local line = vim.api.nvim_buf_get_lines(bufnr, open_row, open_row + 1, false)[1]
			if not line then
				return
			end

			local after_bracket = line:sub(open_name_start + 1)
			local new_name = after_bracket:match("^([%w_%-%.%:]*)") or ""

			if new_name == last_synced_name then
				return
			end

			-- Find where the close tag name currently is
			local col = find_close_name_col()
			if not col then
				return
			end

			local close_current_end = col + #last_synced_name

			pcall(vim.cmd, "undojoin")
			pcall(vim.api.nvim_buf_set_text,
				bufnr, close_row, col, close_row, close_current_end, { new_name })

			last_synced_name = new_name

			-- Update highlight on the close tag name
			if close_hl_id then
				pcall(vim.api.nvim_buf_del_extmark, bufnr, consts.ns_id, close_hl_id)
			end
			local new_col = find_close_name_col()
			if new_col then
				close_hl_id = vim.api.nvim_buf_set_extmark(bufnr, consts.ns_id, close_row, new_col, {
					end_row = close_row,
					end_col = new_col + #new_name,
					hl_group = "SmartMotionSelected",
				})
			end
		end,
	})

	-- Clean up on InsertLeave
	vim.api.nvim_create_autocmd("InsertLeave", {
		group = augroup,
		buffer = bufnr,
		once = true,
		callback = function()
			vim.api.nvim_del_augroup_by_id(augroup)
			pcall(vim.api.nvim_buf_del_extmark, bufnr, consts.ns_id, close_hl_id)
			log.debug(string.format("surround change tag: '%s' → '%s'", old_name, last_synced_name))
		end,
	})

	-- Position cursor and enter insert mode
	vim.api.nvim_win_set_cursor(winid, { open_row + 1, open_name_start })
	vim.cmd("startinsert")
end

--- Dispatching action for surround operations.
--- Checks motion_state.motion.action_key to determine operation.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local action_key = motion_state.motion.action_key
	local meta = motion_state.selected_jump_target and motion_state.selected_jump_target.metadata

	-- Tag special handling
	if meta and meta.tag_name then
		if action_key == "c" then
			_change_tag_name(ctx, cfg, motion_state)
			return
		end
		-- dst falls through to normal _delete_delimiters (removes both tags)
	end

	-- Function call special handling
	if meta and meta.func_name then
		if action_key == "c" then
			_change_function_name(ctx, cfg, motion_state)
			return
		end
		-- dsf falls through to normal _delete_delimiters (removes name+parens)
	end

	if action_key == "d" then
		_delete_delimiters(ctx, motion_state)
	elseif action_key == "y" then
		_yank_delimiters(ctx, motion_state)
	elseif action_key == "c" then
		_change_delimiters(ctx, cfg, motion_state)
	else
		log.debug("surround: unsupported action_key '" .. tostring(action_key) .. "'")
	end
end

return M
