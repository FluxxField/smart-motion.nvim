local log = require("smart-motion.core.log")
local consts = require("smart-motion.consts")
local utils = require("smart-motion.utils")
local targets = require("smart-motion.core.targets")
local state = require("smart-motion.core.state")
local flow_state = require("smart-motion.core.flow-state")
local selection = require("smart-motion.core.selection")

local SEARCH_EXIT_TYPE = consts.SEARCH_EXIT_TYPE

--- @class Dispatcher
local M = {}

--- Triggers a motion by its trigger key.
--- @param trigger_key string
function M.trigger_motion(trigger_key)
	-- Get Registries and motion data
	local registries = require("smart-motion.core.registries"):get()

	local motion = require("smart-motion.motions").get_by_key(trigger_key)
	if not motion then
		log.warn("No motion found for key: " .. trigger_key)
		return
	end

	local pipeline = motion.pipeline
	local collector = registries.collectors.get_by_name(pipeline.collector)
	local extractor = registries.extractors.get_by_name(pipeline.extractor)
	local visualizer = registries.visualizers.get_by_name(pipeline.visualizer)
	local action = registries.actions.get_by_name(motion.action)

	-- Check if filter needs fallback
	local filter = registries.filters.get_by_name(pipeline.filter or "default")
	if not filter or not filter.run then
		filter = registries.filters.get_by_name("default")
	end

	-- Build ctx, cfg, motion_state
	local ctx, cfg, motion_state = utils.prepare_motion(extractor.name)
	if not ctx or not cfg or not motion_state then
		log.error("Failed to prepare motion - aborting")
		return
	end

	state.merge_motion_state(motion_state, motion, collector, extractor, filter, visualizer, action)
	utils.reset_motion(ctx, cfg, motion_state)

	-- Evaluate flow state
	if flow_state.evaluate_flow_at_motion_start() then
		M._prepare_pipeline(ctx, cfg, motion_state, collector, extractor, filter, motion.opts)

		if motion_state.selected_jump_target then
			action.run(ctx, cfg, motion_state, motion.opts)
			utils.reset_motion(ctx, cfg, motion_state)

			return
		end
	end

	-- Check if wrapper needs fallback
	local pipeline_wrapper = registries.pipeline_wrappers.get_by_name(motion.pipeline_wrapper or "default")
	if not pipeline_wrapper or not pipeline_wrapper.run then
		pipeline_wrapper = registries.pipeline_wrappers.get_by_name("default")
	end

	motion_state = vim.tbl_deep_extend("force", motion_state, pipeline_wrapper.metadata.motion_state)

	-- Build and run the pipeline
	local run_pipeline = M._build_pipeline(collector, extractor, filter, visualizer)
	local exit_type = pipeline_wrapper.run(run_pipeline, ctx, cfg, motion_state, motion.opts)

	-- Handle pipeline early exits
	M._handle_exit(ctx, cfg, motion_state, exit_type, action, visualizer)

	-- Clean up
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

	local pipeline = motion.pipeline
	local collector = registries.collectors.get_by_name(pipeline.collector)
	local visualizer = registries.visualizers.get_by_name(pipeline.visualizer)

	-- Check if filter needs a fallback
	local filter = registries.filters.get_by_name(pipeline.filter or "default")
	if not filter or not filter.run then
		filter = registries.filters.get_by_name("default")
	end

	local ctx, cfg, motion_state = utils.prepare_motion("")
	if not ctx or not cfg or not motion_state then
		log.error("Failde to prepare motion - aborting")
		return
	end

	state.merge_motion_state(motion_state, motion, collector, filter, visualizer, action)
	utils.reset_motion(ctx, cfg, motion_state)

	-- Get motion_key
	local motion_key = vim.fn.nr2char(motion_char)
	local extractor = registries.extractors.get_by_key(motion_key)

	motion_state.target_type = consts.TARGET_TYPES_BY_KEY[motion_key] or ""

	-- Fallback to native behavior if no extractor exists
	if not extractor or not extractor.run then
		-- Is this a short-curcit double key?
		if motion_key == trigger_key then
			motion_state.target_type = "lines"

			local line_action = registries.actions.get_by_name(action.name .. "_line")

			if not line_action or not line_action.run then
				vim.api.nvim_feedkeys(trigger_key .. motion_key, "n", false)
				return
			end

			motion_state.selected_jump_target = targets.get_target_under_cursor(ctx, cfg, motion_state)

			if motion_state.selected_jump_target then
				line_action.run(ctx, cfg, motion_state, motion.opts)
			end

			return
		end

		vim.api.nvim_feedkeys(trigger_key .. motion_key, "n", false)
		return
	end

	state.merge_motion_state(motion_state, extractor)

	local under_cursor_target = targets.get_target_under_cursor(ctx, cfg, motion_state)

	if under_cursor_target then
		motion_state.selected_jump_target = under_cursor_target
		action.run(ctx, cfg, motion_state, motion.opts)
		utils.reset_motion(ctx, cfg, motion_state)
		return
	end

	if flow_state.evaluate_flow_at_motion_start() then
		M._prepare_pipeline(ctx, cfg, motion_state, collector, extractor, filter, motion.opts)

		if motion_state.selected_jump_target then
			action.run(ctx, cfg, motion_state, motion.opts)
			utils.reset_motion(ctx, cfg, motion_state)
			return
		end
	end

	action = registries.actions.get_by_name(action.name .. "_jump")

	-- Check if wrapper needs fallback
	local pipeline_wrapper = registries.pipeline_wrappers.get_by_name(motion.pipeline_wrapper or "default")
	if not pipeline_wrapper or not pipeline_wrapper.run then
		pipeline_wrapper = registries.pipeline_wrappers.get_by_name("default")
	end

	state.merge_motion_state(motion_state, pipeline_wrapper)

	local run_pipeline = M._build_pipeline(collector, extractor, filter, visualizer)
	local exit_type = pipeline_wrapper.run(run_pipeline, ctx, cfg, motion_state, motion.opts)

	M._handle_exit(ctx, cfg, motion_state, exit_type, action, visualizer)

	utils.reset_motion(ctx, cfg, motion_state)
