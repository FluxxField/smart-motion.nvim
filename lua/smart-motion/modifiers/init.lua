---@type SmartMotionRegistry<SmartMotionModifierModuleEntry>
local modifiers = require("smart-motion.core.registry")("modifiers")

local modifiers_entries = {
	default = require("smart-motion.modifiers.default"),
	distance_metadata = require("smart-motion.modifiers.distance_metadata"),
}

modifiers.register_many(modifiers_entries)

return modifiers
