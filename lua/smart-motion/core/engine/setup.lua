local exit = require("smart-motion.core.events.exit")
local utils = require("smart-motion.utils")
local consts = require("smart-motion.consts")
local state = require("smart-motion.core.state")
local module_loader = require("smart-motion.utils.module_loader")
local log = require("smart-motion.core.log")

local EXIT_TYPE = consts.EXIT_TYPE

local M = {}

function M.run(trigger_key)
	local motion = require("smart-motion.motions").get_by_key(trigger_key)
	exit.throw_if(not motion, EXIT_TYPE.EARLY_EXIT)

	local ctx, cfg, motion_state = utils.prepare_motion()
	exit.throw_if(not ctx or not cfg or not motion_state, EXIT_TYPE.EARLY_EXIT)

	-- Attach motion data to motion_state
	motion_state.motion = motion

	local modules = module_loader.get_modules(ctx, cfg, motion_state)

	-- The modules might have motion_state they would like to set
	motion_state = state.merge_motion_state(motion_state, motion, modules)

	return ctx, cfg, motion_state
end

return M
