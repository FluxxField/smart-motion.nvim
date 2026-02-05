--- Treesitter Search: search for text, select the surrounding treesitter node.
--- In operator-pending mode, the operator applies to the full node range.
--- In visual mode, selects the node. In normal mode, enters visual mode with node selected.
local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local M = {}

--- Gets the smallest named treesitter node containing a position.
---@param bufnr integer
---@param row integer 0-indexed
---@param col integer 0-indexed
---@return TSNode|nil
local function get_node_at_pos(bufnr, row, col)
	local ok, node = pcall(vim.treesitter.get_node, {
		bufnr = bufnr,
		pos = { row, col },
	})
	if not ok or not node then
		return nil
	end
	-- Get the smallest named node
	while node and not node:named() do
		node = node:parent()
	end
	return node
end

--- Finds all text matches in visible lines.
---@param pattern string
---@param bufnr integer
---@param top_line integer 0-indexed
---@param bottom_line integer 0-indexed
---@return table[] matches with {row, col, end_col, text}
local function find_matches(pattern, bufnr, top_line, bottom_line)
	local matches = {}
	local lines = vim.api.nvim_buf_get_lines(bufnr, top_line, bottom_line + 1, false)

	for i, line_text in ipairs(lines) do
		local line_number = top_line + i - 1
		local col = 0

		while true do
			local ok, match_data = pcall(vim.fn.matchstrpos, line_text, "\\V" .. vim.fn.escape(pattern, "\\"), col)
			if not ok then
				break
			end

			local match, start_col, end_col = match_data[1], match_data[2], match_data[3]
			if start_col == -1 then
				break
			end

			table.insert(matches, {
				row = line_number,
				col = start_col,
				end_col = end_col,
				text = match,
			})

			col = end_col + 1
		end
	end

	return matches
end

--- Root-level node types to exclude (too broad — covers the whole file).
local ROOT_NODE_TYPES = {
	source_file = true,
	program = true,
	module = true,
	chunk = true,
	translation_unit = true,
	source = true,
	stylesheet = true,
	document = true,
}

--- Converts text matches to treesitter node targets (deduped by range).
--- Returns the smallest named node at each match position.
---@param matches table[]
---@param bufnr integer
---@return table[] targets
local function matches_to_node_targets(matches, bufnr)
	local targets = {}
	local seen_ranges = {}
	local winid = vim.api.nvim_get_current_win()

	for _, match in ipairs(matches) do
		local node = get_node_at_pos(bufnr, match.row, match.col)
		if node then
			local sr, sc, er, ec = node:range()
			local range_key = string.format("%d:%d-%d:%d", sr, sc, er, ec)

			if not seen_ranges[range_key] then
				seen_ranges[range_key] = true
				table.insert(targets, {
					text = vim.treesitter.get_node_text(node, bufnr),
					start_pos = { row = sr, col = sc },
					end_pos = { row = er, col = ec },
					type = "treesitter",
					metadata = {
						bufnr = bufnr,
						winid = winid,
						node_type = node:type(),
						match_row = match.row,
						match_col = match.col,
					},
				})
			end
		end
	end

	return targets
end

--- From a selected target position, walks up the treesitter tree and
--- collects all named ancestor nodes as targets (deduped, excluding root).
---@param bufnr integer
---@param row integer 0-indexed
---@param col integer 0-indexed
---@return table[] targets
local function collect_ancestor_targets(bufnr, row, col)
	local targets = {}
	local seen_ranges = {}
	local winid = vim.api.nvim_get_current_win()

	local node = get_node_at_pos(bufnr, row, col)
	if not node then
		return targets
	end

	-- Start from the parent of the smallest node (the smallest node was already selected)
	node = node:parent()
	while node and not node:named() do
		node = node:parent()
	end

	while node do
		if ROOT_NODE_TYPES[node:type()] then
			break
		end

		local sr, sc, er, ec = node:range()
		local range_key = string.format("%d:%d-%d:%d", sr, sc, er, ec)

		if not seen_ranges[range_key] then
			seen_ranges[range_key] = true
			table.insert(targets, {
				text = vim.treesitter.get_node_text(node, bufnr),
				start_pos = { row = sr, col = sc },
				end_pos = { row = er, col = ec },
				type = "treesitter",
				metadata = {
					bufnr = bufnr,
					winid = winid,
					node_type = node:type(),
				},
			})
		end

		node = node:parent()
		while node and not node:named() do
			node = node:parent()
		end
	end

	return targets
end

