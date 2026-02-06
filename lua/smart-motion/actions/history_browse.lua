--- History browser: floating window picker for motion history.
--- Triggered by `g.`: browse all history entries, pick one to jump back to.
--- Uses nui.nvim for proper split layout if available, falls back to simple popup.
local consts = require("smart-motion.consts")

local M = {}

-- Reserved keys that can't be used as labels
M._reserved_keys = { j = true, k = true, d = true, y = true, c = true }

-- Check if nui.nvim is available
local has_nui, _ = pcall(require, "nui.popup")

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

	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			local name = vim.api.nvim_buf_get_name(bufnr)
			if name == filepath then
				return bufnr
			end
		end
	end

	local bufnr = vim.fn.bufadd(filepath)
	vim.fn.bufload(bufnr)
	return bufnr
end

--- Navigates to the target from a history entry.
---@param entry table
function M._navigate(entry)
	local target = entry.target
	if not target or not target.start_pos then
		return
	end

	local bufnr = target.metadata and target.metadata.bufnr
	local filepath = entry.filepath

	vim.cmd("normal! m'")

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

	local line_count = vim.api.nvim_buf_line_count(0)
	local row = target.start_pos.row + 1
	if row > line_count then
		vim.notify("History target position out of bounds", vim.log.levels.WARN)
		return
	end
	local col = math.max(target.start_pos.col, 0)
	pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
	vim.cmd("normal! zv")
end

--- Executes a remote action on a history entry's target.
---@param action_mode string
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

	if start_row >= line_count then
		vim.notify("History target out of bounds", vim.log.levels.WARN)
		return
	end
	if end_row >= line_count then
		end_row = line_count - 1
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

--- Gets preview lines for an entry.
---@param entry table
---@param num_lines number
---@return string[] lines
---@return number highlight_line
function M._get_preview_lines(entry, num_lines)
	local filepath = entry.filepath
	if not filepath or filepath == "" then
		local lines = {}
		for i = 1, num_lines do
			if i == math.floor(num_lines / 2) then
				table.insert(lines, "  [no file]")
			else
				table.insert(lines, "")
			end
		end
		return lines, math.floor(num_lines / 2) - 1
	end

	local bufnr = M._ensure_buffer(filepath)
	if not bufnr then
		local lines = {}
		for i = 1, num_lines do
			if i == math.floor(num_lines / 2) then
				table.insert(lines, "  [file not found]")
			else
				table.insert(lines, "")
			end
		end
		return lines, math.floor(num_lines / 2) - 1
	end

	local target = entry.target
	if not target or not target.start_pos then
		local lines = {}
		for i = 1, num_lines do table.insert(lines, "") end
		return lines, 0
	end

	local target_row = target.start_pos.row
	local line_count = vim.api.nvim_buf_line_count(bufnr)
	local context = math.floor(num_lines / 2)

	local start_line = math.max(0, target_row - context)
	local end_line = math.min(line_count, target_row + context + 1)

	local ok, raw_lines = pcall(vim.api.nvim_buf_get_lines, bufnr, start_line, end_line, false)
	if not ok or #raw_lines == 0 then
		local lines = {}
		for i = 1, num_lines do table.insert(lines, "") end
		return lines, 0
	end

	local result = {}
	for i, line in ipairs(raw_lines) do
		local lnum = start_line + i
		local prefix = string.format("%4d  ", lnum)
		table.insert(result, prefix .. line)
	end

	while #result < num_lines do
		table.insert(result, "")
	end

	local highlight_line = target_row - start_line
	return result, highlight_line
end

--- Simple fuzzy match.
---@param needle string
---@param haystack string
---@return boolean
function M._fuzzy_match(needle, haystack)
	if needle == "" then return true end
	needle = needle:lower()
	haystack = haystack:lower()
	local ni = 1
	for hi = 1, #haystack do
		if haystack:sub(hi, hi) == needle:sub(ni, ni) then
			ni = ni + 1
			if ni > #needle then return true end
		end
	end
	return false
end

