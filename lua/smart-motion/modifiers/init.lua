---@type SmartMotionRegistry<SmartMotionModifierModuleEntry>
local modifiers = require("smart-motion.core.registry")("modifiers")

modifiers.register_many({
	default = require("smart-motion.modifiers.default"),
	weight_distance = require("smart-motion.modifiers.weight_distance"),
})

return modifiers
