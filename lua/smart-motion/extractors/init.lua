local utils = require("smart-motion.utils")
local lines = require("smart-motion.extractors.lines")
local words = require("smart-motion.extractors.words")
local text_search = require("smart-motion.extractors.text_search")
local live_search = require("smart-motion.extractors.live_search")
local fuzzy_search = require("smart-motion.extractors.fuzzy_search")
local pass_through = require("smart-motion.extractors.pass_through")

---@type SmartMotionRegistry<SmartMotionExtractorModuleEntry>
local extractors = require("smart-motion.core.registry")("extractors")

--- @type table<string, SmartMotionExtractorModuleEntry>
extractors.register_many({
	lines = {
		keys = { "l" },
		run = utils.module_wrapper(lines.run),
		metadata = vim.tbl_deep_extend("force", lines.metadata, {
			motion_state = {
				allow_quick_action = false,
			},
		}),
	},
	words = {
		keys = { "w" },
		run = utils.module_wrapper(words.run),
		metadata = words.metadata,
	},
	text_search_1_char = {
		keys = { "f" },
		run = utils.module_wrapper(text_search.run, {
			before_input_loop = text_search.before_input_loop,
		}),
		metadata = vim.tbl_deep_extend("force", text_search.metadata, {
			motion_state = {
				num_of_char = 1,
				should_show_prefix = false,
				cursor_to_target = true,
			},
		}),
	},
	text_search_1_char_until = {
		run = utils.module_wrapper(text_search.run, {
			before_input_loop = text_search.before_input_loop,
		}),
		metadata = vim.tbl_deep_extend("force", text_search.metadata, {
			motion_state = {
				num_of_char = 1,
				should_show_prefix = false,
				exclude_target = true,
			},
		}),
	},
	text_search_2_char_until = {
		keys = { "t" },
		run = utils.module_wrapper(text_search.run, {
			before_input_loop = text_search.before_input_loop,
		}),
		metadata = vim.tbl_deep_extend("force", text_search.metadata, {
			motion_state = {
				num_of_char = 2,
				exclude_target = true,
			},
		}),
	},
	text_search_2_char = {
		run = utils.module_wrapper(text_search.run, {
			before_input_loop = text_search.before_input_loop,
		}),
		metadata = vim.tbl_deep_extend("force", text_search.metadata, {
			motion_state = {
				num_of_char = 2,
				cursor_to_target = true,
			},
		}),
	},
	live_search = {
		run = utils.module_wrapper(live_search.run, {
			before_input_loop = live_search.before_input_loop,
		}),
		metadata = vim.tbl_deep_extend("force", live_search.metadata, {
			motion_state = {
				cursor_to_target = true,
			},
		}),
	},
	fuzzy_search = {
		run = utils.module_wrapper(fuzzy_search.run, {
			before_input_loop = fuzzy_search.before_input_loop,
		}),
		metadata = vim.tbl_deep_extend("force", fuzzy_search.metadata, {
			motion_state = {
				cursor_to_target = true,
			},
		}),
	},
	pass_through = {
		run = utils.module_wrapper(pass_through.run),
		metadata = pass_through.metadata,
	},
})

return extractors
