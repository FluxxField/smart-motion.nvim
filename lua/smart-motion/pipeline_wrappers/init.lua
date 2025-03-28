local default = require("smart-motion.pipeline_wrappers.default")
local wrappers = require("smart-motion.core.registry")("wrappers")
local live_search = require("smart-motion.pipeline_wrappers.live_search")

wrappers.register_many({
	default = {
		run = default.run,
		metadata = {
			label = "Default Wrapper",
			description = "Executes pipeline once without user interaction",
		},
	},
	search = {
		run = live_search.run,
		metadata = {
			label = "Live Search Wrapper",
			description = "Executes pipeline while the user searches for text",
		},
	},
})

return wrappers
