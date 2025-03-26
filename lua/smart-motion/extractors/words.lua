local consts = require("smart-motion.consts")

local M = {}

--- Extracts words from the given lines collector.
---@param collector thread The lines collector (yields line data).
---@return thread A coroutine generator yielding word jump targets.
function M.init(collector)
	return coroutine.create(function(ctx, cfg, motion_state)
		local is_after_cursor = (motion_state.direction == consts.DIRECTION.AFTER_CURSOR)

		while true do
			local ok, line_data = coroutine.resume(collector, ctx, cfg, motion_state)

			if not ok or not line_data then
				break
			end

			local line_text, line_number = line_data.text, line_data.line_number
			local collected_words = {}
			local search_start = 0

			if line_number == ctx.cursor_line then
				if is_after_cursor then
					-- We get words from cursor to end of the line
					search_start = ctx.cursor_col
				else
					-- We collect the full line
					search_start = 0
				end
			end

			-- Collect all words left-to-right for the line.
			while true do
				local match_data = vim.fn.matchstrpos(line_text, consts.WORD_PATTERN, search_start)
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

			-- Handles the filtering the word under the cursor
			if line_number == ctx.cursor_line then
				collected_words = vim.tbl_filter(function(word)
					if is_after_cursor then
						if motion_state.hint_position == consts.HINT_POSITION.START then
							-- Exclude the word if cursor is sitting *inside* its start.
							if word.start_pos == ctx.cursor_col then
								return false
							end
						elseif motion_state.hint_position == consts.HINT_POSITION.END then
							-- Exclude if cursor is on or past the end of the word.
							if ctx.cursor_col >= word.end_pos - 1 then
								return false
							end
						end
					else -- BEFORE_CURSOR
						if motion_state.hint_position == consts.HINT_POSITION.END then
							-- Exclude the word if cursor is sitting *inside* its end.
							if word.end_pos - 1 == ctx.cursor_col then
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

			-- Yield words in the desired order.
			for _, word in ipairs(collected_words) do
				local hint_position_col = (motion_state.hint_position == consts.HINT_POSITION.START) and word.start_pos
					or word.end_pos - 1

				coroutine.yield({
					row = line_number,
					col = hint_position_col,
					text = word.text,
					start_pos = { row = line_number, col = word.start_pos },
					end_pos = { row = line_number, col = word.end_pos },
					type = consts.TARGET_TYPES.WORDS,
				})
			end
		end
	end)
end

return M
