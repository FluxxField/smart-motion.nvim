local exit = require("smart-motion.core.events.exit")
local utils = require("smart-motion.utils")
local consts = require("smart-motion.consts")
local state = require("smart-motion.core.state")
local module_loader = require("smart-motion.utils.module_loader")
local log = require("smart-motion.core.log")
local filetype_dispatch = require("smart-motion.core.engine.filetype_dispatch")

local EXIT_TYPE = consts.EXIT_TYPE

local M = {}

function M.run(trigger_key)
	local motion = require("smart-motion.motions").get_by_key(trigger_key)
	exit.throw_if(not motion, EXIT_TYPE.EARLY_EXIT)

	local ctx, cfg, motion_state = utils.prepare_motion()
	exit.throw_if(not ctx or not cfg or not motion_state, EXIT_TYPE.EARLY_EXIT)

	-- Shallow copy so infer mutations don't leak to the registry entry
	motion_state.motion = vim.tbl_extend("force", {}, motion)

	filetype_dispatch.apply(ctx, motion_state)

	-- Set motion_key to the trigger key for direct motions.
	-- For operator motions (infer=true), infer.run will override this with the composed key.
	motion_state.motion_key = trigger_key

	-- For infer motions (d, y, c), skip loading the extractor here — infer.run()
	-- will determine the correct extractor from the composable motion (e.g. w, b, e).
	local load_keys = nil
	if motion_state.motion.infer then
		load_keys = { "collector", "modifier", "filter", "visualizer", "action" }
	end
	local modules = module_loader.get_modules(ctx, cfg, motion_state, load_keys)

	-- The modules might have motion_state they would like to set
	-- Use motion_state.motion (the shallow copy, possibly modified by filetype_dispatch)
	-- instead of the original registry entry, so overridden metadata is preserved.
	motion_state = state.merge_motion_state(motion_state, motion_state.motion, modules)

	-- Apply any per-mode motion_state override (e.g. o = { exclude_target = true })
	-- Normalize ctx.mode to keymap-style single char: "no" -> "o", "v"/"V" -> "x", etc.
	if motion_state.motion.per_mode_motion_state then
		local mode_key = ctx.mode:find("o") and "o" or ctx.mode:sub(1, 1)
		local mode_override = motion_state.motion.per_mode_motion_state[mode_key]
			or motion_state.motion.per_mode_motion_state[ctx.mode]
		if mode_override then
			motion_state = vim.tbl_deep_extend("force", motion_state, mode_override)
		end
	end

	return ctx, cfg, motion_state
end

--- Set up engine context from a textobject entry (no registry lookup).
--- Used by i/a keymaps in visual and operator-pending modes.
--- @param textobject SmartMotionTextobjectEntry
--- @param textobject_key string "inside" or "around"
function M.run_with_textobject(textobject, textobject_key)
	local ctx, cfg, motion_state = utils.prepare_motion()
	exit.throw_if(not ctx or not cfg or not motion_state, EXIT_TYPE.EARLY_EXIT)

	-- Build a motion entry from the textobject
	local motion = {
		name = textobject_key .. "_" .. (textobject.key or "textobject"),
		trigger_key = textobject_key .. (textobject.key or ""),
		collector = textobject.collector,
		extractor = textobject.extractor,
		modifier = textobject.modifier or "weight_distance",
		filter = textobject.filter or "filter_visible",
		visualizer = textobject.visualizer or "hint_start",
		action = textobject.action or "textobject_select",
		metadata = vim.deepcopy(textobject.metadata or {}),
	}

	motion_state.motion = motion
	motion_state.motion_key = motion.trigger_key

	-- Load modules
	local modules = module_loader.get_modules(ctx, cfg, motion_state)
	motion_state = state.merge_motion_state(motion_state, motion, modules)

	-- Merge base motion_state from textobject
	if textobject.metadata and textobject.metadata.motion_state then
		for k, v in pairs(textobject.metadata.motion_state) do
			motion_state[k] = v
		end
	end

	-- Merge prefix-specific overrides (inside/around)
	local overrides = textobject[textobject_key]
	if not overrides then
		overrides = textobject[textobject.default or "around"]
	end
	if overrides then
		for k, v in pairs(overrides) do
			-- Pipeline overrides: swap collector/extractor for this prefix
			if k == "_collector_override" then
				motion.collector = v
			elseif k == "_extractor_override" then
				motion.extractor = v
			else
				motion_state[k] = v
			end
		end
	end

	return ctx, cfg, motion_state
end

return M
