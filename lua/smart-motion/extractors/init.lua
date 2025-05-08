local text_search = require("smart-motion.extractors.text_search")

---@type SmartMotionRegistry<SmartMotionExtractorModuleEntry>
local extractors = require("smart-motion.core.registry")("extractors")

--- @type table<string, SmartMotionExtractorModuleEntry>
extractors.register_many({
	lines = require("smart-motion.extractors.lines"),
	words = require("smart-motion.extractors.words"),
	text_search_1_char = {
		run = text_search.run,
		metadata = vim.tbl_deep_extend("force", text_search.metadata, {
			motion_state = {
				search_text = "",
				num_of_char = 1,
			},
		}),
	},
	text_search_2_char = {
		run = text_search.run,
		metadata = vim.tbl_deep_extend("force", text_search.metadata, {
			motion_state = {
				search_text = "",
				num_of_char = 2,
			},
		}),
	},
	live_search = require("smart-motion.extractors.live_search"),
})

return extractors
