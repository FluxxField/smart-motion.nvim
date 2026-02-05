--- History browser: floating window picker for motion history.
--- Triggered by `g.`: browse all history entries, pick one to jump back to.
--- Supports pins at top, frecency sorting, and action mode (d/y/c).
local consts = require("smart-motion.consts")

local M = {}

--- Formats elapsed seconds into a human-readable string.
---@param seconds number
---@return string
function M._format_time(seconds)
	if seconds < 60 then
		return "just now"
	elseif seconds < 3600 then
		return math.floor(seconds / 60) .. "m ago"
	elseif seconds < 86400 then
		return math.floor(seconds / 3600) .. "h ago"
	else
		return math.floor(seconds / 86400) .. "d ago"
	end
end

--- Returns a frecency bar indicator (1-4 blocks).
---@param score number
---@param max_score number
---@return string
function M._frecency_bar(score, max_score)
	if max_score <= 0 then
		return "█"
	end
	local ratio = score / max_score
	if ratio >= 0.75 then
		return "████"
	elseif ratio >= 0.5 then
		return "███"
	elseif ratio >= 0.25 then
		return "██"
	else
		return "█"
	end
end

--- Finds a window displaying the given buffer.
---@param bufnr integer
---@return integer|nil
function M._find_win_for_buf(bufnr)
	for _, winid in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(winid) == bufnr then
			return winid
		end
	end
	return nil
end

--- Loads a buffer without displaying it, returns bufnr or nil.
---@param filepath string
---@return integer|nil
function M._ensure_buffer(filepath)
	if vim.fn.filereadable(filepath) == 0 then
		return nil
	end

	-- Check existing buffers
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			local name = vim.api.nvim_buf_get_name(bufnr)
			if name == filepath then
				return bufnr
			end
		end
	end

	-- Load without displaying
	local bufnr = vim.fn.bufadd(filepath)
	vim.fn.bufload(bufnr)
	return bufnr
end

--- Navigates to the target from a history entry, reopening closed buffers if needed.
---@param entry table
function M._navigate(entry)
	local target = entry.target
	if not target or not target.start_pos then
		return
	end

	local bufnr = target.metadata and target.metadata.bufnr
	local filepath = entry.filepath

	-- Save current position to jumplist before moving
	vim.cmd("normal! m'")

	-- Try to find or open the target buffer
	if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
		local winid = M._find_win_for_buf(bufnr)
		if winid then
			vim.api.nvim_set_current_win(winid)
		else
			vim.cmd("buffer " .. bufnr)
		end
	elseif filepath and filepath ~= "" then
		vim.cmd("edit " .. vim.fn.fnameescape(filepath))
	else
		vim.notify("Cannot navigate: buffer closed and no filepath recorded", vim.log.levels.WARN)
		return
	end

	-- Move cursor to target position
	local line_count = vim.api.nvim_buf_line_count(0)
	local row = target.start_pos.row + 1
	if row > line_count then
		vim.notify("History target position out of bounds", vim.log.levels.WARN)
		return
	end
	local col = math.max(target.start_pos.col, 0)
	local ok, _ = pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
	if not ok then
		vim.notify("History target position no longer valid", vim.log.levels.WARN)
		return
	end

	-- Open any folds at the target position
	vim.cmd("normal! zv")
end

--- Builds a display line for a pin entry.
---@param label string
---@param pin table
---@return string display_line
---@return integer label_end_col byte offset where the label ends
function M._format_pin(label, pin)
	local target = pin.target or {}
	local text = target.text or ""

	text = text:gsub("\n", " ")
	if #text > 30 then
		text = text:sub(1, 27) .. "..."
	end

	local filepath = pin.filepath or ""
	local filename = vim.fn.fnamemodify(filepath, ":t")
	if filename == "" then
		filename = "[no file]"
	end

	local row = target.start_pos and (target.start_pos.row + 1) or 0

	local label_part = " " .. label .. " "
	local line = string.format(
		"%s *  %-32s %s:%d",
		label_part,
		'"' .. text .. '"',
		filename,
		row
	)

	return line, #label_part
end

--- Builds a display line for a history entry with frecency bar.
---@param label string
---@param entry table
---@param frecency_bar string
---@return string display_line
---@return integer label_end_col byte offset where the label ends
function M._format_entry(label, entry, frecency_bar)
	local motion_key = entry.motion and entry.motion.trigger_key or "?"
	local target = entry.target or {}
	local text = target.text or ""

	text = text:gsub("\n", " ")
	if #text > 30 then
		text = text:sub(1, 27) .. "..."
	end

	local filepath = entry.filepath or ""
	local filename = vim.fn.fnamemodify(filepath, ":t")
	if filename == "" then
		filename = "[no file]"
	end

	local row = target.start_pos and (target.start_pos.row + 1) or 0

	local elapsed = os.time() - (entry.metadata and entry.metadata.time_stamp or os.time())
	local time_str = M._format_time(elapsed)

	local label_part = " " .. label .. " "
	local line = string.format(
		"%s %-4s %-32s %-5s %s:%d  %s",
		label_part,
		motion_key,
		'"' .. text .. '"',
		frecency_bar,
		filename,
		row,
		time_str
	)

	return line, #label_part
