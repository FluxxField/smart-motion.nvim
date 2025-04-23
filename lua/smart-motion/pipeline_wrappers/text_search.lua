local highlight = require("smart-motion.core.highlight")
local utils = require("smart-motion.utils")
local log = require("smart-motion.core.log")
local consts = require("smart-motion.consts")

local SEARCH_EXIT_TYPE = consts.SEARCH_EXIT_TYPE

---@type SmartMotionPipelineWrapperModule
local M = {}

---@param run_pipeline fun(ctx: SmartMotionContext, cfg: SmartMotionConfig, state: SmartMotionMotionState, opts: table): nil
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@param opts table
---@return SearchExitType
function M.run(run_pipeline, ctx, cfg, motion_state, opts)
	local num_of_char = opts.num_of_char or 1
	local timeout_ms = 2000
	local search_text = ""
	local start_time = vim.fn.reltime()

	highlight.dim_background(ctx, cfg, motion_state)

	while #search_text < num_of_char do
		local last_search_text = ""

		-- Cancel after timeout if no input yet
		local elapsed = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000
		if #search_text == 0 and elapsed > timeout_ms then
			return SEARCH_EXIT_TYPE.EARLY_EXIT
		end

		-- Wait for input
		if vim.fn.getchar(1) == 0 then
			vim.cmd("sleep 10m")
		else
			local char = vim.fn.getchar()
			char = type(char) == "number" and vim.fn.nr2char(char) or char
			vim.api.nvim_feedkeys("", "n", false) -- flush pending operators

			if char == "\027" then -- ESC
				return SEARCH_EXIT_TYPE.EARLY_EXIT
			elseif char == "\b" or char == vim.api.nvim_replace_termcodes("<BS>", true, false, true) then
				-- Backspace: Remove last char
				search_text = search_text:sub(1, -2)
			else
				search_text = search_text .. char
			end

			if search_text ~= last_search_text and #search_text > 0 then
				start_time = nil -- stop timeout tracking

				-- Run the pipeline once we hit the desired char count
				local merged_opts = vim.tbl_extend(
					"force",
					opts,
					{ text = utils.escape_lua_pattern(search_text), is_search_mode = num_of_char > 1 }
				)
				run_pipeline(ctx, cfg, motion_state, merged_opts)

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
