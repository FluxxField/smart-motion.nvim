local default_filter = require("smart-motion.filters.default")

---@type SmartMotionRegistry<SmartMotionFilterModuleEntry>
local filters = require("smart-motion.core.registry")("filters")

---@type table<string, SmartMotionFilterModuleEntry>
local filter_entries = {
	default = {
		run = default_filter.run,
		metadata = {
			label = "Default Filter",
			description = "Takes in data and simply returns it. No filtering applied",
		},
	},
}

filters.register_many(filter_entries)

return filters
