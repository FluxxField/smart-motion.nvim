local log = require("smart-motion.core.log")

local M = {}

--- Merge multiple generator-based filters into one SmartMotionFilterModuleEntry
---@param filters (fun(input_gen: thread): thread)[]
---@return SmartMotionFilterModuleEntry
function M.merge(filters)
	function run(ctx, cfg, motion_state, target)
		for _, filter in ipairs(filters) do
			local ok, result = pcall(filter.run, ctx, cfg, motion_state, target)

			if not ok then
				break
			end

			if result == nil or type(result) == "string" then
				return result
			end

			target = result
		end

		return target
	end

	return run
end

return M
