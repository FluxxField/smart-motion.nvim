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
	text_search = {
		run = text_search.run,
		metadata = {
			label = "Text Search Wrapper",
			description = "Executes pipeline while the user searches for a specific number of text",
		},
	},
}

pipeline_wrappers.register_many(pipeline_wrapper_entries)

return pipeline_wrappers
