local exit_event = require("smart-motion.core.events.exit")
local consts = require("smart-motion.consts")
local pipeline = require("smart-motion.core.engine.pipeline")
local module_loader = require("smart-motion.utils.module_loader")
local log = require("smart-motion.core.log")

-- TODO: Move to config
local EARLY_EXIT_TIMEOUT = 2000
local CONTINUE_TIMEOUT = 500
local EXIT_TYPE = consts.EXIT_TYPE

local M = {}

function M.run(ctx, cfg, motion_state)
	local visualizer = module_loader.get_module(ctx, cfg, motion_state, "visualizer")

	-- Single pass mode
	if not motion_state.is_searching_mode then
		pipeline.run(ctx, cfg, motion_state)

		local targets = motion_state.jump_targets or {}
		exit_event.throw_if(#targets == 0, EXIT_TYPE.EARLY_EXIT)
		exit_event.throw_if(#targets == 1 and motion_state.auto_select_target, EXIT_TYPE.AUTO_SELECT)

		visualizer.run(ctx, cfg, motion_state)
		exit_event.throw(EXIT_TYPE.CONTINUE_TO_SELECTION)
	end

	-- Mulit-pass mode
	if motion_state.is_searching_mode then
		while true do
			local start_time = vim.fn.reltime()
			-- inner loop: pipeline repeat
			while true do
				local timeout

				if type(motion_state.search_text) == "string" and motion_state.search_text ~= "" then
					timeout = motion_state.timeout_after_input and CONTINUE_TIMEOUT or nil
				else
					timeout = EARLY_EXIT_TIMEOUT
				end

				local elapsed_time = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000

				if timeout and elapsed_time > timeout then
					if type(motion_state.search_text) == "string" and motion_state.search_text ~= "" then
						exit_event.throw(EXIT_TYPE.CONTINUE_TO_SELECTION)
					else
						exit_event.throw(EXIT_TYPE.EARLY_EXIT)
					end
				end

				local exit_type = exit_event.wrap(function()
					pipeline.run(ctx, cfg, motion_state)
				end)

				exit_event.throw_if(exit_type and exit_type ~= EXIT_TYPE.PIPELINE_EXIT, exit_type)

				if
					type(motion_state.search_text) == "string"
					and motion_state.search_text ~= ""
					and motion_state.search_text ~= motion_state.last_search_text
				then
					if motion_state.timeout_after_input then
						start_time = vim.fn.reltime()
					end

					local targets = motion_state.jump_targets or {}
					exit_event.throw_if(#targets == 0, EXIT_TYPE.EARLY_EXIT)
					exit_event.throw_if(#targets == 1 and motion_state.auto_select_target, EXIT_TYPE.AUTO_SELECT)

					visualizer.run(ctx, cfg, motion_state)
					motion_state.last_search_text = motion_state.search_text
				end

				vim.cmd("sleep 10m")
			end
		end
	end
end

return M
