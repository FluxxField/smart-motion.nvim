local lines = require("smart-motion.extractors.lines")
local words = require("smart-motion.extractors.words")
local text_search = require("smart-motion.extractors.text-search")

---@type SmartMotionRegistry<SmartMotionExtractorModuleEntry>
local extractors = require("smart-motion.core.registry")("extractors")

--- @type table<string, SmartMotionExtractorModuleEntry>
local extractor_entries = {
	lines = {
		keys = { "l" },
		run = lines.run,
		metadata = {
			label = "Line Extractor",
			description = "Extracts lines to generate targets from collector",
		},
	},
	words = {
		keys = { "w" },
		run = words.run,
		metadata = {
			label = "Word Extractor",
			description = "Extracts words to generate targets from collector",
		},
	},
	text_search = {
		run = text_search.run,
		metadata = {
			label = "Search Extractor",
			description = "Extracts searched text to generate targets from collector",
		},
	},
}

extractors.register_many(extractor_entries)

return extractors
