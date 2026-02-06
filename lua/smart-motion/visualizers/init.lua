local hints = require("smart-motion.visualizers.hints")
local pass_through = require("smart-motion.visualizers.pass_through")
local quickfix = require("smart-motion.visualizers.quickfix")
local telescope = require("smart-motion.visualizers.telescope")

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
	hint_before = {
		run = hints.run,
		metadata = {
			label = "Hint Before Visualizer",
			description = "Applies hints inline before targets (beacon style)",
			motion_state = {
				hint_position = HINT_POSITION.START,
				virt_text_pos = "inline",
			},
		},
	},
	pass_through = {
		run = pass_through.run,
		metadata = pass_through.metadata,
	},
	quickfix = {
		run = quickfix.run,
		metadata = quickfix.metadata,
	},
	telescope = {
		run = telescope.run,
		metadata = telescope.metadata,
	},
}

visualizers.register_many(visualizer_entries)

return visualizers
