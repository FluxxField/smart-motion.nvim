local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local EXIT_TYPE = consts.EXIT_TYPE

---@type SmartMotionExtractorModuleEntry
local M = {}

function M.run(collector_gen)
	return coroutine.create(function(ctx, cfg, motion_state)
		motion_state.search_text = motion_state.search_text or ""

		local early_exit_timeout = 2000
		local continue_timeout = 500
		local timeout = (motion_state.search_text == "" and early_exit_timeout) or continue_timeout
		local start_time = vim.fn.reltime()

		--
		-- Wait for input or timeout
		--
		while vim.fn.getchar(1) == 0 do
			local elapsed = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000

			if elapsed > timeout then
				if motion_state.search_text == "" then
					motion_state.exit_type = EXIT_TYPE.EARLY_EXIT
				else
					motion_state.is_searching_mode = false
					motion_state.exit_type = EXIT_TYPE.CONTINUE_TO_SELECTION
				end
				return
			end

			vim.cmd("sleep 50m")
		end

		--
		-- Got input
		--
		local char = vim.fn.getchar()
		char = type(char) == "number" and vim.fn.nr2char(char) or char
		vim.api.nvim_feedkeys("", "n", false)

		if char == "\027" then -- ESC
			motion_state.exit_type = EXIT_TYPE.EARLY_EXIT
			return
		elseif char == "\r" then -- ENTER
			motion_state.exit_type = EXIT_TYPE.CONTINUE_TO_SELECTION
			return
		elseif char == "\b" or char == vim.api.nvim_replace_termcodes("<BS>", true, false, true) then
			motion_state.search_text = motion_state.search_text:sub(1, -2)
		else
			motion_state.search_text = motion_state.search_text .. char
		end

		if motion_state.search_text == "" then
			motion_state.exit_type = EXIT_TYPE.EARLY_EXIT
			return
		end

		while true do
			local ok, line = coroutine.resume(collector_gen, ctx, cfg, motion_state)
			if not ok or not line then
				break
			end

			local text, line_number = line.text, line.line_number
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
					type = consts.TARGET_TYPES.SEARCH,
				})

				col = end_col + 1
			end
		end
	end)
end

M.metadata = {
	label = "Live Search Extractor",
	description = "Continuously updates search results as the user types",
	motion_state = {
		search_text = "",
		is_searching_mode = true,
	},
}

return M
