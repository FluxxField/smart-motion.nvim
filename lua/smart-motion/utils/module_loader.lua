local log = require("smart-motion.core.log")

local M = {}

--- Returns a map of module key -> resolved module from motion_state.motion
--- Supports fallback to 'default' where applicable.
--- @param motion_state SmartMotionMotionState
--- @param keys string[] | nil -- optional list of keys to resolve (defaults to all standard types)
function M.get_modules(ctx, cfg, motion_state, keys)
	local registries = require("smart-motion.core.registries"):get()
	local motion = motion_state.motion
	local action_key = motion.action_key
	local motion_key = motion_state.motion_key
	local modules = {}

	local default_keys = { "collector", "extractor", "modifier", "filter", "visualizer", "action" }
	keys = keys or default_keys

	for _, key in ipairs(keys) do
		local registry = registries[key .. "s"]

		if registry then
			local name = motion[key] or "default"
			local module

			module = registry.get_by_name(name)

			--
			-- Special handle for actions
			--
			if key == "action" and motion.infer and action_key then
				module = registry.get_by_key(action_key)
			end

			if (not module or not module.run) and registry.get_by_name("default") then
				module = registry.get_by_name("default")
			end

			modules[key] = module
		end
	end

	return modules
end

--- Shortcut for getting one module by key
function M.get_module(ctx, cfg, motion_state, key)
	return M.get_modules(ctx, cfg, motion_state, { key })[key]
end

function M.get_module_by_name(ctx, cfg, motion_state, registry_key, module_name)
	local registries = require("smart-motion.core.registries"):get()
	return registries[registry_key].get_by_name(module_name)
end

return M
