local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local EXIT_TYPE = consts.EXIT_TYPE
local TARGET_TYPES = consts.TARGET_TYPES

---@type SmartMotionExtractorModuleEntry
local M = {}

function M.before_input_loop(ctx, cfg, motion_state)
	if vim.fn.getchar(1) == 0 then
		return EXIT_TYPE.CONTINUE_LOOP
	end

	local ok, char = pcall(vim.fn.getchar)
	if not ok then
		return EXIT_TYPE.EARLY_EXIT
	end

	char = type(char) == "number" and vim.fn.nr2char(char) or char
	vim.api.nvim_feedkeys("", "n", false)

	if char == "\027" then -- ESC
		return EXIT_TYPE.EARLY_EXIT
	elseif char == "\r" then -- ENTER
		motion_state.exit_type = EXIT_TYPE.CONTINUE_TO_SELECTION
	elseif char == "\b" or char == vim.api.nvim_replace_termcodes("<BS>", true, false, true) then
		motion_state.search_text = motion_state.search_text:sub(1, -2)
	else
		motion_state.search_text = (motion_state.search_text or "") .. char
	end
end

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
	label = "Live Search Extractor",
	description = "Continuously updates search results as the user types",
	motion_state = {
		last_search_text = nil,
		search_text = "",
		is_searching_mode = true,
		should_show_prefix = true,
		timeout_after_input = true,
	},
}

return M
