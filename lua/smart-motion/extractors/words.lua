local log = require("smart-motion.core.log")
local consts = require("smart-motion.consts")

local WORD_PATTERN = consts.WORD_PATTERN
local TARGET_TYPES = consts.TARGET_TYPES
local EXIT_TYPE = consts.EXIT_TYPE

---@class SmartMotionWordMatch
---@field text string
---@field start_pos integer  -- column start (0-based)
---@field end_pos integer    -- column end (exclusive)

---@type SmartMotionExtractorModuleEntry
local M = {}

--- Extracts words from the given line collector coroutine.
--- @param collector thread
--- @return thread Coroutine yielding SmartMotionTarget
function M.run(ctx, cfg, motion_state, data)
	return coroutine.create(function()
		local line_text, line_number = data.text, data.line_number
		local search_start = 0

		while true do
			local match_data = vim.fn.matchstrpos(line_text, motion_state.word_pattern, search_start)
			local match_text, start_pos, end_pos = match_data[1], match_data[2], match_data[3]

			if start_pos == -1 then
				break
			end

			coroutine.yield({
				text = match_text,
				start_pos = { row = line_number, col = start_pos },
				end_pos = { row = line_number, col = end_pos },
				type = TARGET_TYPES.WORDS,
				metadata = data.metadata,
			})

			search_start = end_pos + 1
		end
	end)
end

M.metadata = {
	label = "Word Extractor",
	description = "Extracts words to generate targets from collector",
	motion_state = {
		word_pattern = WORD_PATTERN,
		target_type = "words",
	},
}

return M
