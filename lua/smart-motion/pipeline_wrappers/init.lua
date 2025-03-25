local default = require("smart-motion.pipeline_wrappers.default")
local create_registry = require("smart-motion.core.registry")
local wrappers = create_registry()

wrappers.register_many({
	default_wrapper = {
		run = default.run,
		filetypes = { "*" },
		metadata = {
			label = "Default Wrapper",
			description = "Executes pipeline once without user interaction",
		},
	},
})

return wrappers