end

--- Executes a remote action (yank/delete/change) on a history entry's target.
---@param action_mode string "yank"|"delete"|"change"
---@param entry table
function M._execute_action(action_mode, entry)
	local target = entry.target
	if not target or not target.start_pos then
		vim.notify("Invalid history target", vim.log.levels.WARN)
		return
	end

	local filepath = entry.filepath
	if not filepath or filepath == "" then
		vim.notify("No filepath for history entry", vim.log.levels.WARN)
		return
	end

	local bufnr = M._ensure_buffer(filepath)
	if not bufnr then
		vim.notify("Cannot load file: " .. filepath, vim.log.levels.WARN)
		return
	end

	local line_count = vim.api.nvim_buf_line_count(bufnr)
	local start_row = target.start_pos.row
	local start_col = target.start_pos.col
	local end_row = target.end_pos and target.end_pos.row or start_row
	local end_col = target.end_pos and target.end_pos.col or start_col

	-- Validate bounds
	if start_row >= line_count then
		vim.notify("History target out of bounds", vim.log.levels.WARN)
		return
	end
	if end_row >= line_count then
		end_row = line_count - 1
	end

	-- Check if text still matches
	local ok, current_text
	if target.type == "lines" then
		ok, current_text = pcall(vim.api.nvim_buf_get_lines, bufnr, start_row, end_row + 1, false)
		if ok then
			local joined = table.concat(current_text, "\n")
			if target.text and joined ~= target.text then
				vim.notify("Warning: text at target has changed", vim.log.levels.WARN)
			end
		end
	else
		ok, current_text = pcall(vim.api.nvim_buf_get_text, bufnr, start_row, start_col, end_row, end_col, {})
		if ok then
			local joined = table.concat(current_text, "\n")
			if target.text and joined ~= target.text then
				vim.notify("Warning: text at target has changed", vim.log.levels.WARN)
			end
		end
	end

	if action_mode == "yank" then
		if target.type == "lines" then
			local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
			vim.fn.setreg('"', table.concat(lines, "\n"), "l")
		else
			local text = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
			vim.fn.setreg('"', table.concat(text, "\n"), "c")
		end
		vim.notify("Yanked from history", vim.log.levels.INFO)
	elseif action_mode == "delete" then
		if target.type == "lines" then
			local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
			vim.fn.setreg('"', table.concat(lines, "\n"), "l")
			vim.api.nvim_buf_set_lines(bufnr, start_row, end_row + 1, false, {})
		else
			local text = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
			vim.fn.setreg('"', table.concat(text, "\n"), "c")
			vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, { "" })
		end
		vim.notify("Deleted from history", vim.log.levels.INFO)
	elseif action_mode == "change" then
		M._navigate(entry)
		-- Delete the text at cursor, then enter insert mode
		if target.type == "lines" then
			local lines = vim.api.nvim_buf_get_lines(0, start_row, end_row + 1, false)
			vim.fn.setreg('"', table.concat(lines, "\n"), "l")
			vim.api.nvim_buf_set_lines(0, start_row, end_row + 1, false, { "" })
			vim.api.nvim_win_set_cursor(0, { start_row + 1, 0 })
		else
			local text = vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
			vim.fn.setreg('"', table.concat(text, "\n"), "c")
			vim.api.nvim_buf_set_text(0, start_row, start_col, end_row, end_col, { "" })
			vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
		end
		vim.cmd("startinsert")
	end
end

