local default_filter = require("smart-motion.filters.default")
local filter_visible_lines = require("smart-motion.filters.filter_visible_lines")

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
	filter_visible_lines = {
		run = filter_visible_lines.run,
		metadata = {
			label = "Filter Only Visible Lines",
			description = "Filters out any targets that are not visible",
		},
	},
}

filters.register_many(filter_entries)

return filters
