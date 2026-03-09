local MiniTest = require("mini_test")
local expect = MiniTest.expect
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
	hooks = {
		post_case = helpers.cleanup,
	},
})

-- Helper to get a fresh config module
local function get_config()
	package.loaded["smart-motion.config"] = nil
	return require("smart-motion.config")
end

-- =============================================================================
-- Defaults
-- =============================================================================

T["defaults"] = MiniTest.new_set()

T["defaults"]["returns correct defaults when no config provided"] = function()
	local config = get_config()
	local result = config.validate(nil)

	expect.equality(type(result.keys), "table")
	expect.equality(#result.keys, 16) -- "fjdksleirughtynm"
	expect.equality(result.dim_background, true)
	expect.equality(result.auto_select_target, false)
	expect.equality(result.native_search, true)
	expect.equality(result.count_behavior, "target")
	expect.equality(result.open_folds_on_jump, true)
	expect.equality(result.save_to_jumplist, true)
	expect.equality(result.flow_state_timeout_ms, 300)
	expect.equality(result.search_timeout_ms, 500)
	expect.equality(result.search_idle_timeout_ms, 2000)
	expect.equality(result.yank_highlight_duration, 150)
	expect.equality(result.history_max_age_days, 30)
end

T["defaults"]["returns correct defaults when empty table provided"] = function()
	local config = get_config()
	local result = config.validate({})

	expect.equality(result.dim_background, true)
	expect.equality(result.auto_select_target, false)
end

-- =============================================================================
-- Keys validation
-- =============================================================================

T["keys"] = MiniTest.new_set()

T["keys"]["converts string to character table"] = function()
	local config = get_config()
	local result = config.validate({ keys = "abc" })

	expect.equality(type(result.keys), "table")
	expect.equality(#result.keys, 3)
	expect.equality(result.keys[1], "a")
	expect.equality(result.keys[2], "b")
	expect.equality(result.keys[3], "c")
end

T["keys"]["errors on empty string"] = function()
	local config = get_config()
	expect.error(function()
		config.validate({ keys = "" })
	end)
end

T["keys"]["errors on non-string"] = function()
	local config = get_config()
	expect.error(function()
		config.validate({ keys = 123 })
	end)
end

-- =============================================================================
-- dim_background (and deprecated disable_dim_background)
-- =============================================================================

T["dim_background"] = MiniTest.new_set()

T["dim_background"]["accepts true"] = function()
	local config = get_config()
	local result = config.validate({ dim_background = true })
	expect.equality(result.dim_background, true)
end

T["dim_background"]["accepts false"] = function()
	local config = get_config()
	local result = config.validate({ dim_background = false })
	expect.equality(result.dim_background, false)
end

T["dim_background"]["invalid type falls back to default"] = function()
	local config = get_config()
	local result = config.validate({ dim_background = "yes" })
	expect.equality(result.dim_background, true)
end

T["dim_background"]["deprecated disable_dim_background=true maps to dim_background=false"] = function()
	local config = get_config()
	local result = config.validate({ disable_dim_background = true })
	expect.equality(result.dim_background, false)
	expect.equality(result.disable_dim_background, nil)
end

T["dim_background"]["deprecated disable_dim_background=false maps to dim_background=true"] = function()
	local config = get_config()
	local result = config.validate({ disable_dim_background = false })
	expect.equality(result.dim_background, true)
	expect.equality(result.disable_dim_background, nil)
end

-- =============================================================================
-- Boolean config options
-- =============================================================================

T["boolean options"] = MiniTest.new_set()

local boolean_options = {
	{ name = "auto_select_target", default = false },
	{ name = "native_search", default = true },
	{ name = "open_folds_on_jump", default = true },
	{ name = "save_to_jumplist", default = true },
}

for _, opt in ipairs(boolean_options) do
	T["boolean options"][opt.name .. " accepts true"] = function()
		local config = get_config()
		local result = config.validate({ [opt.name] = true })
		expect.equality(result[opt.name], true)
	end

	T["boolean options"][opt.name .. " accepts false"] = function()
		local config = get_config()
		local result = config.validate({ [opt.name] = false })
		expect.equality(result[opt.name], false)
	end

	T["boolean options"][opt.name .. " invalid type falls back to default"] = function()
		local config = get_config()
		local result = config.validate({ [opt.name] = "invalid" })
		expect.equality(result[opt.name], opt.default)
	end
end

-- =============================================================================
-- Numeric config options
-- =============================================================================

T["numeric options"] = MiniTest.new_set()

local numeric_options = {
	{ name = "flow_state_timeout_ms", default = 300 },
	{ name = "history_max_size", default = 100 },
	{ name = "search_timeout_ms", default = 500 },
	{ name = "search_idle_timeout_ms", default = 2000 },
	{ name = "yank_highlight_duration", default = 150 },
	{ name = "history_max_age_days", default = 30 },
}

for _, opt in ipairs(numeric_options) do
	T["numeric options"][opt.name .. " accepts valid number"] = function()
		local config = get_config()
		local result = config.validate({ [opt.name] = 999 })
		expect.equality(result[opt.name], 999)
	end

	T["numeric options"][opt.name .. " invalid type falls back to default"] = function()
		local config = get_config()
		local result = config.validate({ [opt.name] = "invalid" })
		expect.equality(result[opt.name], opt.default)
	end
end

-- =============================================================================
-- count_behavior
-- =============================================================================

T["count_behavior"] = MiniTest.new_set()

T["count_behavior"]["accepts target"] = function()
	local config = get_config()
	local result = config.validate({ count_behavior = "target" })
	expect.equality(result.count_behavior, "target")
end

T["count_behavior"]["accepts native"] = function()
	local config = get_config()
	local result = config.validate({ count_behavior = "native" })
	expect.equality(result.count_behavior, "native")
end

T["count_behavior"]["invalid value falls back to target"] = function()
	local config = get_config()
	local result = config.validate({ count_behavior = "invalid" })
	expect.equality(result.count_behavior, "target")
end

-- =============================================================================
-- max_pins
-- =============================================================================

T["max_pins"] = MiniTest.new_set()

T["max_pins"]["accepts valid number"] = function()
	local config = get_config()
	local result = config.validate({ max_pins = 5 })
	expect.equality(result.max_pins, 5)
end

T["max_pins"]["rejects zero"] = function()
	local config = get_config()
	local result = config.validate({ max_pins = 0 })
	-- Should fall back to default (PINS_MAX_SIZE)
	expect.equality(type(result.max_pins), "number")
	expect.equality(result.max_pins > 0, true)
end

T["max_pins"]["rejects negative"] = function()
	local config = get_config()
	local result = config.validate({ max_pins = -1 })
	expect.equality(result.max_pins > 0, true)
end

-- =============================================================================
-- Highlight validation
-- =============================================================================

T["highlight"] = MiniTest.new_set()

T["highlight"]["accepts string group names"] = function()
	local config = get_config()
	local result = config.validate({ highlight = { hint = "MyGroup" } })
	expect.equality(type(result.highlight.hint), "string")
end

T["highlight"]["accepts table color definitions"] = function()
	local config = get_config()
	local result = config.validate({ highlight = { hint = { fg = "#FF0000" } } })
	expect.equality(type(result.highlight.hint), "table")
end

T["highlight"]["errors on invalid type"] = function()
	local config = get_config()
	expect.error(function()
		config.validate({ highlight = { hint = 123 } })
	end)
end

T["highlight"]["fills missing groups with defaults"] = function()
	local config = get_config()
	local result = config.validate({ highlight = { hint = "Custom" } })
	-- Other groups should still have defaults
	expect.equality(type(result.highlight.two_char_hint), "string")
	expect.equality(type(result.highlight.dim), "string")
end

-- =============================================================================
-- Presets validation
-- =============================================================================

T["presets"] = MiniTest.new_set()

T["presets"]["accepts boolean values"] = function()
	local config = get_config()
	local result = config.validate({ presets = { words = true } })
	expect.equality(result.presets.words, true)
end

T["presets"]["accepts table exclude lists"] = function()
	local config = get_config()
	local result = config.validate({ presets = { words = { "w", "b" } } })
	expect.equality(type(result.presets.words), "table")
end

T["presets"]["errors on non-table presets"] = function()
	local config = get_config()
	expect.error(function()
		config.validate({ presets = "invalid" })
	end)
end

T["presets"]["errors on invalid preset value type"] = function()
	local config = get_config()
	expect.error(function()
		config.validate({ presets = { words = 123 } })
	end)
end

T["presets"]["errors on non-string exclude keys"] = function()
	local config = get_config()
	expect.error(function()
		config.validate({ presets = { words = { 123 } } })
	end)
end

-- =============================================================================
-- selection_keys validation
-- =============================================================================

T["selection_keys"] = MiniTest.new_set()

T["selection_keys"]["accepts valid key-action pairs"] = function()
	local config = get_config()
	local result = config.validate({ selection_keys = { ["<CR>"] = "select_first" } })
	expect.equality(result.selection_keys["<CR>"], "select_first")
end

T["selection_keys"]["false disables selection keys"] = function()
	local config = get_config()
	local result = config.validate({ selection_keys = false })
	expect.equality(result.selection_keys, false)
end

T["selection_keys"]["filters out invalid entries"] = function()
	local config = get_config()
	local result = config.validate({
		selection_keys = {
			["<CR>"] = "select_first",
			[123] = "bad_key",
		},
	})
	expect.equality(result.selection_keys["<CR>"], "select_first")
	expect.equality(result.selection_keys[123], nil)
end

-- =============================================================================
-- Top-level config validation
-- =============================================================================

T["top level"] = MiniTest.new_set()

T["top level"]["errors on non-table config"] = function()
	local config = get_config()
	expect.error(function()
		config.validate("invalid")
	end)
end

return T
