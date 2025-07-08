local log = require("smart-motion.core.log")
local consts = require("smart-motion.consts")

local FLOW_STATE_TIMEOUT_MS = consts.FLOW_STATE_TIMEOUT_MS
local HISTORY_MAX_SIZE = consts.HISTORY_MAX_SIZE

local M = {}

-- Default highlight group names
local default_highlight_groups = {
	hint = "SmartMotionHint",
	hint_dim = "SmartMotionHintDim",
	two_char_hint = "SmartMotionTwoCharHint",
	two_char_hint_dim = "SmartMotionTwoCharHintDim",
	dim = "SmartMotionDim",
	search_prefix = "SmartMotionSearchPrefix",
	search_prefix_dim = "SmartMotionSearchPrefixDim",
}

---@type SmartMotionConfig
M.defaults = {
	keys = "fjdksleirughtynm",
	use_background_highlights = false,
	highlight = default_highlight_groups,
	presets = {},
	flow_state_timeout_ms = FLOW_STATE_TIMEOUT_MS,
	disable_dim_background = false,
	history_max_size = HISTORY_MAX_SIZE,
	auto_select_target = false,
}

---@type SmartMotionConfig
M.validated = nil

local function split_string(str)
	local result = {}
	for char in str:gmatch(".") do
		table.insert(result, char)
	end
	return result
end

--- Validates user configuration and applies defaults where needed.
---@param user_config? SmartMotionConfig
---@return SmartMotionConfig
function M.validate(user_config)
	log.debug("Validating SmartMotion configuration")

	if user_config and type(user_config) ~= "table" then
		log.error("User config must be a table or nil (got: " .. type(user_config) .. ")")
		error("smart-motion: Invalid user config provided")
	end

	local config = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), user_config or {})

	-- Validate & Convert keys to table of characters
	if type(config.keys) ~= "string" or #config.keys == 0 then
		log.error("`keys` must be a non-empty string of characters (got: " .. tostring(config.keys) .. ")")
		error("smart-motion: `keys` must be a non-empty string")
	end

	config.keys = split_string(config.keys)

	-- Make highlight optional and defensive
	config.highlight = config.highlight or {}

	-- Fill in any missing highlights with defaults
	for key, default_group in pairs(default_highlight_groups) do
		if config.highlight[key] == nil then
			config.highlight[key] = default_group
		end
	end

	-- Validate all highlights
	for key, value in pairs(config.highlight) do
		if type(value) ~= "string" and type(value) ~= "table" then
			log.error(
				"`highlight."
					.. key
					.. "` must be a string (group name) or a table (color definition), got: "
					.. type(value)
			)
			error("smart-motion: `highlight." .. key .. "` must be a string or table")
		end
	end

	--
	-- Validate presets
	--
	if config.presets ~= nil and type(config.presets) ~= "table" then
		log.error("`presets` must be a table with named keys, got: " .. type(config.presets))
		error("smart-motion: `presets` must be a table")
	end

	for preset_name, value in pairs(config.presets or {}) do
		if type(value) ~= "boolean" and type(value) ~= "table" then
			log.error(
				"Preset '"
					.. preset_name
					.. "' must be true, false, or a table (list of keys to exclude), got: "
					.. type(value)
			)
			error("smart-motion: Invalid value for preset '" .. preset_name .. "'")
		end

		if type(value) == "table" then
			for i, excluded_key in ipairs(value) do
				if type(excluded_key) ~= "string" then
					log.error(
						"Preset '"
							.. preset_name
							.. "' has an invalid exclude key at index "
							.. i
							.. ": expected string, got "
							.. type(excluded_key)
					)
					error("smart-motion: All excluded keys for preset '" .. preset_name .. "' must be strings")
				end
			end
		end
	end

	--
	-- Validate flow_state_timeout_ms
	--
	if config.flow_state_timeout_ms == nil or type(config.flow_state_timeout_ms) ~= "number" then
		config.flow_state_timeout_ms = FLOW_STATE_TIMEOUT_MS
	end

	--
	-- Validate disable_dim_background
	--
	if config.disable_dim_background == nil or type(config.disable_dim_background) ~= "boolean" then
		config.disable_dim_background = false
	end

	--
	-- Validate history_max_size
	--
	if config.history_max_size == nil or type(config.history_max_size) ~= "number" then
		config.history_max_size = HISTORY_MAX_SIZE
	end

	--
	-- Validate auto_select_target
	--
	if config.auto_select_target == nil or type(config.auto_select_target) ~= "boolean" then
		config.auto_select_target = false
	end

	M.validated = config

	return config
end

return M
