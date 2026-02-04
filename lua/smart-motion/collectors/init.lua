local lines = require("smart-motion.collectors.lines")
local history = require("smart-motion.collectors.history")
local treesitter = require("smart-motion.collectors.treesitter")
local diagnostics = require("smart-motion.collectors.diagnostics")

---@type SmartMotionRegistry<SmartMotionCollectorModuleEntry>
local collectors = require("smart-motion.core.registry")("collectors")

--- @type table<string, SmartMotionCollectorModuleEntry>
collectors.register_many({
	lines = lines,
	history = history,
	treesitter = treesitter,
	diagnostics = diagnostics,
})

return collectors
