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

--- Converts text matches to treesitter node targets (deduped by range).
---@param matches table[]
---@param bufnr integer
---@return table[] targets
local function matches_to_node_targets(matches, bufnr)
	local targets = {}
	local seen_ranges = {}

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
						winid = vim.api.nvim_get_current_win(),
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

--- Runs the treesitter search motion.
---@param mode string|nil Override mode (for testing)
function M.run(mode)
	local context = require("smart-motion.core.context")
	local state = require("smart-motion.core.state")
	local highlight = require("smart-motion.core.highlight")
	local hints = require("smart-motion.visualizers.hints")
	local selection = require("smart-motion.core.selection")
	local cfg_mod = require("smart-motion.config")

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

	-- Show prompt
	vim.api.nvim_echo({ { "Treesitter Search: ", "Comment" } }, false, {})

	-- Input loop
	while true do
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
			vim.api.nvim_echo({ { "", "" } }, false, {})
			return
		elseif char == "\r" then -- Enter - proceed to selection
			break
		elseif char == "\b" or char == vim.api.nvim_replace_termcodes("<BS>", true, false, true) then
			motion_state.search_text = motion_state.search_text:sub(1, -2)
		else
			motion_state.search_text = motion_state.search_text .. char
		end

		-- Update display
		vim.api.nvim_echo({ { "Treesitter Search: ", "Comment" }, { motion_state.search_text, "Normal" } }, false, {})

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
				vim.cmd("redraw")
			end
		else
			motion_state.jump_targets = {}
			motion_state.jump_target_count = 0
			vim.cmd("redraw")
		end
	end

	-- Clear prompt
	vim.api.nvim_echo({ { "", "" } }, false, {})

	-- If no targets, exit
	if not motion_state.jump_targets or #motion_state.jump_targets == 0 then
		highlight.clear(ctx, cfg, motion_state)
		vim.cmd("redraw")
		return
	end

	-- Wait for label selection
	selection.wait_for_hint_selection(ctx, cfg, motion_state)

	-- Clean up highlights
	highlight.clear(ctx, cfg, motion_state)
	vim.cmd("redraw")

	local target = motion_state.selected_jump_target
	if not target then
		return
	end

	-- Apply the selection based on mode
	local sr = target.start_pos.row
	local sc = target.start_pos.col
	local er = target.end_pos.row
	local ec = target.end_pos.col

	if is_operator_pending then
		-- In operator-pending mode, set visual selection for the operator to act on
		-- Exit operator-pending mode first, then select the range
		vim.cmd("normal! v")
		vim.api.nvim_win_set_cursor(winid, { sr + 1, sc })
		vim.cmd("normal! o")
		-- Handle end position (ec is exclusive)
		if ec == 0 and er > sr then
			local prev_line = vim.api.nvim_buf_get_lines(bufnr, er - 1, er, false)[1]
			vim.api.nvim_win_set_cursor(winid, { er, math.max(#prev_line - 1, 0) })
		else
			vim.api.nvim_win_set_cursor(winid, { er + 1, math.max(ec - 1, 0) })
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