end

--- Prepares the pipeline by collecting and extracting motion targets.
--- @param ctx SmartMotionContext
--- @param cfg SmartMotionConfig
--- @param motion_state SmartMotionMotionState
--- @param collector SmartMotionCollectorModuleEntry
--- @param extractor SmartMotionExtractorModuleEntry
function M._prepare_pipeline(ctx, cfg, motion_state, collector, extractor, filter)
	local lines_gen = collector.run()
	if not lines_gen then
		return
	end

	local extractor_gen = extractor.run(lines_gen)
	if not extractor_gen then
		return
	end

	local filter_gen = filter.run(extractor_gen)
	if not filter_gen then
		return
	end

	targets.get_targets(ctx, cfg, motion_state, filter_gen)
	state.finalize_motion_state(motion_state)
end

--- Builds the pipeline runner function
--- @param collector SmartMotionCollectorModuleEntry
--- @param extractor SmartMotionExtractorModuleEntry
--- @param filter SmartMotionFilterModuleEntry
--- @param visualizer SmartMotionVisualizerModuleEntry
--- @return fun(ctx: SmartMotionContext, cfg: SmartMotionConfig, motion_state: SmartMotionMotionState): nil
function M._build_pipeline(collector, extractor, filter, visualizer)
	local function run_pipeline(ctx, cfg, motion_state)
		utils.reset_motion(ctx, cfg, motion_state)
		M._prepare_pipeline(ctx, cfg, motion_state, collector, extractor, filter)
		visualizer.run(ctx, cfg, motion_state)
	end

	return run_pipeline
end

function M._handle_exit(ctx, cfg, motion_state, exit_type, action, visualizer)
	if exit_type == SEARCH_EXIT_TYPE.EARLY_EXIT then
		return
	end

	if exit_type == SEARCH_EXIT_TYPE.DIRECT_HINT or exit_type == SEARCH_EXIT_TYPE.AUTO_SELECT then
		if motion_state.selected_jump_target then
			action.run(ctx, cfg, motion_state)
		end
	elseif exit_type == SEARCH_EXIT_TYPE.CONTINUE_TO_SELECTION then
		visualizer.run(ctx, cfg, motion_state)
		selection.wait_for_hint_selection(ctx, cfg, motion_state)

		if motion_state.selected_jump_target then
			action.run(ctx, cfg, motion_state)
		end
	end
end

return M
