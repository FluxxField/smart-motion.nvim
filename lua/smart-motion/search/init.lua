--- Native search enhancement: shows SmartMotion labels on visible matches during `/` or `?`.
--- Labels update incrementally as the user types, then wait for selection after Enter.
local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local M = {}

M._active = false
M._enabled = true -- global toggle, flipped by <C-s>
M._augroup = nil
M._cfg = nil
M._pattern = nil -- current cmdline pattern for incremental preview
M._motion_state = nil -- stored motion state for incremental labels
M._ctx = nil -- stored context for incremental labels

--- Sets up autocmds and keymaps for native search label overlay.
---@param cfg SmartMotionConfig
function M.setup(cfg)
	M._cfg = cfg
	M._enabled = true
	M._augroup = vim.api.nvim_create_augroup("SmartMotionSearch", { clear = true })

	vim.api.nvim_create_autocmd("CmdlineEnter", {
		group = M._augroup,
		callback = function()
			local cmd_type = vim.fn.getcmdtype()
			if cmd_type ~= "/" and cmd_type ~= "?" then
				return
			end

			-- Don't activate in operator-pending mode (d/foo should work natively)
			if vim.fn.mode(true):find("o") then
				return
			end

			if not M._enabled then
				return
			end

			M._active = true
			M._pattern = nil
		end,
	})

	vim.api.nvim_create_autocmd("CmdlineChanged", {
		group = M._augroup,
		callback = function()
			if not M._active then
				return
			end

			local pattern = vim.fn.getcmdline()
			M._pattern = pattern
			M._render_preview(pattern)
		end,
	})

	vim.api.nvim_create_autocmd("CmdlineLeave", {
		group = M._augroup,
		callback = function()
			if not M._active then
				return
			end

			M._active = false

			-- If search was aborted (ESC), clean up and return
			if vim.v.event.abort then
				M._clear_preview()
				M._motion_state = nil
				M._ctx = nil
				return
			end

			local cmd_type = vim.fn.getcmdtype()
			if cmd_type ~= "/" and cmd_type ~= "?" then
				M._clear_preview()
				M._motion_state = nil
				M._ctx = nil
				return
			end

			local pattern = vim.fn.getcmdline()
			if not pattern or pattern == "" then
				M._clear_preview()
				M._motion_state = nil
				M._ctx = nil
				return
			end

			-- Schedule to run after cmdline fully closes
			-- Labels are still visible from incremental preview
			vim.schedule(function()
				M._show_labels(pattern)
			end)
		end,
	})

	-- <C-s> toggle in cmdline mode
	vim.keymap.set("c", "<C-s>", function()
		local cmd_type = vim.fn.getcmdtype()
		if cmd_type ~= "/" and cmd_type ~= "?" then
			return
		end

		if M._active then
			-- Deactivate: clear preview labels
			M._active = false
			M._clear_preview()
		else
			-- Don't reactivate in operator-pending mode
			if vim.fn.mode(true):find("o") then
				return
			end
			M._active = true
			-- Re-render with current pattern
			local pattern = vim.fn.getcmdline()
			if pattern and pattern ~= "" then
				M._render_preview(pattern)
			end
		end
	end, { desc = "Toggle SmartMotion search labels" })
end

--- Clears all preview extmarks from all visible buffers.
function M._clear_preview()
	local highlight_mod = require("smart-motion.core.highlight")

	if M._motion_state and M._ctx then
		highlight_mod.clear(M._ctx, M._cfg, M._motion_state)
	else
		-- Fallback: clear namespace directly
		for _, wid in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
			local win_config = vim.api.nvim_win_get_config(wid)
			if win_config.relative == "" then
				local bufnr = vim.api.nvim_win_get_buf(wid)
				if vim.api.nvim_buf_is_valid(bufnr) then
					vim.api.nvim_buf_clear_namespace(bufnr, consts.ns_id, 0, -1)
				end
			end
		end
	end
	vim.cmd("redraw")
end

