local consts = require("smart-motion.consts")
local hints = require("smart-motion.visualizers.hints")
local create_registry = require("smart-motion.core.registry")
local visualizers = create_registry()

visualizers.register_many({
	hint_start = {
		run = hints.assign_and_apply_labels,
		hint_position = consts.HINT_POSITION.START,
		filetypes = { "*" },
		metadata = {
			label = "Hint Start Visualizer",
			description = "Applies hints to the start of targets",
		},
	},
	hint_end = {
		run = hints.assign_and_apply_labels,
		hint_position = consts.HINT_POSITION.END,
		filetypes = { "*" },
		metadata = {
			label = "Hint End Visualizer",
			description = "Applies hints to the end of targets",
		},
	},
})

return visualizers