--- Runs the history browser: show floating window, pick an entry, jump there.
function M.run()
	local history = require("smart-motion.core.history")
	local config = require("smart-motion.config")

	local has_pins = #history.pins > 0
	local has_entries = #history.entries > 0

	if not has_pins and not has_entries then
		vim.notify("No motion history", vim.log.levels.INFO)
		return
	end

	local cfg = config.validated
	if not cfg then
		return
	end

	-- Build available letter keys (excluding d, y, c for action mode)
	local action_keys = { d = true, y = true, c = true }
	local available_keys = {}
	for _, k in ipairs(cfg.keys) do
		if not action_keys[k] then
			table.insert(available_keys, k)
		end
	end

	-- Sort entries by frecency
	local sorted_entries = {}
	for _, entry in ipairs(history.entries) do
		table.insert(sorted_entries, entry)
	end
	table.sort(sorted_entries, function(a, b)
		return history._frecency_score(a) > history._frecency_score(b)
	end)

	-- Compute max frecency score for bar scaling
	local max_score = 0
	for _, entry in ipairs(sorted_entries) do
		local score = history._frecency_score(entry)
		if score > max_score then
			max_score = score
		end
	end

	-- Build pin items with number labels
	local pin_items = {}
	for i, pin in ipairs(history.pins) do
		if i > 9 then
			break
		end
		local label = tostring(i)
		local display, label_end_col = M._format_pin(label, pin)
		table.insert(pin_items, {
			label = label,
			display = display,
			label_end_col = label_end_col,
			entry = pin,
		})
	end

	-- Build entry items with letter labels
	local entry_items = {}
	for i, entry in ipairs(sorted_entries) do
		if i > #available_keys then
			break
		end
		local label = available_keys[i]
		local score = history._frecency_score(entry)
		local bar = M._frecency_bar(score, max_score)
		local display, label_end_col = M._format_entry(label, entry, bar)
		table.insert(entry_items, {
			label = label,
			display = display,
			label_end_col = label_end_col,
			entry = entry,
		})
	end

	-- Build display lines
	local lines = {}
	local max_width = 0
	local all_items = {} -- combined for label lookup

	for _, item in ipairs(pin_items) do
		table.insert(lines, item.display)
		table.insert(all_items, item)
		if #item.display > max_width then
			max_width = #item.display
		end
	end

	-- Separator line if both sections exist
	local separator_line_idx = nil
	if has_pins and has_entries and #entry_items > 0 then
		local sep = string.rep("─", max_width > 0 and max_width or 40)
		table.insert(lines, sep)
		separator_line_idx = #lines
		if #sep > max_width then
			max_width = #sep
		end
	end

	for _, item in ipairs(entry_items) do
		table.insert(lines, item.display)
		table.insert(all_items, item)
		if #item.display > max_width then
			max_width = #item.display
		end
	end

	local width = max_width + 2
	local height = #lines

	-- Create scratch buffer for the floating window
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	vim.bo[buf].bufhidden = "wipe"

	-- Apply label highlights
	local ns = consts.ns_id
	local line_idx = 0
	for _, item in ipairs(pin_items) do
		vim.api.nvim_buf_add_highlight(buf, ns, "SmartMotionHint", line_idx, 1, item.label_end_col)
		line_idx = line_idx + 1
	end
	if separator_line_idx then
		line_idx = line_idx + 1 -- skip separator
	end
	for _, item in ipairs(entry_items) do
		vim.api.nvim_buf_add_highlight(buf, ns, "SmartMotionHint", line_idx, 1, item.label_end_col)
		line_idx = line_idx + 1
	end

	-- Open centered floating window
	local win = vim.api.nvim_open_win(buf, false, {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = " Motion History ",
		title_pos = "center",
	})

	vim.cmd("redraw")

	-- Two-phase input loop
	local ok, char = pcall(vim.fn.getcharstr)
	if not ok or char == "\27" then
		pcall(vim.api.nvim_win_close, win, true)
		pcall(vim.api.nvim_buf_delete, buf, { force = true })
		vim.cmd("redraw")
		return
	end

	-- Check for action mode (d/y/c)
	local action_map = { d = "delete", y = "yank", c = "change" }
	if action_map[char] then
		local action_mode = action_map[char]
		local mode_label = char:upper()

		-- Update floating window title to show action mode
		vim.bo[buf].modifiable = true
		vim.bo[buf].modifiable = false
		pcall(vim.api.nvim_win_set_config, win, {
			title = " Motion History [" .. mode_label .. "] ",
			title_pos = "center",
		})
		vim.cmd("redraw")

		-- Wait for label selection
		local ok2, label_char = pcall(vim.fn.getcharstr)

		-- Close the floating window
		pcall(vim.api.nvim_win_close, win, true)
		pcall(vim.api.nvim_buf_delete, buf, { force = true })
		vim.cmd("redraw")

		if not ok2 or label_char == "\27" then
			return
		end

		-- Find matching entry (check both pin and regular labels)
		local selected = nil
		for _, item in ipairs(all_items) do
			if label_char:lower() == item.label:lower() then
				selected = item.entry
				break
			end
		end

		if not selected then
			return
		end

		M._execute_action(action_mode, selected)
		return
	end

	-- Close the floating window for navigation
	pcall(vim.api.nvim_win_close, win, true)
	pcall(vim.api.nvim_buf_delete, buf, { force = true })
	vim.cmd("redraw")

	-- Find matching entry (check both pin and regular labels, case-insensitive)
	local selected = nil
	for _, item in ipairs(all_items) do
		if char:lower() == item.label:lower() then
			selected = item.entry
			break
		end
	end

	if not selected then
		return
	end

	M._navigate(selected)
end

return M