--- Renders incremental labels while user is typing in cmdline.
---@param pattern string|nil
function M._render_preview(pattern)
	M._clear_preview()
	M._motion_state = nil
	M._ctx = nil

	if not pattern or pattern == "" then
		return
	end

	local context = require("smart-motion.core.context")
	local state = require("smart-motion.core.state")
	local hints = require("smart-motion.visualizers.hints")

	local ctx = context.get()
	local targets = M._find_matches(pattern, ctx)

	if #targets == 0 then
		return
	end

	local motion_state = state.create_motion_state()
	motion_state.multi_window = true
	motion_state.jump_targets = targets
	motion_state.jump_target_count = #targets
	motion_state.is_searching_mode = true
	motion_state.search_text = pattern
	state.finalize_motion_state(ctx, M._cfg, motion_state)

	-- Store for cleanup and reuse in _show_labels
	M._motion_state = motion_state
	M._ctx = ctx

	-- Render labels
	hints.run(ctx, M._cfg, motion_state)
end

--- Finds all matches of the search pattern in visible lines across all windows.
---@param pattern string Vim regex pattern
---@param ctx table context with windows list
---@return table[] targets
function M._find_matches(pattern, ctx)
	local targets = {}

	for _, win in ipairs(ctx.windows) do
		local winid = win.winid
		local bufnr = win.bufnr

		if not vim.api.nvim_buf_is_valid(bufnr) then
			goto continue
		end

		local top_line = vim.fn.line("w0", winid) - 1 -- 0-indexed
		local bottom_line = vim.fn.line("w$", winid) - 1

		local lines = vim.api.nvim_buf_get_lines(bufnr, top_line, bottom_line + 1, false)

		for i, line_text in ipairs(lines) do
			local line_number = top_line + i - 1
			local col = 0

			while true do
				local ok, match_data = pcall(vim.fn.matchstrpos, line_text, pattern, col)
				if not ok then
					break
				end

				local match, start_col, end_col = match_data[1], match_data[2], match_data[3]
				if start_col == -1 then
					break
				end

				table.insert(targets, {
					text = match,
					start_pos = { row = line_number, col = start_col },
					end_pos = { row = line_number, col = end_col },
					type = "search",
					metadata = { bufnr = bufnr, winid = winid },
				})

				col = end_col + 1
			end
		end

		::continue::
	end

	return targets
end

--- Shows labels on all matches and waits for selection (runs after cmdline closes).
---@param pattern string
function M._show_labels(pattern)
	local context = require("smart-motion.core.context")
	local state = require("smart-motion.core.state")
	local highlight_mod = require("smart-motion.core.highlight")
	local hints = require("smart-motion.visualizers.hints")
	local selection = require("smart-motion.core.selection")
	local jump = require("smart-motion.actions.jump")
	local cfg = M._cfg

	-- Reuse stored state from incremental preview if available and pattern matches
	local ctx = M._ctx
	local motion_state = M._motion_state

	if not ctx or not motion_state or M._pattern ~= pattern then
		-- Recreate if state is stale or pattern changed
		ctx = context.get()
		motion_state = state.create_motion_state()
		motion_state.multi_window = true

		local targets = M._find_matches(pattern, ctx)
		if #targets == 0 then
			M._ctx = nil
			M._motion_state = nil
			return
		end

		motion_state.jump_targets = targets
		motion_state.jump_target_count = #targets
		state.finalize_motion_state(ctx, cfg, motion_state)

		-- Render labels (only if we recreated state)
		hints.run(ctx, cfg, motion_state)
	end

	-- Clear stored state
	M._ctx = nil
	M._motion_state = nil

	if not motion_state.jump_targets or #motion_state.jump_targets == 0 then
		return
	end

	-- Wait for label selection
	selection.wait_for_hint_selection(ctx, cfg, motion_state)

	-- Clean up highlights
	highlight_mod.clear(ctx, cfg, motion_state)
	vim.cmd("redraw")

	-- Jump if target selected
	if motion_state.selected_jump_target then
		jump.run(ctx, cfg, motion_state)
	end
end

return M
