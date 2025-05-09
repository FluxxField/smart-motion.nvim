local log = require("smart-motion.core.log")
local consts = require("smart-motion.consts")
local utils = require("smart-motion.utils")
local targets = require("smart-motion.core.targets")
local state = require("smart-motion.core.state")
local flow_state = require("smart-motion.core.flow-state")
local selection = require("smart-motion.core.selection")
local highlight = require("smart-motion.core.highlight")

local EXIT_TYPE = consts.EXIT_TYPE

--- @class Dispatcher
local M = {}

--- Triggers a motion by its trigger key.
--- @param trigger_key string
function M.trigger_motion(trigger_key)
	--
	-- Get Registries and motion data
	--
	local registries = require("smart-motion.core.registries"):get()

	local motion = require("smart-motion.motions").get_by_key(trigger_key)
	if not motion then
		log.warn("No motion found for key: " .. trigger_key)
		return
	end

	--
	-- Get modules
	--
	local collector = registries.collectors.get_by_name(motion.collector)
	local extractor = registries.extractors.get_by_name(motion.extractor)
	local visualizer = registries.visualizers.get_by_name(motion.visualizer)
	local action = registries.actions.get_by_name(motion.action)

	local modifier = registries.modifiers.get_by_name(motion.modifier or "default")
	if not modifier or not modifier.run then
		modifier = registries.modifiers.get_by_name("default")
	end

	local filter = registries.filters.get_by_name(motion.filter or "default")
	if not filter or not filter.run then
		filter = registries.filters.get_by_name("default")
	end

	--
	-- Initiate state for the motion
	--
	local ctx, cfg, motion_state = utils.prepare_motion(extractor.name)
	if not ctx or not cfg or not motion_state then
		log.error("Failed to prepare motion - aborting")
		utils.reset_motion(ctx, cfg, motion_state)
		return
	end

	--
	-- Update motion_state from what the modules provide
	--
	motion_state =
		state.merge_motion_state(motion_state, motion, collector, extractor, modifier, filter, visualizer, action)

	--
	-- Evaluate flow state
	--
	if flow_state.evaluate_flow_at_motion_start() then
		M._run_core_pipeline(ctx, cfg, motion_state, collector, extractor, modifier, filter)

		if motion_state.selected_jump_target then
			action.run(ctx, cfg, motion_state)
			utils.reset_motion(ctx, cfg, motion_state)
			return
		end
	end

	--
	-- Pipeline Loop
	--
	highlight.dim_background(ctx, cfg, motion_state)

	local early_exit_timeout = 2000
	local continue_timeout = 500

	while true do
		--
		-- Multi-pass
		--
		if motion_state.is_searching_mode then
			local start_time = vim.fn.reltime()

			if motion_state.exit_type == nil then
				motion_state.exit_type = EXIT_TYPE.CONTINUE_LOOP
			end

			while motion_state.exit_type == EXIT_TYPE.CONTINUE_LOOP do
				local timeout = (motion_state.search_text == "" and early_exit_timeout) or continue_timeout
				local elapsed = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000

				if elapsed > timeout then
					if motion_state.search_text == "" then
						motion_state.exit_type = EXIT_TYPE.EARLY_EXIT
					else
						motion_state.exit_type = EXIT_TYPE.CONTINUE_TO_SELECTION
					end

					break
				end

				if motion_state.exit_type ~= EXIT_TYPE.CONTINUE_LOOP then
					break
				end

				M._run_core_pipeline(ctx, cfg, motion_state, collector, extractor, modifier, filter)

				if motion_state.search_text ~= motion_state.last_search_text and motion_state.search_text ~= "" then
					start_time = vim.fn.reltime() -- Reset timer

					visualizer.run(ctx, cfg, motion_state)
					motion_state.last_search_text = motion_state.search_text

					if motion_state.exit_type ~= EXIT_TYPE.CONTINUE_LOOP then
						local targets = motion_state.jump_targets or {}
						if #targets == 0 then
							motion_state.exit_type = EXIT_TYPE.EARLY_EXIT
							break
						elseif #targets == 1 then
							motion_state.exit_type = EXIT_TYPE.CONTINUE_TO_SELECTION
							break
						end
					end
				end

				vim.cmd("sleep 10m")
			end
			--
			-- Single Pass
			--
		else
			M._run_core_pipeline(ctx, cfg, motion_state, collector, extractor, modifier, filter)
			visualizer.run(ctx, cfg, motion_state)

			local targets = motion_state.jump_targets or {}
			if #targets == 0 then
				motion_state.exit_type = EXIT_TYPE.EARLY_EXIT
				break
			elseif #targets == 1 then
				motion_state.exit_type = EXIT_TYPE.CONTINUE_TO_SELECTION
				break
			end
		end

		if
			motion_state.exit_type == EXIT_TYPE.EARLY_EXIT
			or motion_state.exit_type == EXIT_TYPE.CONTINUE_TO_SELECTION
		then
			break
		end
	end

	--
	-- Handle exit
	--
	M._handle_exit(ctx, cfg, motion_state, action, visualizer)
	utils.reset_motion(ctx, cfg, motion_state)
