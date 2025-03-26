--- Main entry point for smart-motion
local state = require("smart-motion.core.state")
local config = require("smart-motion.config")
local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")
local highlight_setup = require("smart-motion.highlight_setup")
local motions = require("smart-motion.motions")
local presets = require("smart-motion.presets")

-- Core module registries
local collectors = require("smart-motion.collectors")
local extractors = require("smart-motion.extractors")
local filters = require("smart-motion.filters")
local visualizers = require("smart-motion.visualizers")
local actions = require("smart-motion.actions")
local pipeline_wrappers = require("smart-motion.pipeline_wrappers")

local M = {}

--- Sets up smart-motion with user-provided config.
--- This should be called froh the user's init.lua/init.vim.
---@param user_config table|nil
function M.setup(user_config)
	log.debug("Setting up SmartMotion")

	local ok, validated_config = pcall(config.validate, user_config)
	if not ok then
		log.error("Failed to validate config: " .. tostring(validated_config))

		return
	end

	highlight_setup.setup(validated_config)

	-- Setup static state based on config (keys and max_labels only need to be computed once)
	state.init_motion_state(validated_config)

	log.debug("SmartMotion setup complete")
end

-- Constants for config
M.consts = consts

M.presets = presets

-- Motion registration
M.register_motion = motions.register_motion
M.register_many_motions = motions.register_many_motions

-- Module registration per type
M.collectors = {
	register = collectors.register,
	register_many = collectors.register_many,
}

M.extractors = {
	register = extractors.register,
	register_many = extractors.register_many,
}

M.filters = {
	register = filters.register,
	register_many = filters.register_many,
}

M.visualizers = {
	register = visualizers.register,
	register_many = visualizers.register_many,
}

M.actions = {
	register = actions.register,
	register_many = actions.register_many,
}

M.pipeline_wrappers = {
	register = pipeline_wrappers.register,
	register_many = pipeline_wrappers.register_many,
}

return M
