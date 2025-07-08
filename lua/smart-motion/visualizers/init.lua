local hints = require("smart-motion.visualizers.hints")
local pass_through = require("smart-motion.visualizers.pass_through")

local HINT_POSITION = require("smart-motion.consts").HINT_POSITION

---@type SmartMotionRegistry<SmartMotionVisualizerModuleEntry>
local visualizers = require("smart-motion.core.registry")("visualizers")

--- @type table<string, SmartMotionVisualizerModuleEntry>
local visualizer_entries = {
	hint_start = {
		run = hints.run,
		metadata = {
			label = "Hint Start Visualizer",
			description = "Applies hints to the start of targets",
			motion_state = {
				hint_position = HINT_POSITION.START,
			},
		},
	},
	hint_end = {
		run = hints.run,
		metadata = {
			label = "Hint End Visualizer",
			description = "Applies hints to the end of targets",
			motion_state = {
				hint_position = HINT_POSITION.END,
			},
		},
	},
	pass_through = {
		run = pass_through.run,
		metadata = pass_through.metadata,
	},
}

visualizers.register_many(visualizer_entries)

return visualizers
