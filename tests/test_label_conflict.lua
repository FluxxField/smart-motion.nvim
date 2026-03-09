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
-- get_conflicting_chars
-- =============================================================================

T["get_conflicting_chars"] = MiniTest.new_set()

T["get_conflicting_chars"]["finds chars after target matches"] = function()
	local lc = require("smart-motion.core.label_conflict")
	local bufnr = helpers.create_buf({ "foo bar fob" })

	-- Target "fo" at col 0-2 → next char is 'o' (from "foo")
	-- Target "fo" at col 8-10 → next char is 'b' (from "fob")
	local targets = {
		{
			start_pos = { row = 0, col = 0 },
			end_pos = { row = 0, col = 2 },
			metadata = { bufnr = bufnr },
		},
		{
			start_pos = { row = 0, col = 8 },
			end_pos = { row = 0, col = 10 },
			metadata = { bufnr = bufnr },
		},
	}

	local conflicts = lc.get_conflicting_chars(targets, bufnr)
	expect.equality(conflicts["o"], true)
	expect.equality(conflicts["b"], true)
end

T["get_conflicting_chars"]["ignores non-alphanumeric next chars"] = function()
	local lc = require("smart-motion.core.label_conflict")
	local bufnr = helpers.create_buf({ "ab cd" })

	-- Target "ab" at col 0-2 → next char is ' ' (space, not alphanumeric)
	local targets = {
		{
			start_pos = { row = 0, col = 0 },
			end_pos = { row = 0, col = 2 },
			metadata = { bufnr = bufnr },
		},
	}

	local conflicts = lc.get_conflicting_chars(targets, bufnr)
	-- Space should not be in conflicts
	expect.equality(conflicts[" "], nil)
end

T["get_conflicting_chars"]["handles end of line"] = function()
	local lc = require("smart-motion.core.label_conflict")
	local bufnr = helpers.create_buf({ "abc" })

	-- Target at end of line → no next char
	local targets = {
		{
			start_pos = { row = 0, col = 0 },
			end_pos = { row = 0, col = 3 },
			metadata = { bufnr = bufnr },
		},
	}

	local conflicts = lc.get_conflicting_chars(targets, bufnr)
	-- Should be empty
	expect.equality(next(conflicts), nil)
end

T["get_conflicting_chars"]["stores lowercase"] = function()
	local lc = require("smart-motion.core.label_conflict")
	local bufnr = helpers.create_buf({ "foX" })

	local targets = {
		{
			start_pos = { row = 0, col = 0 },
			end_pos = { row = 0, col = 2 },
			metadata = { bufnr = bufnr },
		},
	}

	local conflicts = lc.get_conflicting_chars(targets, bufnr)
	expect.equality(conflicts["x"], true) -- lowercase
	expect.equality(conflicts["X"], nil) -- not uppercase
end

-- =============================================================================
-- filter_keys
-- =============================================================================

T["filter_keys"] = MiniTest.new_set()

T["filter_keys"]["removes conflicting keys"] = function()
	local lc = require("smart-motion.core.label_conflict")

	local keys = { "f", "j", "d", "k", "s" }
	local conflicts = { f = true, k = true }

	local filtered = lc.filter_keys(keys, conflicts)

	expect.equality(#filtered, 3)
	expect.equality(filtered[1], "j")
	expect.equality(filtered[2], "d")
	expect.equality(filtered[3], "s")
end

T["filter_keys"]["returns all keys when no conflicts"] = function()
	local lc = require("smart-motion.core.label_conflict")

	local keys = { "a", "b", "c" }
	local filtered = lc.filter_keys(keys, {})

	expect.equality(#filtered, 3)
end

T["filter_keys"]["returns all keys when conflicts is nil"] = function()
	local lc = require("smart-motion.core.label_conflict")

	local keys = { "a", "b", "c" }
	local filtered = lc.filter_keys(keys, nil)

	expect.equality(#filtered, 3)
end

T["filter_keys"]["case insensitive filtering"] = function()
	local lc = require("smart-motion.core.label_conflict")

	local keys = { "F", "j", "D" }
	local conflicts = { f = true, d = true }

	local filtered = lc.filter_keys(keys, conflicts)

	expect.equality(#filtered, 1)
	expect.equality(filtered[1], "j")
end

-- =============================================================================
-- filter_conflicting_labels (main entry point)
-- =============================================================================

T["filter_conflicting_labels"] = MiniTest.new_set()

T["filter_conflicting_labels"]["removes labels matching next chars in targets"] = function()
	local lc = require("smart-motion.core.label_conflict")
	local bufnr = helpers.create_buf({ "foo for fox" })

	-- Targets: matches of "fo" in "foo for fox"
	local targets = {
		{ start_pos = { row = 0, col = 0 }, end_pos = { row = 0, col = 2 }, metadata = { bufnr = bufnr } },
		{ start_pos = { row = 0, col = 4 }, end_pos = { row = 0, col = 6 }, metadata = { bufnr = bufnr } },
		{ start_pos = { row = 0, col = 8 }, end_pos = { row = 0, col = 10 }, metadata = { bufnr = bufnr } },
	}

	local keys = { "f", "j", "d", "o", "r", "x", "s" }

	local filtered = lc.filter_conflicting_labels(keys, targets, bufnr)

	-- 'o', 'r', 'x' should be removed (they are chars after "fo" in foo, for, fox)
	for _, key in ipairs(filtered) do
		expect.equality(key ~= "o" and key ~= "r" and key ~= "x", true)
	end
end

T["filter_conflicting_labels"]["returns all keys when no targets"] = function()
	local lc = require("smart-motion.core.label_conflict")

	local keys = { "a", "b", "c" }
	local filtered = lc.filter_conflicting_labels(keys, {}, 0)

	expect.equality(#filtered, 3)
end

return T
