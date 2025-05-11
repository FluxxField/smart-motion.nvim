local log = require("smart-motion.core.log")

local M = {}

--- Merge multiple generator-based filters into one SmartMotionFilterModuleEntry
---@param filters (fun(input_gen: thread): thread)[]
---@return SmartMotionFilterModuleEntry
function M.merge(filters)
	return function(ctx, cfg, motion_state, data)
		for _, run_fn in ipairs(filters) do
			local ok, result = pcall(run_fn, ctx, cfg, motion_state, data)

			if not ok then
				log.debug("merge_filters: failed to run filter: " .. tostring(result))
				break
			end

			if result == nil or type(result) == "string" then
				return result
			end

			data = result
		end

		return data
	end
end

return M
