local registries = require("smart-motion.core.registries")

local M = {}

--- Returns a map of module key -> resolved module from motion_state.motion
--- Supports fallback to 'default' where applicable.
--- @param motion_state SmartMotionMotionState
--- @param keys string[] | nil -- optional list of keys to resolve (defaults to all standard types)
function M.get_modules(ctx, cfg, motion_state, keys)
	local motion = motion_state.motion
	local trigger_key = motion.trigger_key
	local modules = {}

	local default_keys = { "collector", "extractor", "modifier", "filter", "visualizer", "action" }
	keys = keys or default_keys

	for _, key in ipairs(keys) do
		local registry = registries[key .. "s"]

		if registry then
			local name = motion[key] or "default"
			local module

			if key == "action" and motion.infer and trigger_key then
				module = registry.get_by_key(trigger_key)
			else
				module = registry.get_by_name(name)
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
function M.get_module(motion_state, key)
	return M.get_modules(motion_state, { key })[key]
end

return M
