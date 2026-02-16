local consts = require("smart-motion.consts")
local selection = require("smart-motion.core.selection")
local setup = require("smart-motion.core.engine.setup")
local module_loader = require("smart-motion.utils.module_loader")

local EXIT_TYPE = consts.EXIT_TYPE

local M = {}

function M.run(ctx, cfg, motion_state, exit_type)
	if exit_type == EXIT_TYPE.EARLY_EXIT then
		return
	end

	local modules = module_loader.get_modules(ctx, cfg, motion_state, { "visualizer", "action" })

	if exit_type == EXIT_TYPE.CONTINUE_TO_SELECTION then
		motion_state.is_searching_mode = false
		-- Only render labels if they weren't already assigned during the search loop.
		-- Re-rendering here would use the full (unfiltered) key pool, which produces
		-- different label assignments than the conflict-filtered labels the user already saw.
		if vim.tbl_isempty(motion_state.assigned_hint_labels) then
			modules.visualizer.run(ctx, cfg, motion_state)
		end
		selection.wait_for_hint_selection(ctx, cfg, motion_state)
	end

	if motion_state.selected_jump_target then
		if ctx.mode and ctx.mode:find("o") and not motion_state.is_textobject then
			require("smart-motion.actions.jump").run(ctx, cfg, motion_state)
		else
			modules.action.run(ctx, cfg, motion_state)
		end
	end
end

return M
