local lines = require("smart-motion.collectors.lines")
local create_registry = require("smart-motion.core.registry")
local collectors = create_registry()

collectors.register_many({
	lines = {
		keys = { "l" },
		run = lines.init,
		filetypes = { "*" },
		metadata = {
			label = "Line Collector",
			description = "Collects full lines forward or backward from the cursor",
		},
	},
})

return collectors
