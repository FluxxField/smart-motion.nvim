local lines = require("smart-motion.extractors.lines")
local words = require("smart-motion.extractors.words")
local text_search = require("smart-motion.extractors.text-search")
local extractors = require("smart-motion.core.registry")("extractors")

extractors.register_many({
	lines = {
		keys = { "l" },
		run = lines.init,
		metadata = {
			label = "Line Extractor",
			description = "Extracts lines to generate targets from collector",
		},
	},
	words = {
		keys = { "w" },
		run = words.init,
		metadata = {
			label = "Word Extractor",
			description = "Extracts words to generate targets from collector",
		},
	},
	text_search = {
		run = text_search.init,
		metadata = {
			label = "Search Extractor",
			description = "Extracts searched text to generate targets from collector",
		},
	},
})

return extractors
