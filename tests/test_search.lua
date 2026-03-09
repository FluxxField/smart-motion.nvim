local MiniTest = require("mini_test")
local expect = MiniTest.expect
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
	hooks = {
		pre_case = function()
			helpers.setup_plugin()
		end,
		post_case = helpers.cleanup,
	},
})

-- =============================================================================
-- char_state
-- =============================================================================

T["char_state"] = MiniTest.new_set()

T["char_state"]["starts with nil"] = function()
	local cs = require("smart-motion.search.char_state")
	cs.last = nil -- ensure clean state

	expect.equality(cs.get(), nil)
end

T["char_state"]["saves and retrieves state"] = function()
	local cs = require("smart-motion.search.char_state")

	cs.save("x", "after_cursor", false)

	local state = cs.get()
	expect.no_equality(state, nil)
	expect.equality(state.search_text, "x")
	expect.equality(state.direction, "after_cursor")
	expect.equality(state.exclude_target, false)
end

T["char_state"]["overwrites previous state"] = function()
	local cs = require("smart-motion.search.char_state")

	cs.save("a", "after_cursor", false)
	cs.save("b", "before_cursor", true)

	local state = cs.get()
	expect.equality(state.search_text, "b")
	expect.equality(state.direction, "before_cursor")
	expect.equality(state.exclude_target, true)
end

T["char_state"]["defaults exclude_target to false"] = function()
	local cs = require("smart-motion.search.char_state")

	cs.save("z", "both")

	local state = cs.get()
	expect.equality(state.exclude_target, false)
end

-- =============================================================================
-- Collector registry
-- =============================================================================

T["collector registry"] = MiniTest.new_set()

T["collector registry"]["all collectors are registered"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local collectors = registries.collectors

	local expected = { "lines", "history", "treesitter", "diagnostics", "git_hunks", "quickfix", "marks", "patterns" }
	for _, name in ipairs(expected) do
		expect.no_equality(collectors.get_by_name(name), nil)
	end
end

-- =============================================================================
-- Filter registry
-- =============================================================================

T["filter registry"] = MiniTest.new_set()

T["filter registry"]["all filters are registered"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local filters = registries.filters

	local expected = {
		"default",
		"filter_visible",
		"filter_cursor_line_only",
		"filter_lines_after_cursor",
		"filter_lines_before_cursor",
		"filter_words_after_cursor",
		"filter_words_before_cursor",
		"filter_words_around_cursor",
		"filter_lines_around_cursor",
		"filter_words_on_cursor_line_after_cursor",
		"filter_words_on_cursor_line_before_cursor",
		"first_target",
	}

	for _, name in ipairs(expected) do
		expect.no_equality(filters.get_by_name(name), nil)
	end
end

return T
