local log = require("smart-motion.core.log")

local default_registry_constructors = {
	collectors = true,
	extractors = true,
	filters = true,
	visualizers = true,
	actions = true,
	pipeline_wrappers = true,
	motions = true,
}

local M = {}

function M:init(registry_table)
	local resolved = {}

	for name, value in pairs(registry_table) do
		assert(default_registry_constructors[name], "[smart-motion] Unknown registry: " .. name)

		if type(value) == "function" then
			value = value()
		end

		resolved[name] = value
	end

	-- ✅ Store resolved registries on self
	self.registries = resolved
end

function M:get()
	assert(self.registries, "[smart-motion] Registries not initialized. Call :init() first.")
	return self.registries
end

return M
