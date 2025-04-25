local log = require("smart-motion.core.log")
local consts = require("smart-motion.consts")

---@class SmartMotionWordMatch
---@field text string
---@field start_pos integer  -- column start (0-based)
---@field end_pos integer    -- column end (exclusive)

---@type SmartMotionExtractorModuleEntry
local M = {}

--- Extracts words from the given line collector coroutine.
--- @param collector thread
--- @param opts table Additional options passed along the pipeline
--- @return thread Coroutine yielding SmartMotionTarget
function M.run(collector, opts)
	return coroutine.create(function(ctx, cfg, motion_state)
		while true do
			local ok, data_or_error = coroutine.resume(collector, ctx, cfg, motion_state)

			if not ok then
				log.error("Collector Coroutine Error: " .. tostring(data_or_error))
				break
			end

			if not data_or_error then
				break
			end

			local line_text, line_number = data_or_error.text, data_or_error.line_number
			local search_start = 0

			while true do
				local match_data = vim.fn.matchstrpos(line_text, consts.WORD_PATTERN, search_start)
				local match_text, start_pos, end_pos = match_data[1], match_data[2], match_data[3]

				if start_pos == -1 then
					break
				end

				coroutine.yield({
					text = match_text,
					start_pos = { row = line_number, col = start_pos },
					end_pos = { row = line_number, col = end_pos },
					type = consts.TARGET_TYPES.WORDS,
				})

				search_start = end_pos + 1
			end
		end
	end)
end

return M
