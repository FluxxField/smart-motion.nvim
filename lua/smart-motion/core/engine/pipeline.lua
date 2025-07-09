local exit = require("smart-motion.core.events.exit")
local consts = require("smart-motion.consts")
local targets = require("smart-motion.core.targets")
local state = require("smart-motion.core.state")
local module_loader = require("smart-motion.utils.module_loader")
local log = require("smart-motion.core.log")

local EXIT_TYPE = consts.EXIT_TYPE

local M = {}

--- Prepares the pipeline by collecting and extracting motion targets.
--- @param ctx SmartMotionContext
--- @param cfg SmartMotionConfig
--- @param motion_state SmartMotionMotionState
function M.run(ctx, cfg, motion_state)
	local modules =
		module_loader.get_modules(ctx, cfg, motion_state, { "collector", "extractor", "modifier", "filter" })

	local collector_generator = modules.collector.run()
	exit.throw_if(not collector_generator, EXIT_TYPE.EARLY_EXIT)

	local extractor_generator = modules.extractor.run(collector_generator)
	exit.throw_if(not extractor_generator, EXIT_TYPE.EARLY_EXIT)

	local modifier_generator = modules.modifier.run(extractor_generator)
	exit.throw_if(not modifier_generator, EXIT_TYPE.EARLY_EXIT)

	local filter_generator = modules.filter.run(modifier_generator)
	exit.throw_if(not filter_generator)

	targets.get_targets(ctx, cfg, motion_state, filter_generator)
	state.finalize_motion_state(ctx, cfg, motion_state)
end

return M
