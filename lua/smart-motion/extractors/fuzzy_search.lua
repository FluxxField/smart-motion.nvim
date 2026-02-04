--- Fuzzy search extractor: finds fuzzy matches as user types.
local exit = require("smart-motion.core.events.exit")
local consts = require("smart-motion.consts")
local fuzzy = require("smart-motion.core.fuzzy")
local log = require("smart-motion.core.log")

local EXIT_TYPE = consts.EXIT_TYPE
local TARGET_TYPES = consts.TARGET_TYPES

---@type SmartMotionExtractorModuleEntry
local M = {}

function M.before_input_loop(ctx, cfg, motion_state)
	exit.throw_if(vim.fn.getchar(1) == 0, EXIT_TYPE.PIPELINE_EXIT)

	local ok, char = exit.safe(pcall(vim.fn.getchar))
	exit.throw_if(not ok, EXIT_TYPE.EARLY_EXIT)

	char = type(char) == "number" and vim.fn.nr2char(char) or char
	vim.api.nvim_feedkeys("", "n", false)

	exit.throw_if(char == "\027", EXIT_TYPE.EARLY_EXIT)
	exit.throw_if(char == "\r", EXIT_TYPE.CONTINUE_TO_SELECTION)

	if char == "\b" or char == vim.api.nvim_replace_termcodes("<BS>", true, false, true) then
		motion_state.search_text = motion_state.search_text:sub(1, -2)
	else
		motion_state.search_text = (motion_state.search_text or "") .. char
	end
end

function M.run(ctx, cfg, motion_state, data)
	return coroutine.create(function()
		local text, line_number = data.text, data.line_number
		local search_text = motion_state.search_text

		if not search_text or #search_text == 0 then
			return
		end

		-- Determine case sensitivity based on vim settings
		local ignorecase = vim.o.ignorecase
		local smartcase = vim.o.smartcase
		local case_sensitive = not ignorecase
		if smartcase and search_text:match("[A-Z]") then
			case_sensitive = true
		end

		-- Find fuzzy matches in this line
		local matches = fuzzy.find_matches_in_line(search_text, text, case_sensitive)

		for _, match in ipairs(matches) do
			coroutine.yield({
				text = match.text,
				start_pos = { row = line_number, col = match.start_col },
				end_pos = { row = line_number, col = match.end_col },
				type = TARGET_TYPES.SEARCH,
				metadata = vim.tbl_extend("force", data.metadata or {}, {
					fuzzy_score = match.score,
					fuzzy_positions = match.positions,
				}),
			})
		end
	end)
end

M.metadata = {
	label = "Fuzzy Search Extractor",
	description = "Finds fuzzy matches as the user types, ranking by match quality",
	motion_state = {
		last_search_text = nil,
		search_text = "",
		is_searching_mode = true,
		should_show_prefix = true,
		timeout_after_input = true,
		target_type = "words",
		sort_by = "fuzzy_score",
		sort_descending = true, -- Higher scores first
	},
}

return M
