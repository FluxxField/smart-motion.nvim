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

	-- Shallow copy so infer mutations don't leak to the registry entry
	motion_state.motion = vim.tbl_extend("force", {}, motion)

	-- Set motion_key to the trigger key for direct motions.
	-- For operator motions (infer=true), infer.run will override this with the composed key.
	motion_state.motion_key = trigger_key

	local modules = module_loader.get_modules(ctx, cfg, motion_state)

	-- The modules might have motion_state they would like to set
	motion_state = state.merge_motion_state(motion_state, motion, modules)

	-- Apply any per-mode motion_state override (e.g. o = { exclude_target = true })
	-- Normalize ctx.mode to keymap-style single char: "no" -> "o", "v"/"V" -> "x", etc.
	if motion.per_mode_motion_state then
		local mode_key = ctx.mode:find("o") and "o" or ctx.mode:sub(1, 1)
		local mode_override = motion.per_mode_motion_state[mode_key]
			or motion.per_mode_motion_state[ctx.mode]
		if mode_override then
			motion_state = vim.tbl_deep_extend("force", motion_state, mode_override)
		end
	end

	return ctx, cfg, motion_state
end

return M
