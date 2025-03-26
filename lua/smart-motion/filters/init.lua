local default_filter = require("smart-motion.filters.default")
local create_registry = require("smart-motion.core.registry")
local filters = create_registry()

filters.register_many({
	default = {
		run = default_filter,
		metadata = {
			label = "Default Filter",
			description = "Takes in data and simply returns it. No filtering applied",
		},
	},
})

return filters
