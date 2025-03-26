local jump_to_target = require("smart-motion.actions.jump_to_target")
local create_registry = require("smart-motion.core.registry")
local actions = create_registry()

actions.register_many({
	jump_to_target = {
		run = jump_to_target.execute,
		metadata = {
			label = "Jump To Target",
			description = "Executes a jump to selected target hint",
		},
	},
})

return actions
