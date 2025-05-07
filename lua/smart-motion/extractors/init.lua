local words = require("smart-motion.extractors.words")
local text_search = require("smart-motion.extractors.text_search")

---@type SmartMotionRegistry<SmartMotionExtractorModuleEntry>
local extractors = require("smart-motion.core.registry")("extractors")

--- @type table<string, SmartMotionExtractorModuleEntry>
extractors.register_many({
	lines = require("smart-motion.extractors.lines"),
	words = require("smart-motion.extractors.words"),
	text_search = require("smart-motion.extractors.text_search"),
})

return extractors
