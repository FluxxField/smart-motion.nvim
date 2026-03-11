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
-- fuzzy match
-- =============================================================================

T["match"] = MiniTest.new_set()

T["match"]["empty needle matches everything"] = function()
	local fuzzy = require("smart-motion.core.fuzzy")
	local score, positions = fuzzy.match("", "hello", false)
	expect.equality(score, 0)
	expect.equality(type(positions), "table")
	expect.equality(#positions, 0)
end

T["match"]["needle longer than haystack returns nil"] = function()
	local fuzzy = require("smart-motion.core.fuzzy")
	local score, positions = fuzzy.match("toolong", "hi", false)
	expect.equality(score, nil)
	expect.equality(positions, nil)
end

T["match"]["exact match scores high"] = function()
	local fuzzy = require("smart-motion.core.fuzzy")
	local score, positions = fuzzy.match("hello", "hello", false)
	expect.no_equality(score, nil)
	expect.equality(#positions, 5)
end

T["match"]["substring match works"] = function()
	local fuzzy = require("smart-motion.core.fuzzy")
	local score, positions = fuzzy.match("hlo", "hello", false)
	expect.no_equality(score, nil)
	expect.equality(#positions, 3)
end

T["match"]["no match returns nil"] = function()
	local fuzzy = require("smart-motion.core.fuzzy")
	local score, positions = fuzzy.match("xyz", "hello", false)
	expect.equality(score, nil)
end

T["match"]["case insensitive by default"] = function()
	local fuzzy = require("smart-motion.core.fuzzy")
	local score, positions = fuzzy.match("HEL", "hello", false)
	expect.no_equality(score, nil)
end

T["match"]["case sensitive when requested"] = function()
	local fuzzy = require("smart-motion.core.fuzzy")
	local score, positions = fuzzy.match("HEL", "hello", true)
	expect.equality(score, nil)
end

T["match"]["camelCase boundary gets bonus"] = function()
	local fuzzy = require("smart-motion.core.fuzzy")
	-- "fN" should match "fileName" at camelCase boundary
	local score1, _ = fuzzy.match("fN", "fileName", false)
	-- "fn" against a word without boundary
	local score2, _ = fuzzy.match("fn", "function", false)
	-- Both should match
	expect.no_equality(score1, nil)
	expect.no_equality(score2, nil)
end

T["match"]["word boundary after separator gets bonus"] = function()
	local fuzzy = require("smart-motion.core.fuzzy")
	local score, positions = fuzzy.match("fb", "foo_bar", false)
	expect.no_equality(score, nil)
	-- 'b' should match at position after '_'
	expect.equality(#positions, 2)
end

-- =============================================================================
-- find_matches_in_line
-- =============================================================================

T["find_matches_in_line"] = MiniTest.new_set()

T["find_matches_in_line"]["finds matches in words"] = function()
	local fuzzy = require("smart-motion.core.fuzzy")
	local matches = fuzzy.find_matches_in_line("hel", "hello world help", false)

	-- Should match "hello" and "help"
	expect.equality(#matches, 2)
end

T["find_matches_in_line"]["returns empty for no matches"] = function()
	local fuzzy = require("smart-motion.core.fuzzy")
	local matches = fuzzy.find_matches_in_line("xyz", "hello world", false)
	expect.equality(#matches, 0)
end

T["find_matches_in_line"]["returns empty for empty input"] = function()
	local fuzzy = require("smart-motion.core.fuzzy")

	local m1 = fuzzy.find_matches_in_line("", "hello", false)
	local m2 = fuzzy.find_matches_in_line("hello", "", false)

	expect.equality(#m1, 0)
	expect.equality(#m2, 0)
end

T["find_matches_in_line"]["match positions are 0-indexed"] = function()
	local fuzzy = require("smart-motion.core.fuzzy")
	local matches = fuzzy.find_matches_in_line("wor", "hello world", false)

	expect.equality(#matches, 1)
	-- "world" starts at column 6 (0-indexed)
	expect.equality(matches[1].start_col, 6)
end

T["find_matches_in_line"]["includes score and text"] = function()
	local fuzzy = require("smart-motion.core.fuzzy")
	local matches = fuzzy.find_matches_in_line("hel", "hello world", false)

	expect.equality(#matches, 1)
	expect.no_equality(matches[1].score, nil)
	expect.equality(matches[1].text, "hello")
end

return T
