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

-- Helper: build a target at position
local function make_target(row, col, end_col, text, opts)
	opts = opts or {}
	return {
		start_pos = { row = row, col = col },
		end_pos = { row = row, col = end_col },
		text = text or "",
		metadata = opts.metadata or {},
	}
end

-- =============================================================================
-- filter_lines_before_cursor
-- =============================================================================

T["lines before cursor"] = MiniTest.new_set()

T["lines before cursor"]["keeps targets before cursor row"] = function()
	helpers.create_buf({ "line1", "line2", "line3" })
	helpers.set_cursor(3, 0) -- cursor on line3 (0-indexed row 2)

	local filter = require("smart-motion.filters.filter_lines_before_cursor")
	local ctx = helpers.build_ctx()

	local target = make_target(0, 0, 5, "line1")
	expect.no_equality(filter.run(ctx, nil, nil, target), nil)
end

T["lines before cursor"]["removes targets after cursor row"] = function()
	helpers.create_buf({ "line1", "line2", "line3" })
	helpers.set_cursor(1, 0) -- cursor on line1 (row 0)

	local filter = require("smart-motion.filters.filter_lines_before_cursor")
	local ctx = helpers.build_ctx()

	local target = make_target(2, 0, 5, "line3")
	expect.equality(filter.run(ctx, nil, nil, target), nil)
end

T["lines before cursor"]["removes targets on cursor row"] = function()
	helpers.create_buf({ "line1", "line2", "line3" })
	helpers.set_cursor(2, 0)

	local filter = require("smart-motion.filters.filter_lines_before_cursor")
	local ctx = helpers.build_ctx()

	local target = make_target(1, 0, 5, "line2") -- same row as cursor
	expect.equality(filter.run(ctx, nil, nil, target), nil)
end

-- =============================================================================
-- filter_words_before_cursor
-- =============================================================================

T["words before cursor"] = MiniTest.new_set()

T["words before cursor"]["keeps words before cursor on same line"] = function()
	helpers.create_buf({ "foo bar baz" })
	helpers.set_cursor(1, 8) -- cursor at "baz"

	local filter = require("smart-motion.filters.filter_words_before_cursor")
	local ctx = helpers.build_ctx()
	local ms = { hint_position = "start" }

	-- "foo" at col 0, before cursor col 8
	local target = make_target(0, 0, 3, "foo")
	expect.no_equality(filter.run(ctx, nil, ms, target), nil)
end

T["words before cursor"]["removes words after cursor on same line"] = function()
	helpers.create_buf({ "foo bar baz" })
	helpers.set_cursor(1, 0) -- cursor at "foo"

	local filter = require("smart-motion.filters.filter_words_before_cursor")
	local ctx = helpers.build_ctx()
	local ms = { hint_position = "start" }

	-- "baz" at col 8, after cursor col 0
	local target = make_target(0, 8, 11, "baz")
	expect.equality(filter.run(ctx, nil, ms, target), nil)
end

T["words before cursor"]["keeps all words on lines before cursor"] = function()
	helpers.create_buf({ "first", "second" })
	helpers.set_cursor(2, 0) -- cursor on line 2

	local filter = require("smart-motion.filters.filter_words_before_cursor")
	local ctx = helpers.build_ctx()
	local ms = { hint_position = "start" }

	local target = make_target(0, 0, 5, "first") -- line 1 = before cursor
	expect.no_equality(filter.run(ctx, nil, ms, target), nil)
end

-- =============================================================================
-- filter_lines_around_cursor
-- =============================================================================

T["lines around cursor"] = MiniTest.new_set()

T["lines around cursor"]["keeps targets on different rows"] = function()
	helpers.create_buf({ "above", "cursor", "below" })
	helpers.set_cursor(2, 0) -- cursor on "cursor" (row 1)

	local filter = require("smart-motion.filters.filter_lines_around_cursor")
	local ctx = helpers.build_ctx()

	expect.no_equality(filter.run(ctx, nil, nil, make_target(0, 0, 5, "above")), nil)
	expect.no_equality(filter.run(ctx, nil, nil, make_target(2, 0, 5, "below")), nil)
end

T["lines around cursor"]["removes targets on cursor row"] = function()
	helpers.create_buf({ "above", "cursor", "below" })
	helpers.set_cursor(2, 0)

	local filter = require("smart-motion.filters.filter_lines_around_cursor")
	local ctx = helpers.build_ctx()

	expect.equality(filter.run(ctx, nil, nil, make_target(1, 0, 6, "cursor")), nil)
end

-- =============================================================================
-- filter_words_around_cursor
-- =============================================================================

T["words around cursor"] = MiniTest.new_set()

T["words around cursor"]["keeps words on different rows"] = function()
	helpers.create_buf({ "above", "cursor word", "below" })
	helpers.set_cursor(2, 0)

	local filter = require("smart-motion.filters.filter_words_around_cursor")
	local ctx = helpers.build_ctx()
	local ms = { hint_position = "start" }

	expect.no_equality(filter.run(ctx, nil, ms, make_target(0, 0, 5, "above")), nil)
	expect.no_equality(filter.run(ctx, nil, ms, make_target(2, 0, 5, "below")), nil)
end

T["words around cursor"]["keeps words on same row not at cursor col"] = function()
	helpers.create_buf({ "foo bar baz" })
	helpers.set_cursor(1, 4) -- cursor at "bar" col 4

	local filter = require("smart-motion.filters.filter_words_around_cursor")
	local ctx = helpers.build_ctx()
	local ms = { hint_position = "start" }

	-- "foo" at col 0, not at cursor col 4
	expect.no_equality(filter.run(ctx, nil, ms, make_target(0, 0, 3, "foo")), nil)
	-- "baz" at col 8
	expect.no_equality(filter.run(ctx, nil, ms, make_target(0, 8, 11, "baz")), nil)
