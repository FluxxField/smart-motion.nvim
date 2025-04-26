local M = {}

--- Merges multiple action modules into one
--- @param actions SmartMotionActionModuleEntry[]
--- @return SmartMotionActionModuleEntry
function M.merge(actions)
	return function(ctx, cfg, motion_state)
		for _, action in ipairs(actions) do
			action.run(ctx, cfg, motion_state)
		end
	end
end

return M
