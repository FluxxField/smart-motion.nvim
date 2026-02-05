--- History browser: floating window picker for motion history.
--- Triggered by `g.`: browse all history entries, pick one to jump back to.
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
	local row = target.start_pos.row + 1
	local col = math.max(target.start_pos.col, 0)
	local ok, err = pcall(vim.api.nvim_win_set_cursor, 0, { row, col })
	if not ok then
		vim.notify("History target position no longer valid", vim.log.levels.WARN)
		return
	end

	-- Open any folds at the target position
	vim.cmd("normal! zv")
end

--- Builds a display line for a history entry.
---@param label string
---@param entry table
---@return string display_line
---@return integer label_end_col byte offset where the label ends (for highlighting)
function M._format_entry(label, entry)
	local motion_key = entry.motion and entry.motion.trigger_key or "?"
	local target = entry.target or {}
	local text = target.text or ""

	-- Truncate long text and strip newlines
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
		"%s %-4s %-32s %s:%d  %s",
		label_part,
		motion_key,
		'"' .. text .. '"',
		filename,
		row,
		time_str
	)

	return line, #label_part
end

--- Runs the history browser: show floating window, pick an entry, jump there.
function M.run()
	local history = require("smart-motion.core.history")
	local config = require("smart-motion.config")

	if #history.entries == 0 then
		vim.notify("No motion history", vim.log.levels.INFO)
		return
	end

	local cfg = config.validated
	if not cfg then
		return
	end

	local keys = cfg.keys

	-- Build entries with labels
	local entries = {}
	for i, entry in ipairs(history.entries) do
		if i > #keys then
			break
		end

		local label = keys[i]
		local display, label_end_col = M._format_entry(label, entry)

		table.insert(entries, {
			label = label,
			display = display,
			label_end_col = label_end_col,
			entry = entry,
		})
	end

	-- Build display lines and measure width
	local lines = {}
	local max_width = 0
	for _, e in ipairs(entries) do
		table.insert(lines, e.display)
		if #e.display > max_width then
			max_width = #e.display
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
	for i, e in ipairs(entries) do
		vim.api.nvim_buf_add_highlight(buf, ns, "SmartMotionHint", i - 1, 1, e.label_end_col)
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

	-- Wait for user keypress
	local ok, char = pcall(vim.fn.getcharstr)

	-- Close the floating window
	pcall(vim.api.nvim_win_close, win, true)
	pcall(vim.api.nvim_buf_delete, buf, { force = true })
	vim.cmd("redraw")

	if not ok then
		return
	end

	-- Find matching entry (case-insensitive)
	local selected = nil
	for _, e in ipairs(entries) do
		if char:lower() == e.label:lower() then
			selected = e.entry
			break
		end
	end

	if not selected then
		return
	end

	M._navigate(selected)
end

return M
