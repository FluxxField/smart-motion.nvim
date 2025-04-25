local merge = require("smart-motion.filters.utils").merge

---@type SmartMotionRegistry<SmartMotionFilterModuleEntry>
local filters = require("smart-motion.core.registry")("filters")

local DIRECTION = require("smart-motion.consts").DIRECTION

---@type table<string, SmartMotionFilterModuleEntry>
local filter_entries = {
	default = {
		run = require("smart-motion.filters.default").run,
		metadata = {
			label = "Default Passthrough",
			description = "Yields all targets unchanged",
		},
	},
	filter_visible = {
		run = require("smart-motion.filters.filter_visible_lines").run,
		metadata = {
			label = "Visible Only",
			description = "Filters to targets visible in the current window.",
		},
	},
	filter_lines_after_cursor = {
		run = merge({
			require("smart-motion.filters.filter_visible_lines"),
			require("smart-motion.filters.filter_lines_after_cursor"),
		}),
		metadata = {
			label = "Lines After Cursor",
			description = "Visible lines after the cursor.",
			merged = true,
			module_names = { "filter_visible", "filter_lines_after_cursor" },
			motion_state = {
				direction = DIRECTION.AFTER_CURSOR,
			},
		},
	},
	filter_lines_before_cursor = {
		run = merge({
			require("smart-motion.filters.filter_visible_lines"),
			require("smart-motion.filters.filter_lines_before_cursor"),
		}),
		metadata = {
			label = "Lines Before Cursor",
			description = "Visible lines before the cursor.",
			merged = true,
			module_names = { "filter_visible", "filter_lines_before_cursor" },
			motion_state = {
				direction = DIRECTION.BEFORE_CURSOR,
			},
		},
	},
	filter_words_after_cursor = {
		run = merge({
			require("smart-motion.filters.filter_visible_lines"),
			require("smart-motion.filters.filter_words_after_cursor"),
		}),
		metadata = {
			label = "Words After Cursor",
			description = "Visible words after the cursor using hint_position.",
			merged = true,
			module_names = { "filter_visible", "filter_words_after_cursor" },
			motion_state = {
				direction = DIRECTION.AFTER_CURSOR,
			},
		},
	},
	filter_words_before_cursor = {
		run = merge({
			require("smart-motion.filters.filter_visible_lines"),
			require("smart-motion.filters.filter_words_before_cursor"),
		}),
		metadata = {
			label = "Words Before Cursor",
			description = "Visible words before the cursor using hint_position.",
			merged = true,
			module_names = { "filter_visible", "filter_words_before_cursor" },
			motion_state = {
				direction = DIRECTION.BEFORE_CURSOR,
			},
		},
	},
	filter_words_around_cursor = {
		run = merge({
			require("smart-motion.filters.filter_visible_lines"),
			require("smart-motion.filters.filter_words_around_cursor"),
		}),
		metadata = {
			label = "Words Around Cursor",
			description = "Visible words around (before and after) the cursor.",
			merged = true,
			module_names = { "filter_visible", "filter_words_around_cursor" },
			motion_state = {
				direction = DIRECTION.BOTH,
			},
		},
	},
	filter_lines_around_cursor = {
		run = merge({
			require("smart-motion.filters.filter_visible_lines"),
			require("smart-motion.filters.filter_lines_around_cursor"),
		}),
		metadata = {
			label = "Lines Around Cursor",
			description = "Visible lines around (before and after) the cursor.",
			merged = true,
			module_names = { "filter_visible", "filter_lines_around_cursor" },
			motion_state = {
				direction = DIRECTION.BOTH,
			},
		},
	},
}

filters.register_many(filter_entries)

return filters
