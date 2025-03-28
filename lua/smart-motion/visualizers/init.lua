local consts = require("smart-motion.consts")
local hints = require("smart-motion.visualizers.hints")
local visualizers = require("smart-motion.core.registry")("visualizers")

visualizers.register_many({
	hint_start = {
		run = hints.assign_and_apply_labels,
		hint_position = consts.HINT_POSITION.START,
		metadata = {
			label = "Hint Start Visualizer",
			description = "Applies hints to the start of targets",
		},
	},
	hint_end = {
		run = hints.assign_and_apply_labels,
		hint_position = consts.HINT_POSITION.END,
		metadata = {
			label = "Hint End Visualizer",
			description = "Applies hints to the end of targets",
		},
	},
})

return visualizers
