--- Main entry point for smart-motion
local state = require("smart-motion.core.state")
local config = require("smart-motion.config")
local hint_words = require("smart-motion.motion.hint_words")
local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")
local highlight_setup = require("smart-motion.highlight_setup")
local hint_lines = require("smart-motion.motion.hint_lines")

local M = {}

--- Helper to detect if which-key.nvim is installed.
local function has_which_key()
	local ok = pcall(require, "which-key")

	return ok
end

--- Register mappings, preferring which-key if available.
---@param mappings table The `n` and `v` mappings table from config.
local function register_mappings(mappings)
	log.debug("Registering mappings")

	if type(mappings) ~= "table" then
		log.error("Mappings should be a table (got: " .. type(mappings) .. ")")

		return
	end

	for mode, mode_mappings in pairs(mappings) do
		if type(mode_mappings) ~= "table" then
			log.debug(
				"Skipping mappings for mode '" .. mode .. "' (expected table, got: " .. type(mode_mappings) .. ")"
			)

			goto continue
		end

		for key, mapping in pairs(mode_mappings) do
			if type(mapping) ~= "table" or type(mapping[1]) ~= "function" then
				log.warn(string.format("Invalid mapping for '%s' in mode '%s'", key, mode))

				goto continue_inner
			end

			local action = mapping[1]
			local opts = { desc = mapping.desc or "smart-motion action" }

			if has_which_key() then
				local wk = require("which-key")
				wk.register({ [key] = opts.desc }, { mode = mode })
			end

			local ok, err = pcall(vim.keymap.set, mode, key, action, opts)
			if not ok then
				log.error(string.format("Failed to register keymap %s in mode %s: %s", key, mode, err))
			else
				log.debug(string.format("Registered keymap %s in mode %s", key, mode))
			end

			::continue_inner::
		end

		::continue::
	end

	log.debug("Mapping registration complete")
end

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

	register_mappings(validated_config.mappings)

	-- Setup static state based on config (keys and max_labels only need to be computed once)
	state.init_motion_state(validated_config)

	log.debug("SmartMotion setup complete")
end

--- Expose methods and constants
M.hint_words = hint_words.run
M.hint_lines = hint_lines.run
M.consts = consts

return M
