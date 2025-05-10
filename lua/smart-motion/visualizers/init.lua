local HINT_POSITION = require("smart-motion.consts").HINT_POSITION

---@type SmartMotionRegistry<SmartMotionVisualizerModuleEntry>
local visualizers = require("smart-motion.core.registry")("visualizers")

--- @type table<string, SmartMotionVisualizerModuleEntry>
local visualizer_entries = {
	hint_start = {
		run = require("smart-motion.visualizers.hints").run,
		metadata = {
			label = "Hint Start Visualizer",
			description = "Applies hints to the start of targets",
			motion_state = {
				hint_position = HINT_POSITION.START,
			},
		},
	},
	hint_end = {
		run = require("smart-motion.visualizers.hints").run,
		metadata = {
			label = "Hint End Visualizer",
			description = "Applies hints to the end of targets",
			motion_state = {
				hint_position = HINT_POSITION.END,
			},
		},
	},
}

visualizers.register_many(visualizer_entries)

return visualizers
