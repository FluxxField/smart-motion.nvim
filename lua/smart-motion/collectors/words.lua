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

		-- First line filtering logic (handling cursor word rules)
		if line_idx == 1 then
			collected_words = vim.tbl_filter(function(word)
				if is_after_cursor then
					if motion_state.hint_position == consts.HINT_POSITION.START then
						-- Exclude the word if cursor is sitting *inside* its start.
						if word.start_pos == ctx.cursor_col then
							return false
						end
					elseif motion_state.hint_position == consts.HINT_POSITION.END then
						-- Exclude if cursor is on or past the end of the word.
						if ctx.cursor_col >= word.end_pos then
							return false
						end
					end
				else -- BEFORE_CURSOR
					if motion_state.hint_position == consts.HINT_POSITION.END then
						-- Exclude the word if cursor is sitting *inside* its end.
						if word.end_pos == ctx.cursor_col then
							return false
						end
					elseif motion_state.hint_position == consts.HINT_POSITION.START then
						-- Exclude if cursor is on or before the start of the word.
						if ctx.cursor_col <= word.start_pos then
							return false
						end
					end
				end

				return true
			end, collected_words)
		end

		-- If BEFORE_CURSOR, reverse the order of words for this line.
		if not is_after_cursor then
			collected_words = vim.fn.reverse(collected_words)
		end

		-- Yield words (targets) in the desired order.
		for _, word in ipairs(collected_words) do
			local target_pos_col = (motion_state.hint_position == consts.HINT_POSITION.START) and word.start_pos
				or word.end_pos

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
