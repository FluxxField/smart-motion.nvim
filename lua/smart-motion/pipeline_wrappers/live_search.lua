local highlight = require("smart-motion.core.highlight")
local utils = require("smart-motion.utils")
local log = require("smart-motion.core.log")
local consts = require("smart-motion.consts")

local SEARCH_EXIT_TYPE = consts.SEARCH_EXIT_TYPE

--- @type SmartMotionPipelineWrapperModule
local M = {}

--- Runs a pipeline interactively while the user types search text.
--- @param run_pipeline fun(ctx: SmartMotionContext, cfg: SmartMotionConfig, state: SmartMotionMotionState, opts: table): nil
--- @param ctx SmartMotionContext
--- @param cfg SmartMotionConfig
--- @param motion_state SmartMotionMotionState
--- @return SearchExitType
function M.run(run_pipeline, ctx, cfg, motion_state)
	local early_exit_timeout = 2000
	local continue_timeout = 500
	local start_time = vim.fn.reltime()
	local search_text = ""

	highlight.dim_background(ctx, cfg, motion_state)

	while true do
		local last_search_text = ""
		local elapsed = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000

		if elapsed > (search_text == "" and early_exit_timeout or continue_timeout) then
			if search_text == "" then
				return SEARCH_EXIT_TYPE.EARLY_EXIT
			else
				motion_state.is_searching_mode = false
				return SEARCH_EXIT_TYPE.CONTINUE_TO_SELECTION
			end
		end

		if vim.fn.getchar(1) == 0 then
			vim.cmd("sleep 10m")
		else
			local char = vim.fn.getchar()
			char = type(char) == "number" and vim.fn.nr2char(char) or char
			vim.api.nvim_feedkeys("", "n", false)

			if char == "\027" then -- ESC
				return SEARCH_EXIT_TYPE.EARLY_EXIT
			elseif char == "\r" then -- ENTER
				return SEARCH_EXIT_TYPE.CONTINUE_TO_SELECTION
			elseif char == "\b" or char == vim.api.nvim_replace_termcodes("<BS>", true, false, true) then
				-- Backspace: Remove last char
				search_text = search_text:sub(1, -2)
			else
				search_text = search_text .. char
			end

			if search_text ~= last_search_text and search_text ~= "" then
				-- Run the pipeline with the current input
				motion_state.search_text = search_text
				motion_state.is_searching_mode = true
				run_pipeline(ctx, cfg, motion_state)

				start_time = vim.fn.reltime()
				last_search_text = search_text

				local count = motion_state.jump_target_count
					or (motion_state.jump_targets and #motion_state.jump_targets or 0)

				if count == 0 then
					return SEARCH_EXIT_TYPE.EARLY_EXIT
				elseif count == 1 then
					return SEARCH_EXIT_TYPE.AUTO_SELECT
				end
			end
		end
	end

	return SEARCH_EXIT_TYPE.CONTINUE_TO_SELECTION
end

return M
