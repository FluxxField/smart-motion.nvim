local lines = require("smart-motion.collectors.lines")
local collectors = require("smart-motion.core.registry")("collectors")

collectors.register_many({
	lines = {
		keys = { "l" },
		run = lines.init,
		metadata = {
			label = "Line Collector",
			description = "Collects full lines forward or backward from the cursor",
		},
	},
})

return collectors
