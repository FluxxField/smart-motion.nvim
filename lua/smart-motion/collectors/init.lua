local lines = require("smart-motion.collectors.lines")

---@type SmartMotionRegistry<SmartMotionCollectorModuleEntry>
local collectors = require("smart-motion.core.registry")("collectors")

--- @type table<string, SmartMotionCollectorModuleEntry>
local collector_entries = {
	lines = {
		keys = { "l" },
		run = lines.run,
		metadata = {
			label = "Line Collector",
			description = "Collects full lines forward or backward from the cursor",
		},
	},
}

collectors.register_many(collector_entries)

return collectors
