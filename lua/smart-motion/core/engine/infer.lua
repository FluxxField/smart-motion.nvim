local exit = require("smart-motion.core.events.exit")
local consts = require("smart-motion.consts")
local module_loader = require("smart-motion.utils.module_loader")
local targets = require("smart-motion.core.targets")
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

	local modules = module_loader.get_modules(ctx, cfg, motion_state, { "extractor", "action" })

	if not modules.extractor or not modules.extractor.run then
		if motion_key == motion_state.motion.trigger_key then
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

		-- Feed trigger key with noremap to get native operator behavior (avoids recursion),
		-- but feed the motion key with remap so user/plugin "o" mode keymaps fire (e.g. R).
		vim.api.nvim_feedkeys(motion_state.motion.trigger_key, "n", false)
		vim.api.nvim_feedkeys(motion_key, "m", false)
		exit.throw(EXIT_TYPE.EARLY_EXIT)
	end

end

return M