end

T["words around cursor"]["removes word exactly at cursor col (start hint)"] = function()
	helpers.create_buf({ "foo bar baz" })
	helpers.set_cursor(1, 4) -- cursor at col 4

	local filter = require("smart-motion.filters.filter_words_around_cursor")
	local ctx = helpers.build_ctx()
	local ms = { hint_position = "start" }

	-- target starts at col 4, same as cursor
	expect.equality(filter.run(ctx, nil, ms, make_target(0, 4, 7, "bar")), nil)
end

-- =============================================================================
-- filter_cursor_line_only
-- =============================================================================

T["cursor line only"] = MiniTest.new_set()

T["cursor line only"]["keeps targets on cursor row"] = function()
	helpers.create_buf({ "line1", "line2", "line3" })
	helpers.set_cursor(2, 0) -- cursor on line2 (row 1)

	local filter = require("smart-motion.filters.filter_cursor_line_only")
	local ctx = helpers.build_ctx()

	expect.no_equality(filter.run(ctx, nil, nil, make_target(1, 0, 5, "line2")), nil)
end

T["cursor line only"]["removes targets on other rows"] = function()
	helpers.create_buf({ "line1", "line2", "line3" })
	helpers.set_cursor(2, 0)

	local filter = require("smart-motion.filters.filter_cursor_line_only")
	local ctx = helpers.build_ctx()

	expect.equality(filter.run(ctx, nil, nil, make_target(0, 0, 5, "line1")), nil)
	expect.equality(filter.run(ctx, nil, nil, make_target(2, 0, 5, "line3")), nil)
end

-- =============================================================================
-- filter_visible_lines
-- =============================================================================

T["visible lines"] = MiniTest.new_set()

T["visible lines"]["keeps targets within window bounds"] = function()
	helpers.create_buf({ "line1", "line2", "line3" })
	helpers.set_cursor(1, 0)

	local filter = require("smart-motion.filters.filter_visible_lines")
	local ctx = helpers.build_ctx()

	-- In a test window, all lines should be visible
	expect.no_equality(filter.run(ctx, nil, nil, make_target(0, 0, 5, "line1")), nil)
	expect.no_equality(filter.run(ctx, nil, nil, make_target(1, 0, 5, "line2")), nil)
	expect.no_equality(filter.run(ctx, nil, nil, make_target(2, 0, 5, "line3")), nil)
end

-- =============================================================================
-- first_target filter
-- =============================================================================

T["first target"] = MiniTest.new_set()

T["first target"]["sets selected target and throws AUTO_SELECT"] = function()
	helpers.create_buf({ "test" })

	local filter = require("smart-motion.filters.first_target")
	local exit_event = require("smart-motion.core.events.exit")
	local consts = require("smart-motion.consts")
	local ctx = helpers.build_ctx()

	local ms = {}
	local target = make_target(0, 0, 4, "test")

	local exit_type = exit_event.wrap(function()
		filter.run(ctx, nil, ms, target)
	end)

	expect.equality(exit_type, consts.EXIT_TYPE.AUTO_SELECT)
	expect.equality(ms.selected_jump_target.text, "test")
end

-- =============================================================================
-- filter utils merge
-- =============================================================================

T["filter merge"] = MiniTest.new_set()

T["filter merge"]["chains multiple filters"] = function()
	local filter_utils = require("smart-motion.filters.utils")

	-- Filter 1: only keep targets with text length > 2
	local f1 = function(ctx, cfg, ms, data)
		if #data.text > 2 then
			return data
		end
		return nil
	end

	-- Filter 2: only keep targets on row 0
	local f2 = function(ctx, cfg, ms, data)
		if data.start_pos.row == 0 then
			return data
		end
		return nil
	end

	local merged = filter_utils.merge({ f1, f2 })

	-- Passes both filters
	local result = merged(nil, nil, nil, make_target(0, 0, 5, "hello"))
	expect.no_equality(result, nil)

	-- Fails f1 (text too short)
	result = merged(nil, nil, nil, make_target(0, 0, 2, "hi"))
	expect.equality(result, nil)

	-- Fails f2 (wrong row)
	result = merged(nil, nil, nil, make_target(1, 0, 5, "hello"))
	expect.equality(result, nil)
end

-- =============================================================================
-- Multi-window bypass: targets from other windows pass through direction filters
-- =============================================================================

T["multi window bypass"] = MiniTest.new_set()

T["multi window bypass"]["after cursor filter passes through other-window targets"] = function()
	helpers.create_buf({ "line1", "line2" })
	helpers.set_cursor(2, 0) -- cursor on line2 (row 1)

	local filter = require("smart-motion.filters.filter_lines_after_cursor")
	local ctx = helpers.build_ctx()

	-- Target from a different window (winid != ctx.winid)
	local target = make_target(0, 0, 5, "line1", { metadata = { winid = 99999 } })
	expect.no_equality(filter.run(ctx, nil, nil, target), nil)
end

T["multi window bypass"]["before cursor filter passes through other-window targets"] = function()
	helpers.create_buf({ "line1", "line2" })
	helpers.set_cursor(1, 0) -- cursor on line1 (row 0)

	local filter = require("smart-motion.filters.filter_lines_before_cursor")
	local ctx = helpers.build_ctx()

	-- Target from a different window, after cursor, but should pass through
	local target = make_target(5, 0, 5, "far", { metadata = { winid = 99999 } })
	expect.no_equality(filter.run(ctx, nil, nil, target), nil)
end

return T
