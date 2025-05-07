local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

---@type SmartMotionExtractorModuleEntry
local M = {}

--- Extracts searched text from given collector.
--- @param collector thread
--- @return thread Coroutine yielding SmartMotionTarget
function M.run(collector)
	return coroutine.create(function(ctx, cfg, motion_state)
		local search_text = motion_state.search_text or ""

		if not search_text or search_text == "" then
			coroutine.yield()
		end

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
			local search_start_col = 0

			while true do
				local match_data = vim.fn.matchstrpos(line_text, "\\V" .. search_text, search_start_col)
				local match_text, start_pos, end_pos = match_data[1], match_data[2], match_data[3]

				-- If no matches, move to the next line
				if start_pos == -1 then
					break
				end

				---@type SmartMotionTarget
				local target = {}

				coroutine.yield({
					text = match_text,
					start_pos = { row = line_number, col = start_pos },
					end_pos = { row = line_number, col = end_pos },
					type = consts.TARGET_TYPES.SEARCH,
				})

				search_start_col = end_pos + 1
			end
		end
	end)
end

M.metadata = {
	label = "Search Extractor",
	description = "Extracts searched text to generate targets from collector",
}

return M
