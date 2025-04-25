local M = {}

--- @param actions SmartMotionActionModuleEntry[]
--- @return SmartMotionActionModuleEntry
function M.merge(filters)
	return function(ctx, cfg, motion_state, opts)
		for _, filter in ipairs(filters) do
			filter.run(ctx, cfg, motion_state, opts)
		end
	end
end

return M
