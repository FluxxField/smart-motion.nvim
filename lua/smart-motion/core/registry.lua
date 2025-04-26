local log = require("smart-motion.core.log")
local utils = require("smart-motion.utils")

---@param module_type? string
---@return SmartMotionRegistryRegistry
return function(module_type)
	local registry = {
		by_key = {},
		by_name = {},
		module_type = module_type or "",
	}

	local error_label = "[" .. registry.module_type .. " registry] "

	function registry._validate_module_entry(name, entry)
		local error_name = "Module '" .. name .. "': "

		if not utils.is_non_empty_string(name) then
			log.error(error_label .. error_name .. "Module must have a non-empty name.")
			return false
		end

		if not entry or type(entry.run) ~= "function" then
			log.error(error_label .. error_name .. "Module must have a 'run' function.")
			return false
		end

		return true
	end

	--- Registers a module by name.
	function registry.register(name, entry)
		if not registry._validate_module_entry(name, entry) then
			log.error(error_label .. " Registration aborted: " .. name)
			return
		end

		entry.name = name
		entry.metadata = entry.metadata or {}
		entry.metadata.label = entry.metadata.label or name:gsub("^%l", string.upper)
		entry.metadata.description = entry.metadata.description or ("SmartMotion: " .. entry.metadata.label)
		entry.metadata.motion_state = entry.metadata.motion_state or {}

		registry.by_name[name] = entry

		if entry.keys then
			for _, key in ipairs(entry.keys) do
				registry.by_key[key] = entry
			end
		end
	end

	--- Registers many modules.
	function registry.register_many(entries, opts)
		opts = opts or {}

		for name, entry in pairs(entries) do
			if not opts.override and registry.by_name[name] then
				log.warn("Skipping already-registered entry: " .. name)
			else
				registry.register(name, entry)
			end
		end
	end

	--- Gets a module by key.
	function registry.get_by_key(key)
		local entry = registry.by_key[key]

		if not entry then
			return nil
		end

		return entry
	end

	--- Gets a module by name.
	function registry.get_by_name(name)
		local entry = registry.by_name[name]

		if not entry then
			return nil
		end

		return entry
	end

	return registry
end