--- Gets searchable text for filtering.
---@param entry table
---@return string
function M._get_searchable_text(entry)
	local parts = {}
	if entry.target and entry.target.text then
		table.insert(parts, entry.target.text)
	end
	if entry.filepath then
		table.insert(parts, vim.fn.fnamemodify(entry.filepath, ":t"))
	end
	if entry.motion and entry.motion.trigger_key then
		table.insert(parts, entry.motion.trigger_key)
	end
	return table.concat(parts, " ")
end

--- Formats a pin entry for display.
---@param label string
---@param pin table
---@return string
function M._format_pin(label, pin)
	local target = pin.target or {}
	local text = target.text or ""
	text = text:gsub("\n", " ")
	if #text > 25 then
		text = text:sub(1, 22) .. "..."
	end

	local filepath = pin.filepath or ""
	local filename = vim.fn.fnamemodify(filepath, ":t")
	if filename == "" then filename = "[no file]" end

	local row = target.start_pos and (target.start_pos.row + 1) or 0

	return string.format(' %s  * %-27s %s:%d', label, '"' .. text .. '"', filename, row)
end

--- Formats a history entry for display.
---@param label string
---@param entry table
---@param frecency_bar string
---@return string
function M._format_entry(label, entry, frecency_bar)
	local motion_key = entry.motion and entry.motion.trigger_key or "?"
	local target = entry.target or {}
	local text = target.text or ""
	text = text:gsub("\n", " ")
	if #text > 20 then
		text = text:sub(1, 17) .. "..."
	end

	local filepath = entry.filepath or ""
	local filename = vim.fn.fnamemodify(filepath, ":t")
	if filename == "" then filename = "[no file]" end

	local row = target.start_pos and (target.start_pos.row + 1) or 0
	local elapsed = os.time() - (entry.metadata and entry.metadata.time_stamp or os.time())
	local time_str = M._format_time(elapsed)

	return string.format(' %s  %-3s %-22s %s %s:%d  %s',
		label, motion_key, '"' .. text .. '"', frecency_bar, filename, row, time_str)
end

