local highlight = require("smart-motion.core.highlight")
local utils = require("smart-motion.utils")
local log = require("smart-motion.core.log")

--- @type SmartMotionPipelineWrapperModule
local M = {}

--- Runs a pipeline interactively while the user types search text.
--- @param run_pipeline fun(ctx: SmartMotionContext, cfg: SmartMotionConfig, state: SmartMotionMotionState, opts: table): nil
--- @param ctx SmartMotionContext
--- @param cfg SmartMotionConfig
--- @param motion_state SmartMotionMotionState
--- @param opts table
--- @return boolean? Return true to exit early, false to continue
function M.run(run_pipeline, ctx, cfg, motion_state, opts)
	local timeoutlen = 1000
	local start_time = nil
	local search_text = ""

	highlight.dim_background(ctx, cfg, motion_state)

	while true do
		local last_search_text = ""

		if start_time then
			local elapsed = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000

			if elapsed > timeoutlen then
				if not search_text or search_text == "" then
					return true
				end

				return false
			end
		end

		if vim.fn.getchar(1) == 0 then
			vim.cmd("sleep 10m")
		else
			local char = vim.fn.getchar()

			char = type(char) == "number" and vim.fn.nr2char(char) or char

			vim.api.nvim_feedkeys("", "")

			if char == "\027" then -- ESC
				return true
			elseif char == "\r" then -- ENTER
				return false
			elseif char == "\b" or char == vim.api.nvim_replace_termcodes("<BS>", true, false, true) then
				-- Backspace: Remove last char
				search_text = search_text:sub(1, -2)
			else
				search_text = search_text .. char
			end

			-- Check if typed char matches a single-char jump target
			local entry = motion_state.assigned_hint_labels and motion_state.assigned_hint_labels[char]
			if entry and entry.is_single_prefix and entry.jump_target then
				motion_state.selected_jump_target = entry.jump_target
				opts.action.run(ctx, cfg, motion_state)
				return true
			end

			if search_text ~= last_search_text and search_text ~= "" then
				-- Run the pipeline with the current input
				local extractor_opts = { text = search_text }
				run_pipeline(ctx, cfg, motion_state, extractor_opts)

				start_time = vim.fn.reltime()
				last_search_text = search_text

				local count = motion_state.jump_target_count
					or (motion_state.jump_targets and #motion_state.jump_targets or 0)

				if count == 0 then
					return true
				elseif count == 1 then
					opts.action.run(ctx, cfg, motion_state)
					return true
				end
			end
		end
	end
end

return M