end

--- Triggers an action-type motion with secondary key input.
--- @param trigger_key string
function M.trigger_action(trigger_key)
	local registries = require("smart-motion.core.registries"):get()
	local motion = require("smart-motion.motions").get_by_key(trigger_key)
	local action = registries.actions.get_by_name(motion.action)

	if motion.is_action then
		action = registries.actions.get_by_key(trigger_key)
	end

	local ok, motion_char = pcall(vim.fn.getchar)
	if not ok then
		log.warn("Failed to get motion character")
		return
	end

	local collector = registries.collectors.get_by_name(motion.collector)
	local visualizer = registries.visualizers.get_by_name(motion.visualizer)

	local modifier = registries.modifiers.get_by_name(motion.modifier or "default")
	if not modifier or not modifier.run then
		modifier = registries.modifiers.get_by_name("default")
	end

	local filter = registries.filters.get_by_name(motion.filter or "default")
	if not filter or not filter.run then
		filter = registries.filters.get_by_name("default")
	end

	local ctx, cfg, motion_state = utils.prepare_motion("")
	if not ctx or not cfg or not motion_state then
		log.error("Failde to prepare motion - aborting")
		utils.reset_motion(ctx, cfg, motion_state)
		return
	end

	motion_state = state.merge_motion_state(motion_state, motion, collector, modifier, filter, visualizer, action)

	-- Get motion_key
	local motion_key = vim.fn.nr2char(motion_char)
	local extractor = registries.extractors.get_by_key(motion_key)

	motion_state.target_type = consts.TARGET_TYPES_BY_KEY[motion_key] or ""

	--
	-- Fallback to native behavior if no extractor exists
	--
	if not extractor or not extractor.run then
		--
		-- Is this a short-curcit double key?
		--
		if motion_key == trigger_key then
			motion_state.target_type = "lines"

			local line_action = registries.actions.get_by_name(action.name .. "_line")

			if not line_action or not line_action.run then
				vim.api.nvim_feedkeys(trigger_key .. motion_key, "n", false)
				utils.reset_motion(ctx, cfg, motion_state)
				return
			end

			motion_state.selected_jump_target = targets.get_target_under_cursor(ctx, cfg, motion_state)

			if motion_state.selected_jump_target then
				line_action.run(ctx, cfg, motion_state)
			end

			utils.reset_motion(ctx, cfg, motion_state)
			return
		end

		vim.api.nvim_feedkeys(trigger_key .. motion_key, "n", false)
		utils.reset_motion(ctx, cfg, motion_state)
		return
	end

	motion_state = state.merge_motion_state(motion_state, extractor)

	--
	-- Quick action on target under cursor
	--
	local under_cursor_target = targets.get_target_under_cursor(ctx, cfg, motion_state)
	if under_cursor_target then
		motion_state.selected_jump_target = under_cursor_target
		action.run(ctx, cfg, motion_state)
		utils.reset_motion(ctx, cfg, motion_state)
		return
	end

	--
	-- Evaluate flow state
	--
	if flow_state.evaluate_flow_at_motion_start() then
		M._run_core_pipeline(ctx, cfg, motion_state, collector, extractor, filter)

		if motion_state.selected_jump_target then
			action.run(ctx, cfg, motion_state)
			utils.reset_motion(ctx, cfg, motion_state)
			return
		end
	end

	action = registries.actions.get_by_name(action.name .. "_jump")

	--
	-- Pipeline Loop
	--
	highlight.dim_background(ctx, cfg, motion_state)

	local early_exit_timeout = 2000
	local continue_timeout = 500

	while true do
		--
		-- Multi-pass
		--
		if motion_state.is_searching_mode then
			local start_time = vim.fn.reltime()

			if motion_state.exit_type == nil then
				motion_state.exit_type = EXIT_TYPE.CONTINUE_LOOP
			end

			while motion_state.exit_type == EXIT_TYPE.CONTINUE_LOOP do
				local timeout = (motion_state.search_text == "" and early_exit_timeout) or continue_timeout
				local elapsed = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000

				if elapsed > timeout then
					if motion_state.search_text == "" then
						motion_state.exit_type = EXIT_TYPE.EARLY_EXIT
					else
						motion_state.exit_type = EXIT_TYPE.CONTINUE_TO_SELECTION
					end

					break
				end

				if motion_state.exit_type ~= EXIT_TYPE.CONTINUE_LOOP then
					break
				end

				M._run_core_pipeline(ctx, cfg, motion_state, collector, extractor, modifier, filter)

				if motion_state.search_text ~= motion_state.last_search_text and motion_state.search_text ~= "" then
					start_time = vim.fn.reltime() -- Reset timer

					visualizer.run(ctx, cfg, motion_state)
					motion_state.last_search_text = motion_state.search_text

					if motion_state.exit_type ~= EXIT_TYPE.CONTINUE_LOOP then
						local targets = motion_state.jump_targets or {}
						if #targets == 0 then
							motion_state.exit_type = EXIT_TYPE.EARLY_EXIT
							break
						elseif #targets == 1 then
							motion_state.exit_type = EXIT_TYPE.CONTINUE_TO_SELECTION
							break
						end
					end
				end

				vim.cmd("sleep 10m")
			end
			--
			-- Single Pass
			--
		else
			M._run_core_pipeline(ctx, cfg, motion_state, collector, extractor, modifier, filter)
			visualizer.run(ctx, cfg, motion_state)

			local targets = motion_state.jump_targets or {}
			if #targets == 0 then
				motion_state.exit_type = EXIT_TYPE.EARLY_EXIT
				break
			elseif #targets == 1 then
				motion_state.exit_type = EXIT_TYPE.CONTINUE_TO_SELECTION
				break
			end
		end

		if
			motion_state.exit_type == EXIT_TYPE.EARLY_EXIT
			or motion_state.exit_type == EXIT_TYPE.CONTINUE_TO_SELECTION
		then
			break
		end
	end

	--
	-- Handle exit
	--
	M._handle_exit(ctx, cfg, motion_state, action, visualizer)
	utils.reset_motion(ctx, cfg, motion_state)
