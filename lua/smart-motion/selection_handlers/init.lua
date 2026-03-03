local log = require("smart-motion.core.log")

---@type SmartMotionRegistry<SmartMotionSelectionHandlerEntry>
local selection_handlers = require("smart-motion.core.registry")("selection_handlers")

---@type table<string, SmartMotionSelectionHandlerEntry>
local handler_entries = {
	select_first = {
		run = function(ctx, cfg, motion_state)
			-- selected_jump_target is already set to targets[1] by targets.get_targets(),
			-- so just return true to accept the pre-set default.
			log.debug("Selection handler: select_first")
			return true
		end,
		metadata = {
			label = "Select First",
			description = "Selects the first (closest) target during label selection",
		},
	},
}

selection_handlers.register_many(handler_entries)

return selection_handlers
