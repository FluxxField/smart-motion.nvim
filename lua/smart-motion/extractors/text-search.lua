local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

---@type SmartMotionExtractorModuleEntry
local M = {}

--- Extracts searched text from given collector.
--- @param collector thread
--- @param opts table<{ text: string }>
--- @return thread Coroutine yielding SmartMotionJumpTarget
function M.run(collector, opts)
	return coroutine.create(function(ctx, cfg, motion_state)
		---@type SmartMotionContext
		ctx = ctx
		---@type SmartMotionConfig
		cfg = cfg
		---@type SmartMotionMotionState
		motion_state = motion_state

		local is_after_cursor = (motion_state.direction == consts.DIRECTION.AFTER_CURSOR)
		local search_text = opts.text

		if not search_text or search_text == "" then
			coroutine.yield()
		end

		while true do
			local ok, line_data = coroutine.resume(collector, ctx, cfg, motion_state)

			if not ok or not line_data then
				break
			end

			local line_text, line_number = line_data.text, line_data.line_number
			local collected_matches = {}
			local search_start_col = 0

			if line_number == ctx.cursor_line then
				if is_after_cursor then
					-- We get words from cursor to end of the line
					search_start_col = ctx.cursor_col
				else
					-- We collect the full line
					search_start_col = 0
				end
			end

			-- Collect all targets, left-to-right from the current line
			while true do
				local match_data = vim.fn.matchstrpos(line_text, "\\V" .. search_text, search_start_col)
				local match_text, start_pos, end_pos = match_data[1], match_data[2], match_data[3]

				-- If no matches, move to the next line
				if start_pos == -1 then
					break
				end

				table.insert(collected_matches, {
					text = match_text,
					start_pos = start_pos,
					end_pos = end_pos,
				})

				search_start_col = end_pos + 1
			end

			-- Handles filtering the word under the cursor
			if line_number == ctx.cursor_line then
				collected_matches = vim.tbl_filter(function(match)
					if is_after_cursor then
						-- Exclude the match the cursor is on. There is nowhere the cursor can be on the
						-- match where we can show a hint because the hint_position is START
						if ctx.cursor_col >= match.start_pos and ctx.cursor_col <= match.end_pos then
							return false
						end
					else
						-- Exclude the match if the cursor is on the start
						if ctx.cursor_col == match.start_pos then
							return false
						end
					end

					return true
				end, collected_matches)
			end

			-- If BEFORE_CURSOR, reverse the order of the words for this line
			if not is_after_cursor then
				collected_matches = vim.fn.reverse(collected_matches)
			end

			for _, match in ipairs(collected_matches) do
				---@type SmartMotionJumpTarget
				local target = {
					row = line_number,
					col = match.start_pos,
					text = match.text,
					start_pos = { row = line_number, col = match.start_pos },
					end_pos = { row = line_number, col = match.end_pos },
					type = consts.TARGET_TYPES.SEARCH,
				}

				coroutine.yield(target)
			end
		end
	end)
end

return M
