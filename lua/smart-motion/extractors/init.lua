local lines = require("smart-motion.extractors.lines")
local words = require("smart-motion.extractors.words")
local create_registry = require("smart-motion.core.registry")
local extractors = create_registry()

extractors.register_many({
	lines = {
		keys = { "l" },
		run = lines.init,
		filetypes = { "*" },
		metadata = {
			label = "Line Extractor",
			description = "Extracts lines to generate targets from collector",
		},
	},
	words = {
		keys = { "w" },
		run = words.init,
		filetypes = { "*" },
		metadata = {
			label = "Word Extractor",
			description = "Extracts words to generate targets from collector",
		},
	},
})

return extractors
