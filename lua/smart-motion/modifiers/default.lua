local log = require("smart-motion.core.log")

---@type SmartMotionModifierModuleEntry
local M = {}

function M.run(input_gen)
	return coroutine.create(function(ctx, cfg, motion_state)
		while true do
			local ok, target = coroutine.resume(input_gen, ctx, cfg, motion_state)

			if not ok or not target then
				break
			end

			coroutine.yield(target)
		end
	end)
end

M.metadata = {
	label = "Default Passthrough",
	description = "Yields all targets unchanged",
}

return M
