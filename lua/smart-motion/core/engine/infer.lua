local exit = require("smart-motion.core.events.exit")
local consts = require("smart-motion.consts")
local module_loader = require("smart-motion.utils.module_loader")
local targets = require("smart-motion.core.targets")
local state = require("smart-motion.core.state")
local utils = require("smart-motion.utils")
local log = require("smart-motion.core.log")

local EXIT_TYPE = consts.EXIT_TYPE

local M = {}

function M.run(ctx, cfg, motion_state)
	if not motion_state.motion.infer then
		return
	end

	local ok, motion_key = exit.safe(pcall(vim.fn.getchar))
	exit.throw_if(not ok, EXIT_TYPE.EARLY_EXIT)

	motion_key = type(motion_key) == "number" and vim.fn.nr2char(motion_key) or motion_key
	exit.throw_if(motion_key == "\027", EXIT_TYPE.EARLY_EXIT)

	motion_state.motion_key = motion_key
	motion_state.target_type = consts.TARGET_TYPES_BY_KEY[motion_key]

	-- Motion-based inference: look up a composable motion by motion_key.
	-- This allows any registered composable motion (w, b, e, j, k, s, f, etc.)
	-- to automatically work as a target for operators (d, y, c, p).
	local motions_reg = require("smart-motion.motions")
	local target_motion = motions_reg.get_by_key(motion_key)

	if target_motion and target_motion.composable then
		local motion = motion_state.motion
		if target_motion.extractor then motion.extractor = target_motion.extractor end
		if target_motion.filter then motion.filter = target_motion.filter end
		if target_motion.visualizer then motion.visualizer = target_motion.visualizer end
		if target_motion.collector then motion.collector = target_motion.collector end

		-- Merge target motion's metadata into motion_state
		if target_motion.metadata and target_motion.metadata.motion_state then
			for k, v in pairs(target_motion.metadata.motion_state) do
				motion_state[k] = v
			end
		end
	end

	local modules = module_loader.get_modules(ctx, cfg, motion_state, { "extractor", "action" })

	-- Merge inferred module metadata into motion_state (setup.run couldn't do this
	-- because the extractor wasn't known yet before infer resolved the motion key)
	for _, module in pairs(modules) do
		if state.module_has_motion_state(module) then
			for k, v in pairs(module.metadata.motion_state) do
				motion_state[k] = v
			end
		end
	end

	if not modules.extractor or not modules.extractor.run then
		if motion_key == motion_state.motion.action_key then
			motion_state.target_type = "lines"

			-- NOTE: We might need to set motion_state here if actions ever need to set it
			local line_action =
				module_loader.get_module_by_name(ctx, cfg, motion_state, "actions", modules.action.name .. "_line")

			if line_action and line_action.run then
				motion_state.selected_jump_target = targets.get_target_under_cursor(ctx, cfg, motion_state)

				if motion_state.selected_jump_target then
					line_action.run(ctx, cfg, motion_state)
				end
			end
		end

		-- Special case: R (treesitter search) called from operator context (yR, dR, cR).
		-- Call treesitter_search directly with the operator instead of feeding keys
		-- through operator-pending mode, which has timing issues with vim.schedule.
		if motion_key == "R" then
			require("smart-motion.actions.treesitter_search").run(nil, motion_state.motion.action_key)
			exit.throw(EXIT_TYPE.EARLY_EXIT)
		end

		-- Feed trigger key with noremap to get native operator behavior (avoids recursion),
		-- but feed the motion key with remap so user/plugin "o" mode keymaps fire (e.g. R).
		local resolved_trigger = vim.api.nvim_replace_termcodes(motion_state.motion.trigger_key, true, false, true)
		vim.api.nvim_feedkeys(resolved_trigger, "n", false)
		vim.api.nvim_feedkeys(motion_key, "m", false)
		exit.throw(EXIT_TYPE.EARLY_EXIT)
	end

end

return M
