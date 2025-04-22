local consts = require("smart-motion.consts")
local hints = require("smart-motion.visualizers.hints")

---@type SmartMotionRegistry<SmartMotionVisualizerModuleEntry>
local visualizers = require("smart-motion.core.registry")("visualizers")

--- @type table<string, SmartMotionVisualizerModuleEntry>
local visualizer_entries = {
	hint_start = {
		run = hints.run,
		metadata = {
			label = "Hint Start Visualizer",
			description = "Applies hints to the start of targets",
		},
	},
	hint_end = {
		run = hints.run,
		metadata = {
			label = "Hint End Visualizer",
			description = "Applies hints to the end of targets",
		},
	},
}

visualizers.register_many(visualizer_entries)

return visualizers
