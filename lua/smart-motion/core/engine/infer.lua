local exit = require("smart-motion.core.events.exit")
local consts = require("smart-motion.consts")
local module_loader = require("smart-motion.utils.module_loader")
local targets = require("smart-motion.core.targets")
local state = require("smart-motion.core.state")
local key_resolver = require("smart-motion.core.key_resolver")
local log = require("smart-motion.core.log")

local EXIT_TYPE = consts.EXIT_TYPE
local RESOLVE_TYPE = key_resolver.RESOLVE_TYPE

local M = {}

--- Apply a resolved textobject to the current motion_state.
--- Copies pipeline components from the textobject and merges
--- the appropriate motion_state overrides (inside/around/surround).
--- @param motion_state SmartMotionMotionState
--- @param result table Resolve result from key_resolver
local function apply_textobject(motion_state, result)
	local textobject = result.textobject
	local motion = motion_state.motion

	-- Copy pipeline components from textobject
	if textobject.collector then motion.collector = textobject.collector end
	if textobject.extractor then motion.extractor = textobject.extractor end
	if textobject.filter then motion.filter = textobject.filter end
	if textobject.visualizer then motion.visualizer = textobject.visualizer end
	if textobject.modifier then motion.modifier = textobject.modifier end

	-- Merge base motion_state from textobject
	if textobject.metadata and textobject.metadata.motion_state then
		for k, v in pairs(textobject.metadata.motion_state) do
			motion_state[k] = v
		end
	end

	-- Merge the prefix-specific motion_state overrides (inside/around/surround)
	local textobject_key = result.textobject_key
	local overrides = textobject[textobject_key]
	if not overrides then
		-- No overrides for this key, try the default
		local default_key = textobject.default or "around"
		overrides = textobject[default_key]
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
end

--- Apply a resolved composable motion to the current motion_state.
--- Copies pipeline components and conditionally copies action.
--- @param motion_state SmartMotionMotionState
--- @param result table Resolve result from key_resolver
local function apply_composable(motion_state, result)
	local target_motion = result.composable
	local motion = motion_state.motion

	if target_motion.extractor then motion.extractor = target_motion.extractor end
	if target_motion.filter then motion.filter = target_motion.filter end
	if target_motion.visualizer then motion.visualizer = target_motion.visualizer end
	if target_motion.collector then motion.collector = target_motion.collector end

	-- Only copy action from composable motions that explicitly request it
	-- (e.g. surround motions). Standard composable motions (w, b, e) have
	-- action = "jump_centered" which is their standalone default and should
	-- NOT override the operator's action (d→delete_jump, y→yank_jump, etc.).
	if target_motion.override_action and target_motion.action then
		motion.action = target_motion.action
	end

	-- Merge target motion's metadata into motion_state
	if target_motion.metadata and target_motion.metadata.motion_state then
		for k, v in pairs(target_motion.metadata.motion_state) do
			motion_state[k] = v
		end
	end
end

--- Handle the fallback case when no extractor was resolved.
--- Checks for line actions (dd, yy), treesitter search (R),
--- and feeds remaining keys back to vim for native handling.
--- @param ctx SmartMotionContext
--- @param cfg SmartMotionConfig
--- @param motion_state SmartMotionMotionState
--- @param motion_key string
--- @param modules table
local function handle_no_extractor(ctx, cfg, motion_state, motion_key, modules)
	-- Line action: operator key repeated (dd, yy, cc)
	if motion_key == motion_state.motion.action_key then
		motion_state.target_type = "lines"

		local action_name = modules.action.name:gsub("_jump$", "")
		local line_action =
			module_loader.get_module_by_name(ctx, cfg, motion_state, "actions", action_name .. "_line")

		if line_action and line_action.run then
			motion_state.selected_jump_target = targets.get_target_under_cursor(ctx, cfg, motion_state)

			if motion_state.selected_jump_target then
				line_action.run(ctx, cfg, motion_state)
				exit.throw(EXIT_TYPE.EARLY_EXIT)
			end
		end
	end

	-- Special case: R (treesitter search) called from operator context (yR, dR, cR).
	if motion_key == "R" then
		require("smart-motion.actions.treesitter_search").run(nil, motion_state.motion.action_key)
		exit.throw(EXIT_TYPE.EARLY_EXIT)
	end

	-- Feed trigger key with noremap to get native operator behavior (avoids recursion),
	-- but feed the motion key with remap so user/plugin "o" mode keymaps fire.
	local resolved_trigger = vim.api.nvim_replace_termcodes(motion_state.motion.trigger_key, true, false, true)
	vim.api.nvim_feedkeys(resolved_trigger, "n", false)
	vim.api.nvim_feedkeys(motion_key, "m", false)
	exit.throw(EXIT_TYPE.EARLY_EXIT)
end

function M.run(ctx, cfg, motion_state)
	if not motion_state.motion.infer then
		return
	end

	-- Resolve key sequence: textobject (i/a prefix), composable, or fallback
	local result = key_resolver.resolve(motion_state)
	exit.throw_if(not result, EXIT_TYPE.EARLY_EXIT)

	local motion_key = result.motion_key
	motion_state.motion_key = motion_key
	motion_state.target_type = consts.TARGET_TYPES_BY_KEY[motion_key]

	if result.type == RESOLVE_TYPE.TEXTOBJECT then
		apply_textobject(motion_state, result)
	elseif result.type == RESOLVE_TYPE.COMPOSABLE then
		apply_composable(motion_state, result)
		-- Carry textobject_key from i/a prefix if present (e.g. ysaw → around + w composable)
		if result.textobject_key then
			motion_state.textobject_key = result.textobject_key
		end
	elseif result.type == RESOLVE_TYPE.FALLBACK then
		-- No composable or textobject found — feed back to vim
		local resolved_trigger = vim.api.nvim_replace_termcodes(motion_state.motion.trigger_key, true, false, true)
		vim.api.nvim_feedkeys(resolved_trigger, "n", false)
		vim.api.nvim_feedkeys(motion_key, "m", false)
		exit.throw(EXIT_TYPE.EARLY_EXIT)
	end

	-- Load modules with updated pipeline config
	local infer_keys = { "action", "visualizer", "filter" }
	if motion_state.motion.extractor then
		table.insert(infer_keys, 1, "extractor")
	end
	local modules = module_loader.get_modules(ctx, cfg, motion_state, infer_keys)

	-- Merge inferred module metadata into motion_state (defaults only —
	-- don't overwrite values already set by the operator/motion config)
	for _, module in pairs(modules) do
		if state.module_has_motion_state(module) then
			for k, v in pairs(module.metadata.motion_state) do
				if motion_state[k] == nil then
					motion_state[k] = v
				end
			end
		end
	end

	if not modules.extractor or not modules.extractor.run then
		handle_no_extractor(ctx, cfg, motion_state, motion_key, modules)
	end
end

return M
