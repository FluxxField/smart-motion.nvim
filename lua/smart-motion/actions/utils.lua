local M = {}

--- Merges multiple action modules into one
--- @param actions SmartMotionActionModuleEntry[]
--- @return SmartMotionActionModuleEntry
function M.merge(actions)
	return function(ctx, cfg, motion_state, opts)
		for _, action in ipairs(actions) do
			action.run(ctx, cfg, motion_state, opts)
		end
	end
end

return M
