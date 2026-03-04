local log = require("smart-motion.core.log")

local M = {}

--- Applies filetype-specific overrides to the motion definition.
--- Modifies motion_state.motion in place (the shallow copy, not the registry).
---@param ctx SmartMotionContext
---@param motion_state SmartMotionMotionState
function M.apply(ctx, motion_state)
	local motion = motion_state.motion
	if not motion or not motion.metadata then
		return
	end

	local ms = motion.metadata.motion_state
	if not ms or not ms.filetype_overrides then
		return
	end

	local filetype = vim.bo[ctx.bufnr].filetype
	if not filetype or filetype == "" then
		return
	end

	local override = ms.filetype_overrides[filetype]
	if not override then
		return
	end

	log.debug(string.format("filetype_dispatch: applying override for filetype '%s'", filetype))

	-- Swap pipeline module references
	for _, key in ipairs({ "collector", "extractor", "modifier", "filter", "visualizer", "action" }) do
		if override[key] then
			motion[key] = override[key]
		end
	end

	-- Deep-merge motion_state overrides into motion.metadata.motion_state
	if override.motion_state then
		motion.metadata.motion_state = vim.tbl_deep_extend("force", ms, override.motion_state)
	end

	-- Remove consumed overrides so they don't leak through the pipeline
	motion.metadata.motion_state.filetype_overrides = nil
end

return M
