local utils = require("smart-motion.utils")
local lines = require("smart-motion.extractors.lines")
local words = require("smart-motion.extractors.words")
local text_search = require("smart-motion.extractors.text_search")
local live_search = require("smart-motion.extractors.live_search")

---@type SmartMotionRegistry<SmartMotionExtractorModuleEntry>
local extractors = require("smart-motion.core.registry")("extractors")

--- @type table<string, SmartMotionExtractorModuleEntry>
extractors.register_many({
	lines = {
		run = utils.module_wrapper(lines.run),
		metadata = lines.metadata,
	},
	words = {
		run = utils.module_wrapper(words.run),
		metadata = words.metadata,
	},
	text_search_1_char = {
		run = utils.module_wrapper(text_search.run, {
			before_input_loop = text_search.before_input_loop,
		}),
		metadata = vim.tbl_deep_extend("force", text_search.metadata, {
			motion_state = {
				num_of_char = 1,
				should_show_prefix = false,
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
			},
		}),
	},
	live_search = {
		run = utils.module_wrapper(live_search.run, {
			before_input_loop = live_search.before_input_loop,
		}),
		metadata = live_search.metadata,
	},
})

return extractors