end

--- Prepares the pipeline by collecting and extracting motion targets.
--- @param ctx SmartMotionContext
--- @param cfg SmartMotionConfig
--- @param motion_state SmartMotionMotionState
--- @param collector SmartMotionCollectorModuleEntry
--- @param extractor SmartMotionExtractorModuleEntry
function M._run_core_pipeline(ctx, cfg, motion_state, collector, extractor, modifier, filter)
	local lines_gen = collector.run()
	if not lines_gen then
		return
	end

	local extractor_gen = extractor.run(lines_gen)
	if not extractor_gen then
		return
	end

	local modifier_gen = modifier.run(extractor_gen)
	if not modifier_gen then
		return
	end

	local filter_gen = filter.run(modifier_gen)
	if not filter_gen then
		return
	end

	targets.get_targets(ctx, cfg, motion_state, filter_gen)
	state.finalize_motion_state(motion_state)
end

--
-- Handle Exit
--
function M._handle_exit(ctx, cfg, motion_state, action, visualizer)
	if motion_state.exit_type == EXIT_TYPE.EARLY_EXIT then
		return
	end

	if motion_state.exit_type == EXIT_TYPE.DIRECT_HINT or motion_state.exit_type == EXIT_TYPE.AUTO_SELECT then
		if motion_state.selected_jump_target then
			action.run(ctx, cfg, motion_state)
		end
	elseif motion_state.exit_type == EXIT_TYPE.CONTINUE_TO_SELECTION then
		motion_state.is_searching_mode = false
		visualizer.run(ctx, cfg, motion_state)
		selection.wait_for_hint_selection(ctx, cfg, motion_state)

		if motion_state.selected_jump_target then
			action.run(ctx, cfg, motion_state)
		end
	end
end

return M
