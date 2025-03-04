--- Target configuration
---
--- Example: A Word Target
--- {
---     bufnr = 12,                          -- Buffer number
---     winid = 1001,                        -- Window ID
---     row = 14,                            -- Line number (1-based)
---     col = 7,                             -- Column number (0-based)
---     text = "example",                    -- Text at this position (optional for some collectors)
---     start_pos = { row = 14, col = 7 },   -- Start of the object (word, char, line)
---     end_pos = { row = 14, col = 13 },    -- End of the object (word, char, line)
---     type = "word",                       -- What kind of target this is (word, char, line, file, symbol, etc.)
---     metadata = {},                       -- Flexible metadata table (for things like file paths, diagnostics, symbols, etc.)
--- }
---
--- Example: A File Target (from Telescope Collector)
--- {
---     bufnr = nil,  -- Not open yet
---     winid = nil,  -- No window yet
---     row = nil,    -- Not needed for files
---     col = nil,
---     text = "README.md",
---     type = "file",
---     metadata = {
---         filepath = "/path/to/README.md"
---     }
--- }
---
--- Example: A Diagnostic Target (from LSP Collector)
--- {
---     bufnr = 15,
---     winid = 1002,
---     row = 30,
---     col = 10,
---     text = "unexpected symbol",
---     type = "diagnostic",
---     metadata = {
---         severity = "Error",
---         source = "eslint",
---         code = "no-undef"
---     }
--- }

local M = {}

local log = require("smart-motion.core.log")
local consts = require("smart-motion.consts")

local function word_stream(ctx, cfg, motion_state)
	local direction = motion_state.direction
	local is_after_cursor = (direction == consts.DIRECTION.AFTER_CURSOR)

	for line_idx, line in ipairs(motion_state.lines) do
		local actual_line_number = ctx.cursor_line + line_idx - 1

		-- For BEFORE_CURSOR, lines are already reversed by lines.lua, so no need to flip here.
		if not is_after_cursor then
			actual_line_number = ctx.cursor_line - (line_idx - 1)
		end

		local collected_words = {}

		local search_start = 0
		if line_idx == 1 then
			if is_after_cursor then
				search_start = ctx.cursor_col
			else
				search_start = 0 -- We collect the full line, and filter later
			end
		end

		-- Collect all words left-to-right.
		while true do
			local match_data = vim.fn.matchstrpos(line, consts.WORD_PATTERN, search_start)
			local match_text, start_pos, end_pos = match_data[1], match_data[2], match_data[3]

			if start_pos == -1 then
				break
			end

			table.insert(collected_words, {
				text = match_text,
				start_pos = start_pos,
				end_pos = end_pos,
			})

			search_start = end_pos + 1
		end

		-- Filter the first line based on cursor position
		if line_idx == 1 then
			if is_after_cursor then
				-- Drop words that start before the cursor.
				collected_words = vim.tbl_filter(function(word)
					return word.start_pos >= ctx.cursor_col
				end, collected_words)
			else
				-- Drop words that end after the cursor.
				collected_words = vim.tbl_filter(function(word)
					return word.end_pos <= ctx.cursor_col
				end, collected_words)
			end
		end

		-- If BEFORE_CURSOR, reverse the order of words for this line.
		if not is_after_cursor then
			collected_words = vim.fn.reverse(collected_words)
		end

		-- Yield words (targets) in the desired order.
		for _, word in ipairs(collected_words) do
			local target_pos_col = (motion_state.hint_position == consts.HINT_POSITION.START) and word.start_pos
				or (word.end_pos - 1)

			local jump_target = {
				bufnr = ctx.bufnr,
				winid = ctx.winid,
				row = actual_line_number,
				col = target_pos_col,
				text = word.text,
				start_pos = { row = actual_line_number, col = word.start_pos },
				end_pos = { row = actual_line_number, col = word.end_pos },
				type = "word",
				metadata = {},
			}

			coroutine.yield(jump_target)
		end
	end
end

function M.generate_jump_targets_from_words(ctx, cfg, motion_state, flow_state)
	if not motion_state.lines or #motion_state.lines == 0 then
		log.debug("generate_targets_from_words: No lines provided")
		return coroutine.create(function() end), nil
	end

	local co = coroutine.create(word_stream)

	local ok, first_jump_target = coroutine.resume(co, ctx, cfg, motion_state)

	if not ok then
		log.error("Error resuming word generator coroutine: " .. tostring(first_jump_target))
		return coroutine.create(function() end), nil
	end

	return co, first_jump_target
end

return M
