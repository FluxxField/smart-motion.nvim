--- Set mark at target location
--- Standalone action that shows labels on word targets, lets user pick one,
--- then prompts for a mark name (a-z for local, A-Z for global).

local context = require("smart-motion.core.context")
local state = require("smart-motion.core.state")
local hints = require("smart-motion.visualizers.hints")
local selection = require("smart-motion.core.selection")
local log = require("smart-motion.core.log")

local M = {}

--- Run the set mark action
function M.run()
	local cfg = state.get_config()
	local ctx = context.get()
	local motion_state = state.get_motion_state()

	-- Reset motion state for fresh run
	state.reset_motion_state()
	motion_state = state.get_motion_state()
	motion_state.multi_window = true

	-- Collect word targets across visible windows
	local targets = {}
	local pattern = "\\k\\+"

	for _, winid in ipairs(ctx.windows) do
		local bufnr = vim.api.nvim_win_get_buf(winid)
		local win_info = vim.fn.getwininfo(winid)[1]
		local top_line = win_info.topline
		local bot_line = win_info.botline

		local lines = vim.api.nvim_buf_get_lines(bufnr, top_line - 1, bot_line, false)
		for i, line in ipairs(lines) do
			local lnum = top_line + i - 1
			local col = 0
			while true do
				local match_start, match_end = vim.fn.matchstrpos(line, pattern, col)
				if match_start == "" then
					break
				end
				local start_col = match_end[2]
				local end_col = match_end[3]

				table.insert(targets, {
					text = match_start,
					start_pos = { row = lnum - 1, col = start_col },
					end_pos = { row = lnum - 1, col = end_col },
					type = "word",
					metadata = {
						bufnr = bufnr,
						winid = winid,
					},
				})

				col = end_col
			end
		end
	end

	if #targets == 0 then
		log.debug("set_mark: no targets found")
		return
	end

	motion_state.jump_targets = targets
	motion_state.jump_target_count = #targets

	-- Track affected buffers for highlight cleanup
	local affected_buffers = {}
	for _, target in ipairs(targets) do
		affected_buffers[target.metadata.bufnr] = true
	end
	motion_state.affected_buffers = affected_buffers

	-- Show hints and wait for selection
	local ok, err = pcall(function()
		hints.run(ctx, cfg, motion_state)
		selection.wait_for_hint_selection(ctx, cfg, motion_state)
	end)

	-- Cleanup hints
	for bufnr, _ in pairs(affected_buffers) do
		pcall(vim.api.nvim_buf_clear_namespace, bufnr, vim.api.nvim_create_namespace("smart_motion_hints"), 0, -1)
		pcall(vim.api.nvim_buf_clear_namespace, bufnr, vim.api.nvim_create_namespace("smart_motion_dim"), 0, -1)
	end

	if not ok then
		if type(err) == "table" and err.abort then
			return
		end
		log.error("set_mark error: " .. tostring(err))
		return
	end

	local target = motion_state.selected_jump_target
	if not target then
		return
	end

	-- Prompt for mark name
	vim.api.nvim_echo({ { "Mark name (a-z local, A-Z global): ", "Question" } }, false, {})
	local char = vim.fn.getcharstr()

	-- Validate mark name
	if not char:match("^[a-zA-Z]$") then
		vim.api.nvim_echo({ { "Invalid mark name: " .. char, "ErrorMsg" } }, false, {})
		return
	end

	-- Set the mark at target location
	local mark_bufnr = target.metadata.bufnr
	local lnum = target.start_pos.row + 1
	local col = target.start_pos.col

	-- Switch to target buffer/window if needed
	local target_winid = target.metadata.winid
	local current_winid = vim.api.nvim_get_current_win()

	if target_winid and target_winid ~= current_winid then
		vim.api.nvim_set_current_win(target_winid)
	end

	-- Save cursor, set mark, restore cursor
	local saved_cursor = vim.api.nvim_win_get_cursor(0)
	vim.api.nvim_win_set_cursor(0, { lnum, col })
	vim.cmd("normal! m" .. char)
	vim.api.nvim_win_set_cursor(0, saved_cursor)

	-- Switch back to original window
	if target_winid and target_winid ~= current_winid then
		vim.api.nvim_set_current_win(current_winid)
	end

	vim.api.nvim_echo({ { "Mark '" .. char .. "' set at line " .. lnum, "Normal" } }, false, {})
end

return M
