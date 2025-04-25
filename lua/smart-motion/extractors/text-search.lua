local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

---@type SmartMotionExtractorModuleEntry
local M = {}

--- Extracts searched text from given collector.
--- @param collector thread
--- @param opts table<{ text: string }>
--- @return thread Coroutine yielding SmartMotionTarget
function M.run(collector, opts)
	return coroutine.create(function(ctx, cfg, motion_state)
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
			local search_start_col = 0

			while true do
				local match_data = vim.fn.matchstrpos(line_text, "\\V" .. search_text, search_start_col)
				local match_text, start_pos, end_pos = match_data[1], match_data[2], match_data[3]

				-- If no matches, move to the next line
				if start_pos == -1 then
					break
				end

				---@type SmartMotionTarget
				local target = {
					text = match.text,
					start_pos = { row = line_number, col = match.start_pos },
					end_pos = { row = line_number, col = match.end_pos },
					type = consts.TARGET_TYPES.SEARCH,
				}

				coroutine.yield(target)

				search_start_col = end_pos + 1
			end
		end
	end)
end

return M
