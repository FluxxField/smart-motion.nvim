local log = require("smart-motion.core.log")

local M = {}

--- Merge multiple generator-based filters into one SmartMotionFilterModuleEntry
---@param filters (fun(input_gen: thread): thread)[]
---@return SmartMotionFilterModuleEntry
function M.merge(filters)
	function run(input_gen)
		return coroutine.create(function(ctx, cfg, motion_state)
			while true do
				local ok, target = coroutine.resume(input_gen, ctx, cfg, motion_state)
				if not ok or not target then
					break
				end

				local intermediate = target
				local accepted = true

				for _, filter in ipairs(filters) do
					local filter_gen = filter.run(coroutine.create(function()
						coroutine.yield(intermediate)
					end))

					local passed, filtered = coroutine.resume(filter_gen, ctx, cfg, motion_state)

					if not passed or not filtered then
						accepted = false
						break
					end

					intermediate = filtered
				end

				if accepted then
					coroutine.yield(intermediate)
				end
			end
		end)
	end

	return run
end

return M
