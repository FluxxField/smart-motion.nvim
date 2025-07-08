local lines = require("smart-motion.collectors.lines")
local history = require("smart-motion.collectors.history")

---@type SmartMotionRegistry<SmartMotionCollectorModuleEntry>
local collectors = require("smart-motion.core.registry")("collectors")

--- @type table<string, SmartMotionCollectorModuleEntry>
collectors.register_many({
	lines = lines,
	history = history,
})

return collectors
