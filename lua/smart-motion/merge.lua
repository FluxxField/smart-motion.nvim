local registries = require("smart-motion.core.registries")
local filter_merger = require("smart-motion.filters.utils").merge
local action_merger = require("smart-motion.actions.utils").merge

--- Deep merges multiple tables (in order) into one.
--- Later tables override earlier ones for conflicts.
local function deep_merge_metadata(...)
	local result = {}

	for _, t in ipairs({ ... }) do
		for k, v in pairs(t) do
			if type(v) == "table" and type(result[k]) == "table" then
				result[k] = deep_merge_metadata(result[k], v)
			else
				result[k] = v
			end
		end
	end

	return result
end

--- Merge any registry type (actions, filters, etc.) by name.
--- @param registry_type string: one of "actions", "filters", etc.
--- @param module_names string[]: list of registered module names
--- @return table: a merged module with combined `run` and `metadata`
local function merge_registry_modules(registry_type, module_names)
	local all = registries:get()
	local registry = all[registry_type]

	assert(registry, ("[smart-motion] Registry '%s' not initialized. Did you call :init()?"):format(registry_type))

	local modules = {}
	local collected_names = {}
	local metadatas = {}

	for _, name in ipairs(module_names) do
		local mod = registry.get(name)
		if not mod then
			error(string.format("[smart-motion] No %s module found for name: %s", registry_type, name))
		end

		table.insert(modules, mod)
		table.insert(metadatas, mod.metadata or {})
		table.insert(collected_names, name)
	end

	local merged_metadata = deep_merge_metadata(unpack(metadatas))
	merged_metadata.merged = true
	merged_metadata.module_names = collected_names
	merged_metadata.label = "Merged " .. registry_type
	merged_metadata.description = "Merged " .. registry_type .. " modules: " .. table.concat(collected_names, ", ")

	if registry_type == "filters" then
		return {
			metadata = merged_metadata,
			run = filter_merger(modules),
		}
	elseif registry_type == "actions" then
		return {
			metadata = merged_metadata,
			run = action_merger(modules),
		}
	else
		return {
			metadata = merged_metadata,
			run = function(...)
				for _, mod in ipairs(modules) do
					mod.run(...)
				end
			end,
		}
	end
end

return {
	merge_actions = function(names)
		return merge_registry_modules("actions", names)
	end,
	merge_filters = function(names)
		return merge_registry_modules("filters", names)
	end,
}
