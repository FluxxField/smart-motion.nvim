local registries = require("smart-motion.core.registries")

local M = {}

--- Returns a map of module key -> resolved module from motion_state.motion
--- Supports fallback to 'default' where applicable.
--- @param motion_state SmartMotionMotionState
--- @param keys string[] | nil -- optional list of keys to resolve (defaults to all standard types)
function M.get_modules(ctx, cfg, motion_state, keys)
	local motion = motion_state.motion
	local modules = {}

	local default_keys = { "collector", "extractor", "modifier", "filter", "visualizer", "action" }
	keys = keys or default_keys

	for _, key in ipairs(keys) do
		local registry = registries[key .. "s"]

		if registry then
			local name = motion[key] or "default"
			local mod = registry.get_by_name(name)

			if (not mod or not mod.run) and registry.get_by_name("default") then
				mod = registry.get_by_name("default")
			end

			modules[key] = mod
		end
	end

	return modules
end

--- Shortcut for getting one module by key
function M.get_module(motion_state, key)
	return M.get_modules(motion_state, { key })[key]
end

return M
