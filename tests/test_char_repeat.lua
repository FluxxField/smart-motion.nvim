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
-- _find_matches
-- =============================================================================

T["_find_matches"] = MiniTest.new_set()

T["_find_matches"]["finds literal matches in buffer"] = function()
	helpers.create_buf({ "hello world hello", "foo hello bar" })
	helpers.set_cursor(1, 0)

	local char_repeat = require("smart-motion.search.char_repeat")
	local context = require("smart-motion.core.context")
	local ctx = context.get()

	local targets = char_repeat._find_matches("hello", ctx)

	-- Should find 3 matches: 2 on line 1, 1 on line 2
	expect.equality(#targets, 3)
	expect.equality(targets[1].text, "hello")
	expect.equality(targets[1].type, "search")
end

T["_find_matches"]["returns empty for no matches"] = function()
	helpers.create_buf({ "hello world" })
	helpers.set_cursor(1, 0)

	local char_repeat = require("smart-motion.search.char_repeat")
	local context = require("smart-motion.core.context")
	local ctx = context.get()

	local targets = char_repeat._find_matches("xyz", ctx)
	expect.equality(#targets, 0)
end

T["_find_matches"]["includes buffer and window metadata"] = function()
	helpers.create_buf({ "test abc test" })
	helpers.set_cursor(1, 0)

	local char_repeat = require("smart-motion.search.char_repeat")
	local context = require("smart-motion.core.context")
	local ctx = context.get()

	local targets = char_repeat._find_matches("test", ctx)
	expect.equality(#targets >= 2, true)
	expect.no_equality(targets[1].metadata.bufnr, nil)
	expect.no_equality(targets[1].metadata.winid, nil)
end

-- =============================================================================
-- _filter_by_direction
-- =============================================================================

T["_filter_by_direction"] = MiniTest.new_set()

T["_filter_by_direction"]["keeps targets after cursor"] = function()
	helpers.create_buf({ "aaa bbb ccc" })
	helpers.set_cursor(1, 4) -- at "bbb"

	local char_repeat = require("smart-motion.search.char_repeat")
	local winid = vim.api.nvim_get_current_win()

	local targets = {
		{ start_pos = { row = 0, col = 0 }, metadata = { winid = winid } },
		{ start_pos = { row = 0, col = 4 }, metadata = { winid = winid } },
		{ start_pos = { row = 0, col = 8 }, metadata = { winid = winid } },
	}

	local ctx = { cursor_line = 0, cursor_col = 4, winid = winid }
	local filtered = char_repeat._filter_by_direction(targets, ctx, "after_cursor")

	expect.equality(#filtered, 1)
	expect.equality(filtered[1].start_pos.col, 8)
end

T["_filter_by_direction"]["keeps targets before cursor"] = function()
	helpers.create_buf({ "aaa bbb ccc" })
	helpers.set_cursor(1, 4)

	local char_repeat = require("smart-motion.search.char_repeat")
	local winid = vim.api.nvim_get_current_win()

	local targets = {
		{ start_pos = { row = 0, col = 0 }, metadata = { winid = winid } },
		{ start_pos = { row = 0, col = 4 }, metadata = { winid = winid } },
		{ start_pos = { row = 0, col = 8 }, metadata = { winid = winid } },
	}

	local ctx = { cursor_line = 0, cursor_col = 4, winid = winid }
	local filtered = char_repeat._filter_by_direction(targets, ctx, "before_cursor")

	expect.equality(#filtered, 1)
	expect.equality(filtered[1].start_pos.col, 0)
end

T["_filter_by_direction"]["passes cross-window targets through"] = function()
	helpers.create_buf({ "aaa" })
	helpers.set_cursor(1, 0)

	local char_repeat = require("smart-motion.search.char_repeat")
	local winid = vim.api.nvim_get_current_win()
	local other_winid = winid + 999 -- fake other window

	local targets = {
		{ start_pos = { row = 0, col = 0 }, metadata = { winid = other_winid } },
	}

	local ctx = { cursor_line = 0, cursor_col = 5, winid = winid }
	local filtered = char_repeat._filter_by_direction(targets, ctx, "after_cursor")

	-- Cross-window targets always pass through
	expect.equality(#filtered, 1)
end

return T
