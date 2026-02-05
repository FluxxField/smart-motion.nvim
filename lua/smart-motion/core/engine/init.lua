local exit_event = require("smart-motion.core.events.exit")
local setup = require("smart-motion.core.engine.setup")
local handle_exit = require("smart-motion.core.engine.exit")
local flow_state = require("smart-motion.core.flow_state")
local pipeline = require("smart-motion.core.engine.pipeline")
local consts = require("smart-motion.consts")
local highlight = require("smart-motion.core.highlight")
local loop = require("smart-motion.core.engine.loop")
local log = require("smart-motion.core.log")
local infer = require("smart-motion.core.engine.infer")
local utils = require("smart-motion.utils")

local EXIT_TYPE = consts.EXIT_TYPE

local M = {}

--- @param trigger_key string
--- @param opts? { count_select?: integer }
function M.run(trigger_key, opts)
	local ctx, cfg, motion_state

	local exit_type = exit_event.wrap(function()
		ctx, cfg, motion_state = setup.run(trigger_key)

		if opts and opts.count_select then
			motion_state.count_select = opts.count_select
		end

		infer.run(ctx, cfg, motion_state)

		if flow_state.evaluate_flow_at_motion_start() then
			pipeline.run(ctx, cfg, motion_state)
			exit_event.throw_if(motion_state.selected_jump_target, EXIT_TYPE.AUTO_SELECT)
		end

		highlight.dim_background(ctx, cfg, motion_state)

		loop.run(ctx, cfg, motion_state)
	end)

	handle_exit.run(ctx, cfg, motion_state, exit_type)
	utils.reset_motion(ctx, cfg, motion_state)
end

return M
