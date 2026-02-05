local lines = require("smart-motion.collectors.lines")
local history = require("smart-motion.collectors.history")
local treesitter = require("smart-motion.collectors.treesitter")
local diagnostics = require("smart-motion.collectors.diagnostics")
local git_hunks = require("smart-motion.collectors.git_hunks")
local quickfix = require("smart-motion.collectors.quickfix")
local marks = require("smart-motion.collectors.marks")

---@type SmartMotionRegistry<SmartMotionCollectorModuleEntry>
local collectors = require("smart-motion.core.registry")("collectors")

--- @type table<string, SmartMotionCollectorModuleEntry>
collectors.register_many({
	lines = lines,
	history = history,
	treesitter = treesitter,
	diagnostics = diagnostics,
	git_hunks = git_hunks,
	quickfix = quickfix,
	marks = marks,
})

return collectors
