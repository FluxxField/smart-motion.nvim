local utils = require("smart-motion.utils")
local default = require("smart-motion.modifiers.default")
local weight_distance = require("smart-motion.modifiers.weight_distance")

---@type SmartMotionRegistry<SmartMotionModifierModuleEntry>
local modifiers = require("smart-motion.core.registry")("modifiers")

modifiers.register_many({
	default = {
      run = utils.module_wrapper(default.run),
      metadata = default.metadata,
    },
	weight_distance = {
      run = utils.module_wrapper(weight_distance.run),
      metadata = weight_distance.metadata,
    },
})

return modifiers
