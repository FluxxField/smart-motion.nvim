local highlight = require("smart-motion.core.highlight")
local log = require("smart-motion.core.log")

local EXIT_TYPE = require("smart-motion.consts").EXIT_TYPE

---@type SmartMotionExtractorModuleEntry
local M = {}

--- Extracts searched text from given collector.
--- @param collector thread
--- @return thread Coroutine yielding SmartMotionTarget
function M.run(collector)
	return coroutine.create(function(ctx, cfg, motion_state)
		local num_of_char = state.num_of_char or 1
		local timeout_ms = 2000
		local search_text = ""
		local start_time = vim.fn.reltime()

		highlight.dim_background(ctx, cfg, state)

		while #search_text < num_of_char do
			-- Timeout early exit
			local elapsed = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000
			if #search_text == 0 and elapsed > timeout_ms then
				motion_state.exit_type = EXIT_TYPE.EARLY_EXIT
				coroutine.yield()
				break
			end

			if vim.fn.getchar(1) == 0 then
				vim.cmd("sleep 10m")
			else
				local char = vim.fn.getchar()
				char = type(char) == "number" and vim.fn.nr2char(char) or char
				vim.api.nvim_feedkeys("", "n", false) -- flush pending ops

				if char == "\027" then -- ESC
					motion_state.exit_type = EXIT_TYPE.EARLY_EXIT
					coroutine.yield()
					break
				elseif char == "\b" or char == vim.api.nvim_replace_termcodes("<BS>", true, false, true) then
					search_text = search_text:sub(1, -2)
				else
					search_text = search_text .. char
				end

				-- Run matching
				local match_count = 0

				while true do
					local ok, line = coroutine.resume(collector, ctx, cfg, motion_state)
					if not ok or not line then
						break
					end

					local text, line_number = line.text, line.line_number
					local col = 0

					while true do
						local match_data = vim.fn.matchstrpos(text, "\\V" .. search_text, col)
						local match, start_col, end_col = match_data[1], match_data[2], match_data[3]
						if start_col == -1 then
							break
						end

						match_count = match_count + 1

						coroutine.yield({
							text = match,
							start_pos = { row = line_number, col = start_col },
							end_pos = { row = line_number, col = end_col },
							type = consts.TARGET_TYPES.SEARCH,
						})

						col = end_col + 1
					end
				end

				-- Decide on exit behavior
				if match_count == 0 then
					motion_state.exit_type = EXIT_TYPE.EARLY_EXIT
					coroutine.yield()
					break
				elseif match_count == 1 then
					motion_state.exit_type = EXIT_TYPE.AUTO_SELECT
					coroutine.yield()
					break
				end
			end
		end

		-- Finished input, continue to hint selection
		if not motion_state.exit_type then
			motion_state.exit_type = EXIT_TYPE.CONTINUE_TO_SELECTION
		end
	end)
end

M.metadata = {
	label = "Text Search Extractor",
	description = "Extracts searched text to generate targets from collector",
}

return M
