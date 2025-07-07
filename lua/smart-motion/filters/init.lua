local utils = require("smart-motion.utils")
local merge = require("smart-motion.filters.utils").merge

local first_target = require("smart-motion.filters.first_target")

---@type SmartMotionRegistry<SmartMotionFilterModuleEntry>
local filters = require("smart-motion.core.registry")("filters")

local DIRECTION = require("smart-motion.consts").DIRECTION

---@type table<string, SmartMotionFilterModuleEntry>
local filter_entries = {
	default = {
		run = utils.module_wrapper(require("smart-motion.filters.default").run),
		metadata = {
			label = "Default Passthrough",
			description = "Yields all targets unchanged",
		},
	},
	filter_visible = {
		run = utils.module_wrapper(require("smart-motion.filters.filter_visible_lines").run),
		metadata = {
			label = "Visible Only",
			description = "Filters to targets visible in the current window.",
		},
	},
	filter_cursor_line_only = {
		run = utils.module_wrapper(require("smart-motion.filters.filter_cursor_line_only").run),
		metadata = {
			label = "Cursor Line Only",
			description = "Filters targets to the ones only on the cursor line",
		},
	},
	filter_lines_after_cursor = {
		run = utils.module_wrapper(merge({
			require("smart-motion.filters.filter_visible_lines").run,
			require("smart-motion.filters.filter_lines_after_cursor").run,
		})),
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
		run = utils.module_wrapper(merge({
			require("smart-motion.filters.filter_visible_lines").run,
			require("smart-motion.filters.filter_lines_before_cursor").run,
		})),
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
		run = utils.module_wrapper(merge({
			require("smart-motion.filters.filter_visible_lines").run,
			require("smart-motion.filters.filter_words_after_cursor").run,
		})),
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
		run = utils.module_wrapper(merge({
			require("smart-motion.filters.filter_visible_lines").run,
			require("smart-motion.filters.filter_words_before_cursor").run,
		})),
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
		run = utils.module_wrapper(merge({
			require("smart-motion.filters.filter_visible_lines").run,
			require("smart-motion.filters.filter_words_around_cursor").run,
		})),
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
		run = utils.module_wrapper(merge({
			require("smart-motion.filters.filter_visible_lines").run,
			require("smart-motion.filters.filter_lines_around_cursor").run,
		})),
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
	filter_words_on_cursor_line_after_cursor = {
		run = utils.module_wrapper(merge({
			require("smart-motion.filters.filter_cursor_line_only").run,
			require("smart-motion.filters.filter_words_after_cursor").run,
		})),
		metadata = {
			label = "Filter Words On Cursor Line After Cursor",
			description = "Keeps word targets only on the cursor line after the cursor position.",
			merged = true,
			module_names = { "filter_words", "cursor_line_only", "after_cursor" },
		},
	},
	filter_words_on_cursor_line_before_cursor = {
		run = utils.module_wrapper(merge({
			require("smart-motion.filters.filter_cursor_line_only").run,
			require("smart-motion.filters.filter_words_before_cursor").run,
		})),
		metadata = {
			label = "Filter Words On Cursor Line Before Cursor",
			description = "Keeps word targets only on the cursor line before the cursor position.",
			merged = true,
			module_names = { "filter_words", "cursor_line_only", "before_cursor" },
		},
	},
	first_target = {
		run = utils.module_wrapper(first_target.run)
		metadata = first_target.metadata,
	},
}

filters.register_many(filter_entries)

return filters
