local default = require("smart-motion.pipeline_wrappers.default")
local live_search = require("smart-motion.pipeline_wrappers.live_search")
local text_search = require("smart-motion.pipeline_wrappers.text_search")

---@type SmartMotionRegistry<SmartMotionPipelineWrapperModuleEntry>
local pipeline_wrappers = require("smart-motion.core.registry")("pipeline_wrappers")

--- @type table<string, SmartMotionPipelineWrapperModuleEntry>
local pipeline_wrapper_entries = {
	default = {
		run = default.run,
		metadata = {
			label = "Default Wrapper",
			description = "Executes pipeline once without user interaction",
		},
	},
	live_search = {
		run = live_search.run,
		metadata = {
			label = "Live Search Wrapper",
			description = "Executes pipeline while the user searches for text",
		},
	},
	text_search_1_char = {
		run = text_search.run,
		metadata = {
			label = "Text Search Wrapper 1 Character",
			description = "Executes pipeline while the user searches for 1 character",
			motion_state = {
				num_of_char = 1,
			},
		},
	},
	text_search_2_char = {
		run = text_search.run,
		metadata = {
			label = "Text Search Wrapper 2 Characters",
			description = "Executes pipeline while the user searches for 2 characters",
			motion_state = {
				num_of_char = 2,
			},
		},
	},
}

pipeline_wrappers.register_many(pipeline_wrapper_entries)

return pipeline_wrappers