--- Runs the treesitter search motion.
---@param mode string|nil Override mode (for testing, or captured from op-pending context)
---@param operator string|nil Saved operator from op-pending context (e.g. "d", "y", "c")
function M.run(mode, operator)
	local context = require("smart-motion.core.context")
	local state = require("smart-motion.core.state")
	local highlight = require("smart-motion.core.highlight")
	local hints = require("smart-motion.visualizers.hints")
	local selection = require("smart-motion.core.selection")
	local flow_state = require("smart-motion.core.flow_state")
	local cfg_mod = require("smart-motion.config")

	-- Reset flow state so it doesn't interfere with our two-phase selection.
	-- The y/d/c handler's evaluate_flow_at_motion_start refreshes the timestamp,
	-- which would cause evaluate_flow_at_selection to skip phase 2.
	flow_state.reset()

	local cfg = cfg_mod.validated
	if not cfg then
		return
	end

	local ctx = context.get()
	local bufnr = ctx.bufnr
	local winid = ctx.winid
	local captured_mode = mode or vim.fn.mode(true)
	local is_operator_pending = captured_mode:find("o") ~= nil
	local is_visual = captured_mode:find("[vV]") ~= nil or captured_mode == "\22"
	local pending_operator = operator or (is_operator_pending and vim.v.operator or nil)

	-- Check if treesitter is available
	local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok or not parser then
		vim.notify("Treesitter not available for this buffer", vim.log.levels.WARN)
		return
	end
	parser:parse()

	-- Get visible lines
	local top_line = vim.fn.line("w0", winid) - 1
	local bottom_line = vim.fn.line("w$", winid) - 1

	local motion_state = state.create_motion_state()
	motion_state.search_text = ""
	motion_state.is_searching_mode = true

	-- Input loop with auto-timeout (same 500ms as live search)
	local CONTINUE_TIMEOUT_MS = 500
	local last_input_time = nil

	-- Helper: redraw screen then display the search prompt in the message area.
	local function redraw_with_prompt()
		vim.cmd("redraw")
		vim.api.nvim_echo(
			{ { "Treesitter Search: ", "Comment" }, { motion_state.search_text or "" } },
			false,
			{}
		)
	end

	-- Show initial prompt
	redraw_with_prompt()

	while true do
		-- Auto-proceed to selection after pause (only when there are targets to select)
		if
			last_input_time
			and #motion_state.search_text > 0
			and motion_state.jump_targets
			and #motion_state.jump_targets > 0
		then
			local elapsed = vim.fn.reltimefloat(vim.fn.reltime(last_input_time)) * 1000
			if elapsed > CONTINUE_TIMEOUT_MS then
				break
			end
		end

		-- Non-blocking key check — re-display prompt (no redraw, so no flashing)
		if vim.fn.getchar(1) == 0 then
			vim.api.nvim_echo(
				{ { "Treesitter Search: ", "Comment" }, { motion_state.search_text or "" } },
				false,
				{}
			)
			vim.cmd("sleep 10m")
			goto continue
		end

		local char_ok, char = pcall(vim.fn.getchar)
		if not char_ok then
			highlight.clear(ctx, cfg, motion_state)
			vim.cmd("redraw")
			return
		end

		char = type(char) == "number" and vim.fn.nr2char(char) or char

		-- Handle special keys
		if char == "\027" then -- ESC
			highlight.clear(ctx, cfg, motion_state)
			vim.cmd("redraw")
			return
		elseif char == "\r" then -- Enter - proceed to selection immediately
			break
		elseif char == "\b" or char == vim.api.nvim_replace_termcodes("<BS>", true, false, true) then
			motion_state.search_text = motion_state.search_text:sub(1, -2)
		else
			motion_state.search_text = motion_state.search_text .. char
		end

		last_input_time = vim.fn.reltime()

		-- Find matches and convert to node targets
		highlight.clear(ctx, cfg, motion_state)

		if #motion_state.search_text > 0 then
			local matches = find_matches(motion_state.search_text, bufnr, top_line, bottom_line)
			local targets = matches_to_node_targets(matches, bufnr)

			if #targets > 0 then
				motion_state.jump_targets = targets
				motion_state.jump_target_count = #targets
				state.finalize_motion_state(ctx, cfg, motion_state)
				hints.run(ctx, cfg, motion_state)
			else
				motion_state.jump_targets = {}
				motion_state.jump_target_count = 0
			end
		else
			motion_state.jump_targets = {}
			motion_state.jump_target_count = 0
		end

		-- Redraw to show updated hints, then re-display prompt
		redraw_with_prompt()

		::continue::
	end

	-- If no targets, exit
	if not motion_state.jump_targets or #motion_state.jump_targets == 0 then
		highlight.clear(ctx, cfg, motion_state)
		vim.cmd("redraw")
		return
	end

	-- Phase 1: Select a match target
	motion_state.is_searching_mode = false
	highlight.clear(ctx, cfg, motion_state)
	hints.run(ctx, cfg, motion_state)
	vim.cmd("redraw")

	selection.wait_for_hint_selection(ctx, cfg, motion_state)

	highlight.clear(ctx, cfg, motion_state)
	vim.cmd("redraw")

	local match_target = motion_state.selected_jump_target
	if not match_target then
		return
	end

	-- Phase 2: Walk up from the selected node and label all ancestor nodes
	local ancestors = collect_ancestor_targets(bufnr, match_target.start_pos.row, match_target.start_pos.col)

	-- Reset flow state again — phase 1's evaluate_flow_at_selection refreshed
	-- the timestamp, which would cause phase 2's selection to be skipped
	flow_state.reset()

	local target
	if #ancestors == 0 then
		-- No ancestors above — use the match target itself
		target = match_target
	else
		-- Reset selection state for second round
		motion_state.jump_targets = ancestors
		motion_state.jump_target_count = #ancestors
		motion_state.assigned_hint_labels = {}
		motion_state.selection_mode = consts.SELECTION_MODE.FIRST
		motion_state.selection_first_char = nil
		motion_state.selected_jump_target = nil

		state.finalize_motion_state(ctx, cfg, motion_state)
		hints.run(ctx, cfg, motion_state)
		vim.cmd("redraw")

		selection.wait_for_hint_selection(ctx, cfg, motion_state)

		highlight.clear(ctx, cfg, motion_state)
		vim.cmd("redraw")

		target = motion_state.selected_jump_target
		if not target then
			return
		end
	end

	-- Record to history so g. can navigate back here
	local history = require("smart-motion.core.history")
	local trigger = pending_operator and (pending_operator .. "R") or "R"
	history.add({
		motion = { trigger_key = trigger },
		target = target,
		metadata = { time_stamp = os.time() },
	})

	-- Apply the selection based on mode
	local sr = target.start_pos.row
	local sc = target.start_pos.col
	local er = target.end_pos.row
	local ec = target.end_pos.col

	-- Move cursor to target start for all operations
	vim.api.nvim_win_set_cursor(winid, { sr + 1, sc })

	if pending_operator then
		-- Called directly from infer.run (not operator-pending mode), so we
		-- can apply operations synchronously without native operator conflicts.
		local node_lines = vim.api.nvim_buf_get_text(bufnr, sr, sc, er, ec, {})
		local text = table.concat(node_lines, "\n")
		-- Set unnamed register, yank register, and clipboard registers
		vim.fn.setreg('"', text, "c")
		vim.fn.setreg('0', text, "c")
		vim.fn.setreg('+', text, "c")
		vim.fn.setreg('*', text, "c")

		if pending_operator == "y" then
			-- Highlight the yanked range manually (on_yank only highlights around cursor)
			local ns = vim.api.nvim_create_namespace("smart_motion_yank")
			for row = sr, er do
				local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
				local col_start = (row == sr) and sc or 0
				local col_end = (row == er) and ec or #line
				if col_end > col_start then
					vim.api.nvim_buf_add_highlight(bufnr, ns, "IncSearch", row, col_start, col_end)
				end
			end
			vim.defer_fn(function()
				vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
			end, 150)
		elseif pending_operator == "d" then
			vim.api.nvim_buf_set_text(bufnr, sr, sc, er, ec, { "" })
		elseif pending_operator == "c" then
			vim.api.nvim_buf_set_text(bufnr, sr, sc, er, ec, { "" })
			vim.cmd("startinsert")
		end
	elseif is_visual then
		-- In visual mode, adjust selection to the node
		vim.api.nvim_win_set_cursor(winid, { sr + 1, sc })
		vim.cmd("normal! v")
		if ec == 0 and er > sr then
			local prev_line = vim.api.nvim_buf_get_lines(bufnr, er - 1, er, false)[1]
			vim.api.nvim_win_set_cursor(winid, { er, math.max(#prev_line - 1, 0) })
		else
			vim.api.nvim_win_set_cursor(winid, { er + 1, math.max(ec - 1, 0) })
		end
	else
		-- In normal mode, enter visual mode with node selected
		vim.api.nvim_win_set_cursor(winid, { sr + 1, sc })
		vim.cmd("normal! v")
		if ec == 0 and er > sr then
			local prev_line = vim.api.nvim_buf_get_lines(bufnr, er - 1, er, false)[1]
			vim.api.nvim_win_set_cursor(winid, { er, math.max(#prev_line - 1, 0) })
		else
			vim.api.nvim_win_set_cursor(winid, { er + 1, math.max(ec - 1, 0) })
		end
	end
end

return M
