--- Main entry point for smart-motion
local registries_module = require("smart-motion.core.registries")
local state = require("smart-motion.core.state")
local config = require("smart-motion.config")
local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")
local highlight_setup = require("smart-motion.highlight_setup")
local merge = require("smart-motion.merge")

---@type SmartMotionPlugin
local M = {}

--- Sets up smart-motion with user-provided config.
--- This should be called froh the user's init.lua/init.vim.
---@param user_config? SmartMotionConfig
function M.setup(user_config)
	registries_module:init({
		collectors = require("smart-motion.collectors"),
		extractors = require("smart-motion.extractors"),
		modifiers = require("smart-motion.modifiers"),
		filters = require("smart-motion.filters"),
		visualizers = require("smart-motion.visualizers"),
		actions = require("smart-motion.actions"),
		motions = require("smart-motion.motions"),
	})

	local registries = registries_module:get()

	local ok, validated_config = pcall(config.validate, user_config)
	if not ok then
		log.error("Failed to validate config: " .. tostring(validated_config))

		return
	end

	highlight_setup.setup(validated_config)
	state.init_motion_state(validated_config)

	--
	-- Handle preset setup
	--
	if validated_config.presets and type(validated_config.presets) == "table" then
		local presets = require("smart-motion.presets")

		for name, value in pairs(validated_config.presets) do
			local fn = presets[name]

			if type(fn) == "function" then
				if value == true then
					fn() -- no exclude
				elseif type(value) == "table" then
					fn(value) -- pass exclude list
				elseif value ~= false then
					log.warn("Invalid value for preset '" .. name .. "': expected true, false, or table")
				end
			else
				log.warn("Invalid preset name: " .. tostring(name))
			end
		end
	end

	M.merge_filters = merge.merge_filters
	M.merge_actions = merge.merge_actions

	M.motions = {
		register = registries.motions.register_motion,
		register_many = registries.motions.register_many_motions,
		map_motion = registries.motions.map_motion,
		get_by_key = registries.motions.get_by_key,
		get_by_name = registries.motions.get_by_name,
	}

	M.collectors = {
		register = registries.collectors.register,
		register_many = registries.collectors.register_many,
		get_by_key = registries.collectors.get_by_key,
		get_by_name = registries.collectors.get_by_name,
	}

	M.extractors = {
		register = registries.extractors.register,
		register_many = registries.extractors.register_many,
		get_by_key = registries.extractors.get_by_key,
		get_by_name = registries.extractors.get_by_name,
	}

	M.modifiers = {
		register = registries.modifiers.register,
		register_many = registries.modifiers.register_many,
		get_by_key = registries.modifiers.get_by_key,
		get_by_name = registries.modifiers.get_by_name,
	}

	M.filters = {
		register = registries.filters.register,
		register_many = registries.filters.register_many,
		get_by_key = registries.filters.get_by_key,
		get_by_name = registries.filters.get_by_name,
	}

	M.visualizers = {
		register = registries.visualizers.register,
		register_many = registries.visualizers.register_many,
		get_by_key = registries.visualizers.get_by_key,
		get_by_name = registries.visualizers.get_by_name,
	}

	M.actions = {
		register = registries.actions.register,
		register_many = registries.actions.register_many,
		get_by_key = registries.actions.get_by_key,
		get_by_name = registries.actions.get_by_name,
	}
end

M.consts = consts

return M
