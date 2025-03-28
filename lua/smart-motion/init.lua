--- Main entry point for smart-motion
local registries_module = require("smart-motion.core.registries")
local state = require("smart-motion.core.state")
local config = require("smart-motion.config")
local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")
local highlight_setup = require("smart-motion.highlight_setup")

local M = {}

--- Sets up smart-motion with user-provided config.
--- This should be called froh the user's init.lua/init.vim.
---@param user_config table|nil
function M.setup(user_config)
	registries_module:init({
		collectors = require("smart-motion.collectors"),
		extractors = require("smart-motion.extractors"),
		filters = require("smart-motion.filters"),
		visualizers = require("smart-motion.visualizers"),
		actions = require("smart-motion.actions"),
		pipeline_wrappers = require("smart-motion.pipeline_wrappers"),
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

	M.register_motion = registries.motions.register_motion
	M.register_many_motions = registries.motions.register_many_motions

	M.collectors = {
		register = registries.collectors.register,
		register_many = registries.collectors.register_many,
	}

	M.extractors = {
		register = registries.extractors.register,
		register_many = registries.extractors.register_many,
	}

	M.filters = {
		register = registries.filters.register,
		register_many = registries.filters.register_many,
	}

	M.visualizers = {
		register = registries.visualizers.register,
		register_many = registries.visualizers.register_many,
	}

	M.actions = {
		register = registries.actions.register,
		register_many = registries.actions.register_many,
	}

	M.pipeline_wrappers = {
		register = registries.pipeline_wrappers.register,
		register_many = registries.pipeline_wrappers.register_many,
	}
end

M.consts = consts

return M
