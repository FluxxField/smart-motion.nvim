local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

---@type SmartMotionCollectorModuleEntry
local M = {}

--- Collects lines from buffer based on motion direction.
--- @return thread A coroutine generator yielding SmartMotionLineData objects
function M.run()
	local history = require("smart-motion.core.history")

	log.info("history: " .. tostring(#history.entries))

	return coroutine.create(function(ctx, cfg, motion_state)
		for _, entry in ipairs(history.entries) do
			coroutine.yield(vim.tbl_extend("force", entry, {
				type = "history",
			}))
		end
	end)
end

M.metadata = {
	label = "Motion History Collector",
	description = "Collects entries from the smart-motion history",
}

return M
