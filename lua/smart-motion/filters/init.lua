local merge_filters = require("smart-motion.filters.utils")

---@type SmartMotionRegistry<SmartMotionFilterModuleEntry>
local filters = require("smart-motion.core.registry")("filters")

---@type table<string, SmartMotionFilterModuleEntry>
local filter_entries = {
	default = {
		run = require("smart-motion.filters.filter_visible_lines").run,
		metadata = {
			label = "Visible Only",
			description = "Applies dimming and hides off-screen targets.",
		},
	},
	filter_visible = {
		run = require("smart-motion.filters.filter_visible_lines").run,
		metadata = {
			label = "Visible Only",
			description = "Same as default, kept for clarity.",
		},
	},
	filter_lines_after_cursor = {
		run = merge_filters(
			require("smart-motion.filters.filter_visible_lines").run,
			require("smart-motion.filters.filter_lines_after_cursor").run
		),
		metadata = {
			label = "Lines After Cursor",
			description = "Visible lines after the cursor.",
		},
	},
	filter_lines_before_cursor = {
		run = merge_filters(
			require("smart-motion.filters.filter_visible_lines").run,
			require("smart-motion.filters.filter_lines_before_cursor").run
		),
		metadata = {
			label = "Lines Before Cursor",
			description = "Visible lines before the cursor.",
		},
	},
	filter_words_after_cursor = {
		run = merge_filters(
			require("smart-motion.filters.filter_visible_lines").run,
			require("smart-motion.filters.filter_words_after_cursor").run
		),
		metadata = {
			label = "Words After Cursor",
			description = "Visible words after the cursor using hint_position.",
		},
	},
	filter_words_before_cursor = {
		run = merge_filters(
			require("smart-motion.filters.filter_visible_lines").run,
			require("smart-motion.filters.filter_words_before_cursor").run
		),
		metadata = {
			label = "Words Before Cursor",
			description = "Visible words before the cursor using hint_position.",
		},
	},
}

filters.register_many(filter_entries)

return filters
