local M = {}

--- @param ... fun(ctx: SmartMotionContext, targets: SmartMotionTarget[]): SmartMotionTarget[]
--- @return fun(ctx: SmartMotionContext, targets: SmartMotionTarget[]): SmartMotionTarget[]
function M.merge_filters(...)
	local filters = { ... }

	return function(ctx, cfg, motion_state, opts)
		for _, filter in ipairs(filters) do
			filter.run(ctx, cfg, motion_state, opts)
		end
	end
end

return M
