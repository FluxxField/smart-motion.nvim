local log = require("smart-motion.core.log")

--- @class RegistryConstructors
--- @field collectors boolean
--- @field extractors boolean
--- @field filters boolean
--- @field modifiers boolean
--- @field visualizers boolean
--- @field actions boolean
--- @field pipeline_wrappers boolean
--- @field motions boolean

--- @type RegistryConstructors
local default_registry_constructors = {
	collectors = true,
	extractors = true,
	filters = true,
	modifiers = true,
	visualizers = true,
	actions = true,
	pipeline_wrappers = true,
	motions = true,
}

---@type SmartMotionRegistryManager
local M = {}

--- Initialize the registry manager with given registries.
---@param registry_table SmartMotionRegistryMap
function M:init(registry_table)
	local resolved = {}

	for name, value in pairs(registry_table) do
		assert(default_registry_constructors[name], "[smart-motion] Unknown registry: " .. name)

		if type(value) == "function" then
			value = value()
		end

		resolved[name] = value
	end

	---@type SmartMotionRegistryMap
	self.registries = resolved
end

--- Get all resolved registries.
---@return SmartMotionRegistryMap
function M:get()
	assert(self.registries, "[smart-motion] Registries not initialized. Call :init() first.")
	return self.registries
end

---@type SmartMotionRegistryManager
return M