--- Runs the history browser with nui.nvim layout.
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
	if not cfg then return end

	-- Check for nui.nvim
	local ok_popup, Popup = pcall(require, "nui.popup")
	local ok_layout, Layout = pcall(require, "nui.layout")

	if not ok_popup or not ok_layout then
		vim.notify("nui.nvim required for history browser. Install with your package manager.", vim.log.levels.WARN)
		return
	end

	local available_keys = {}
	for _, k in ipairs(cfg.keys) do
		if not M._reserved_keys[k] then
			table.insert(available_keys, k)
		end
	end

	local sorted_entries = {}
	for _, entry in ipairs(history.entries) do
		table.insert(sorted_entries, entry)
	end
	table.sort(sorted_entries, function(a, b)
		return history._frecency_score(a) > history._frecency_score(b)
	end)

	local max_score = 0
	for _, entry in ipairs(sorted_entries) do
		local score = history._frecency_score(entry)
		if score > max_score then max_score = score end
	end

	-- Layout dimensions
	local total_width = math.min(140, vim.o.columns - 10)
	local total_height = math.min(22, vim.o.lines - 6)
	local preview_width = math.floor(total_width * 0.45)
	local list_width = total_width - preview_width

	-- State
	local cursor_pos = 1
	local search_text = ""
	local mode = "normal"
	local action_key = nil

	-- Build items
	local function build_items()
		local pin_items = {}
		local entry_items = {}

		local pin_idx = 1
		for _, pin in ipairs(history.pins) do
			if pin_idx > 9 then break end
			if M._fuzzy_match(search_text, M._get_searchable_text(pin)) then
				local label = tostring(pin_idx)
				table.insert(pin_items, {
					label = label,
					display = M._format_pin(label, pin),
					entry = pin,
				})
				pin_idx = pin_idx + 1
			end
		end

		local entry_idx = 1
		for _, entry in ipairs(sorted_entries) do
			if entry_idx > #available_keys then break end
			if M._fuzzy_match(search_text, M._get_searchable_text(entry)) then
				local label = available_keys[entry_idx]
				local score = history._frecency_score(entry)
				local bar = M._frecency_bar(score, max_score)
				table.insert(entry_items, {
					label = label,
					display = M._format_entry(label, entry, bar),
					entry = entry,
				})
				entry_idx = entry_idx + 1
			end
		end

		return pin_items, entry_items
	end

	-- Initial build
	local pin_items, entry_items = build_items()
	local all_items = {}
	for _, item in ipairs(pin_items) do table.insert(all_items, item) end
	for _, item in ipairs(entry_items) do table.insert(all_items, item) end

	if #all_items == 0 then
		vim.notify("No matching history entries", vim.log.levels.INFO)
		return
	end

	-- Create popups
	local header_popup = Popup({
		border = {
			style = "rounded",
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
		},
	})

	local preview_popup = Popup({
		border = {
			style = "rounded",
			text = {
				top = " Preview ",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
			cursorline = false,
		},
	})

	local list_popup = Popup({
		enter = true,
		border = {
			style = "rounded",
			text = {
				top = " History ",
				top_align = "center",
			},
		},
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
			cursorline = true,
		},
	})

	local hint_popup = Popup({
		border = {
			style = "rounded",
		},
		win_options = {
			winhighlight = "Normal:Comment,FloatBorder:FloatBorder",
		},
	})

	-- Create layout
	local layout = Layout(
		{
			relative = "editor",
			position = "50%",
			size = {
				width = total_width,
				height = total_height,
			},
		},
		Layout.Box({
			Layout.Box(header_popup, { size = 3 }),
			Layout.Box({
				Layout.Box(preview_popup, { size = preview_width }),
				Layout.Box(list_popup, { grow = 1 }),
			}, { dir = "row", grow = 1 }),
			Layout.Box(hint_popup, { size = 3 }),
		}, { dir = "col" })
	)

	-- Update header content
	local function update_header()
		local title
		if mode == "search" then
			title = "  Motion History    Search: " .. search_text .. "█"
		elseif mode == "action" then
			title = "  Motion History [" .. (action_key or "?"):upper() .. "]"
		else
			title = "  Motion History"
		end
		vim.api.nvim_buf_set_lines(header_popup.bufnr, 0, -1, false, { title })

		-- Highlight the title
		vim.api.nvim_buf_clear_namespace(header_popup.bufnr, consts.ns_id, 0, -1)
		vim.api.nvim_buf_add_highlight(header_popup.bufnr, consts.ns_id, "Title", 0, 0, 17) -- "  Motion History"
		if mode == "search" then
			vim.api.nvim_buf_add_highlight(header_popup.bufnr, consts.ns_id, "Search", 0, 22, -1)
		elseif mode == "action" then
			vim.api.nvim_buf_add_highlight(header_popup.bufnr, consts.ns_id, "WarningMsg", 0, 17, -1)
		end
	end

	-- Update preview content
	local function update_preview()
		local current_entry = all_items[cursor_pos] and all_items[cursor_pos].entry or nil
		local preview_height = total_height - 5

		local lines, highlight_line
		if current_entry then
			lines, highlight_line = M._get_preview_lines(current_entry, preview_height)
		else
			lines = {}
			for i = 1, preview_height do table.insert(lines, "") end
			highlight_line = -1
		end

		vim.api.nvim_buf_set_lines(preview_popup.bufnr, 0, -1, false, lines)

		-- Apply filetype for syntax
		if current_entry and current_entry.filepath then
			local ft = vim.filetype.match({ filename = current_entry.filepath })
			if ft then
				pcall(function() vim.bo[preview_popup.bufnr].filetype = ft end)
			end
		end

		-- Highlight target line
		vim.api.nvim_buf_clear_namespace(preview_popup.bufnr, consts.ns_id, 0, -1)
		if highlight_line >= 0 and highlight_line < #lines then
			vim.api.nvim_buf_add_highlight(preview_popup.bufnr, consts.ns_id, "Visual", highlight_line, 0, -1)
		end
	end

	-- Update list content
	local function update_list()
		local lines = {}
		local separator_indices = {}

		for _, item in ipairs(pin_items) do
			table.insert(lines, item.display)
		end

		if #pin_items > 0 and #entry_items > 0 then
			table.insert(lines, string.rep("─", list_width - 4))
			table.insert(separator_indices, #lines)
		end

		for _, item in ipairs(entry_items) do
			table.insert(lines, item.display)
		end

		vim.api.nvim_buf_set_lines(list_popup.bufnr, 0, -1, false, lines)

		-- Apply highlights
		vim.api.nvim_buf_clear_namespace(list_popup.bufnr, consts.ns_id, 0, -1)

		local line_idx = 0
		local item_idx = 0
		for i, line_text in ipairs(lines) do
			local is_separator = false
			for _, sep_idx in ipairs(separator_indices) do
				if i == sep_idx then is_separator = true break end
			end

			if not is_separator then
				item_idx = item_idx + 1
				-- Label highlight (first 3 chars after space)
				vim.api.nvim_buf_add_highlight(list_popup.bufnr, consts.ns_id, "SmartMotionHint", i - 1, 1, 3)
			end
		end

		-- Set cursor position (accounting for separator)
		local cursor_line = cursor_pos
		if #pin_items > 0 and #entry_items > 0 and cursor_pos > #pin_items then
			cursor_line = cursor_pos + 1 -- +1 for separator
		end
		pcall(vim.api.nvim_win_set_cursor, list_popup.winid, { cursor_line, 0 })
	end

	-- Update hint bar
	local function update_hint()
		local hint
		if mode == "action" then
			hint = " [" .. (action_key or "?"):upper() .. "] press label to " ..
				(action_key == "d" and "delete" or action_key == "y" and "yank" or "change") ..
				"   Esc cancel"
		elseif mode == "search" then
			hint = " /" .. search_text .. "█   Backspace clear   Enter done   Esc cancel"
		else
			hint = " j/k navigate   / search   d/y/c action   Enter select   Esc cancel"
		end

		vim.api.nvim_buf_set_lines(hint_popup.bufnr, 0, -1, false, { hint })
	end

	-- Refresh all
	local function refresh()
		pin_items, entry_items = build_items()
		all_items = {}
		for _, item in ipairs(pin_items) do table.insert(all_items, item) end
		for _, item in ipairs(entry_items) do table.insert(all_items, item) end

		if cursor_pos > #all_items then
			cursor_pos = math.max(1, #all_items)
		end

		update_header()
		update_preview()
		update_list()
		update_hint()
	end

	-- Mount layout
	layout:mount()
	refresh()

	-- Cleanup
	local function cleanup()
		layout:unmount()
	end

	-- Input loop
	while true do
		vim.cmd("redraw")
		local ok, char = pcall(vim.fn.getcharstr)
		if not ok then
			cleanup()
			return
		end

		if char == "\27" then -- ESC
			if mode == "search" then
				mode = "normal"
				search_text = ""
				refresh()
			elseif mode == "action" then
				mode = "normal"
				action_key = nil
				refresh()
			else
				cleanup()
				return
			end

		elseif char == "\r" or char == "\n" then -- Enter
			if mode == "search" then
				mode = "normal"
				refresh()
			elseif #all_items > 0 and cursor_pos >= 1 and cursor_pos <= #all_items then
				local selected = all_items[cursor_pos].entry
				cleanup()
				M._navigate(selected)
				return
			end

		elseif char == "j" and mode == "normal" then
			if cursor_pos < #all_items then
				cursor_pos = cursor_pos + 1
				refresh()
			end

		elseif char == "k" and mode == "normal" then
			if cursor_pos > 1 then
				cursor_pos = cursor_pos - 1
				refresh()
			end

		elseif char == "/" and mode == "normal" then
			mode = "search"
			search_text = ""
			refresh()

		elseif (char == "d" or char == "y" or char == "c") and mode == "normal" then
			mode = "action"
			action_key = char
			refresh()

		elseif (char == "\b" or char == "\127") and mode == "search" then
			if #search_text > 0 then
				search_text = search_text:sub(1, -2)
				refresh()
			end

		elseif mode == "search" and char:match("^[%w%s%p]$") then
			search_text = search_text .. char
			refresh()

		else
			-- Label selection
			local selected = nil
			for _, item in ipairs(all_items) do
				if char:lower() == item.label:lower() then
					selected = item
					break
				end
			end

			if selected then
				if mode == "action" then
					cleanup()
					M._execute_action(action_key == "d" and "delete" or action_key == "y" and "yank" or "change", selected.entry)
					return
				else
					cleanup()
					M._navigate(selected.entry)
					return
				end
			end
		end
	end
end

return M
