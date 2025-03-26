local log = require("smart-motion.core.log")
local consts = require("smart-motion.consts")
local utils = require("smart-motion.utils")
local targets = require("smart-motion.core.targets")
local state = require("smart-motion.core.state")
local flow_state = require("smart-motion.core.flow-state")
local selection = require("smart-motion.core.selection")
local validation = require("smart-motion.core.validation")

local collectors = require("smart-motion.collectors")
local extractors = require("smart-motion.extractors")
local filters = require("smart-motion.filters")
local visualizers = require("smart-motion.visualizers")
local wrappers = require("smart-motion.pipeline_wrappers")
local actions = require("smart-motion.actions")

local registries = {
	actions = actions,
	collectors = collectors,
	extractors = extractors,
	filters = filters,
	visualizers = visualizers,
	wrappers = wrappers,
}

local M = {}

--
-- Trigger Motion
--
function M.trigger_motion(trigger_key)
	local motion = require("smart-motion.motions").get_by_key(trigger_key)
	if not motion then
		log.warn("No motion found for key: " .. trigger_key)
		return
	end

	-- Validate the pipeline
	if not validation.validate_pipeline(motion, trigger_key, registries) then
		return
	end

	local pipeline = motion.pipeline
	local collector = registries.collectors.get_by_name(pipeline.collector)
	local extractor = registries.extractors.get_by_name(pipeline.extractor)
	local visualizer = registries.visualizers.get_by_name(pipeline.visualizer)

	-- Validate the action
	local action = actions.get_by_name(motion.action)
	if not validation.validate_module("action", action, trigger_key) then
		return
	end

	-- Validate the filter, fallback to default
	local filter = registries.filters.get_by_name(pipeline.filter or "default")
	if not filter or not filter.run then
		filter = registries.filters.get_by_name("default")
	end

	local direction = motion.direction or consts.DIRECTION.AFTER_CURSOR
	local hint_position = (visualizer and visualizer.hint_position) or consts.HINT_POSITION.START

	local ctx, cfg, motion_state = utils.prepare_motion(direction, hint_position, extractor.name, true)

	if not ctx or not cfg or not motion_state then
		log.error("Failde to prepare motion - aborting")
		return
	end

	utils.reset_motion(ctx, cfg, motion_state)

	if flow_state.evaluate_flow_at_motion_start() then
		M._prepare_pipeline(ctx, cfg, motion_state, collector, extractor, {})

		if motion_state.selected_jump_target then
			action.run(ctx, cfg, motion_state, {})
			utils.reset_motion(ctx, cfg, motion_state)

			return
		end
	end

	-- Validate the Wrapper, fallback to default
	local wrapper = registries.wrappers.get_by_name(motion.pipeline_wrapper or "default")
	if not wrapper or not wrapper.run then
		wrapper = registries.wrappers.get_by_name("default")
	end

	local run_pipeline = M._build_pipeline(collector, extractor, filter, visualizer)
	local exit = wrapper.run(run_pipeline, ctx, cfg, motion_state, action)

	if exit then
		utils.reset_motion(ctx, cfg, motion_state)
		return
	end

	selection.wait_for_hint_selection(ctx, cfg, motion_state)

	if motion_state.selected_jump_target then
		action.run(ctx, cfg, motion_state, opts)
	end

	utils.reset_motion(ctx, cfg, motion_state)
end

--
-- Trigger Action
--
function M.trigger_action(trigger_key)
	local motion = require("smart-motion.motions").get_by_key(trigger_key)
	local action = registries.actions.get_by_key(trigger_key)
	if not validation.validate_module("action", action, trigger_key) then
		return
	end

	local ok, motion_char = pcall(vim.fn.getchar)
	if not ok then
		log.warn("Failed to get motion character")
		return
	end

	local motion_key = vim.fn.nr2char(motion_char)
	local extractor = extractors.get_by_key(motion_key)

	if not extractor then
		log.warn("No extractor mapped for key: " .. motion_key)
		return
	end

	local pipeline = motion.pipeline
	local collector = registries.collectors.get_by_name(pipeline.collector)
	local visualizer = registries.visualizers.get_by_name(pipeline.visualizer)

	-- Validate the filter, fallback to default
	local filter = registries.filters.get_by_name(pipeline.filter or "default")
	if not filter or not filter.run then
		filter = registries.filters.get_by_name("default")
	end

	local direction = motion.direction or consts.DIRECTION.AFTER_CURSOR
	local hint_position = (visualizer and visualizer.hint_position) or consts.HINT_POSITION.START

	local ctx, cfg, motion_state = utils.prepare_motion(direction, hint_position, extractor.name, true)

	if not ctx or not cfg or not motion_state then
		log.error("Failde to prepare motion - aborting")
		return
	end

	utils.reset_motion(ctx, cfg, motion_state)

	if flow_state.evaluate_flow_at_motion_start() then
		M._prepare_pipeline(ctx, cfg, motion_state, collector, extractor, {})

		if motion_state.selected_jump_target then
			action.run(ctx, cfg, motion_state, {})
			utils.reset_motion(ctx, cfg, motion_state)

			return
		end
	end

	-- Validate the Wrapper, fallback to default
	local wrapper = registries.wrappers.get_by_name(motion.pipeline_wrapper or "default")
	if not wrapper or not wrapper.run then
		wrapper = registries.wrappers.get_by_name("default")
	end

	local run_pipeline = M._build_pipeline(collector, extractor, filter, visualizer)
	local exit = wrapper.run(run_pipeline, ctx, cfg, motion_state, action)
	if exit then
		utils.reset_motion(ctx, cfg, motion_state)
		return
	end

	selection.wait_for_hint_selection(ctx, cfg, motion_state)

	if motion_state.selected_jump_target then
		action.run(ctx, cfg, motion_state, {})
	end

	utils.reset_motion(ctx, cfg, motion_state)
end

--
-- _prepare_pipeline
--
function M._prepare_pipeline(ctx, cfg, motion_state, collector, extractor, opts)
	local lines_gen = collector.run(opts)
	if not lines_gen then
		return
	end

	local extractor_gen = extractor.run(lines_gen, opts)
	if not extractor_gen then
		return
	end

	targets.get_jump_targets(ctx, cfg, motion_state, extractor_gen)
	state.finalize_motion_state(motion_state)
end

--
-- _build_pipeline
--
function M._build_pipeline(collector, extractor, filter, visualizer)
	local function run_pipeline(ctx, cfg, motion_state, opts)
		utils.reset_motion(ctx, cfg, motion_state)

		M._prepare_pipeline(ctx, cfg, motion_state, collector, extractor, opts)

		filter.run(ctx, cfg, motion_state, opts)
		visualizer.run(ctx, cfg, motion_state, opts)
	end

	return run_pipeline
end

return M
