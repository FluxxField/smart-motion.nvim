local exit = require("smart-motion.core.events.exit")
local log = require("smart-motion.core.log")
local consts = require("smart-motion.consts")

local EXIT_TYPE = consts.EXIT_TYPE
local TARGET_TYPES = consts.TARGET_TYPES

---@type SmartMotionExtractorModuleEntry
local M = {}

function M.before_input_loop(ctx, cfg, motion_state)
	exit.throw_if(#motion_state.search_text >= (motion_state.num_of_char or 1), EXIT_TYPE.CONTINUE_TO_SELECTION)

	exit.throw_if(vim.fn.getchar(1) == 0, EXIT_TYPE.PIPELINE_EXIT)

	local ok, char = exit.safe(pcall(vim.fn.getchar))
	exit.throw_if(not ok, EXIT_TYPE.EARLY_EXIT)

	char = type(char) == "number" and vim.fn.nr2char(char) or char
	vim.api.nvim_feedkeys("", "n", false)

	exit.throw_if(char == "\027", EXIT_TYPE.EARLY_EXIT)

	if char == "\b" or char == vim.api.nvim_replace_termcodes("<BS>", true, false, true) then
		motion_state.search_text = motion_state.search_text:sub(1, -2)
	else
		motion_state.search_text = motion_state.search_text .. char
	end
end

--- Extracts searched text from given collector.
--- @param collector thread
--- @return thread Coroutine yielding SmartMotionTarget
function M.run(ctx, cfg, motion_state, data)
	return coroutine.create(function()
		local text, line_number = data.text, data.line_number
		local col = 0

		while true do
			local match_data = vim.fn.matchstrpos(text, "\\V" .. motion_state.search_text, col)
			local match, start_col, end_col = match_data[1], match_data[2], match_data[3]

			if start_col == -1 then
				break
			end

			coroutine.yield({
				text = match,
				start_pos = { row = line_number, col = start_col },
				end_pos = { row = line_number, col = end_col },
				type = TARGET_TYPES.SEARCH,
			})

			col = end_col + 1
		end
	end)
end

M.metadata = {
	label = "Text Search Extractor",
	description = "Extracts searched text to generate targets from collector",
	motion_state = {
		last_search_text = nil,
		search_text = "",
		is_searching_mode = true,
		should_show_prefix = true,
		timeout_after_input = false,
		target_type = "words",
	},
}

return M
