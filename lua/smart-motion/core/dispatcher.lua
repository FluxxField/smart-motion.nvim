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
	collectors = collectors,
	extractors = extractors,
	filters = filters,
	visualizers = visualizers,
	wrappers = wrappers,
}

local function prepare_pipeline(ctx, cfg, motion_state, collector, extractor)
	local lines_gen = collector.run()
	if not lines_gen then
		return
	end

	local target_gen = extractor.run(lines_gen)
	if not target_gen then
		return
	end

	targets.get_jump_targets(ctx, cfg, motion_state, target_gen)
	state.finalize_motion_state(motion_state)
end

local function build_pipeline(collector, extractor, filter, visualizer)
	return function(ctx, cfg, motion_state)
		prepare_pipeline(ctx, cfg, motion_state, collector, extractor)

		filter.run(ctx, cfg, motion_state)
		visualizer.run(ctx, cfg, motion_state)
	end
end

local M = {}

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
	local collector = collectors.get_by_name(pipeline.collector)
	local extractor = extractors.get_by_name(pipeline.extractor)
	local visualizer = visualizers.get_by_name(pipeline.visualizer)

	-- Validate the action
	local action = actions.get_by_name(motion.action)
	if not validation.validate_module("action", action, trigger_key) then
		return
	end

	-- Validate the filter, fallback to default
	local filter = filters.get_by_name(pipeline.filter or "default_filter")
	if not filter or not filter.run then
		filter = filters.get_by_name("default_filter")
	end

	local direction = motion.direction or consts.DIRECTION.AFTER_CURSOR
	local hint_position = (visualizer and visualizer.hint_position) or consts.HINT_POSITION.START

	local ctx, cfg, motion_state = utils.prepare_motion(direction, hint_position, consts.TARGET_TYPES.WORD, true)

	if not ctx or not cfg or not motion_state then
		log.error("Failde to prepare motion - aborting")
		return
	end

	utils.reset_motion(ctx, cfg, motion_state)

	if flow_state.evaluate_flow_at_motion_start() then
		prepare_pipeline(ctx, cfg, motion_state, collector, extractor)

		if motion_state.selected_jump_target then
			action.run(ctx, cfg, motion_state)
			utils.reset_motion(ctx, cfg, motion_state)

			return
		end
	end

	-- Validate the Wrapper, fallback to default
	local wrapper = wrappers.get_by_name(motion.pipeline_wrapper or "default_wrapper")
	if not wrapper or not wrapper.run then
		wrapper = wrappers.get_by_name("default_wrapper")
	end

	local run_pipeline = build_pipeline(collector, extractor, filter, visualizer)
	wrapper.run(run_pipeline, ctx, cfg, motion_state)

	selection.wait_for_hint_selection(ctx, cfg, motion_state)

	if motion_state.selected_jump_target then
		action.run(ctx, cfg, motion_state)
	end

	utils.reset_motion(ctx, cfg, motion_state)
end

return M
