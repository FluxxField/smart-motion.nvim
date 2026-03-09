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
-- Lines collector
-- =============================================================================

T["lines collector"] = MiniTest.new_set()

T["lines collector"]["yields all lines in buffer"] = function()
	helpers.create_buf({ "alpha", "beta", "gamma", "delta" })
	helpers.set_cursor(1, 0)

	local collector = require("smart-motion.collectors.lines")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()

	local co = collector.run()
	local lines = {}
	local ok, val = coroutine.resume(co, ctx, cfg, ms)

	while ok and val do
		table.insert(lines, val)
		ok, val = coroutine.resume(co)
	end

	expect.equality(#lines, 4)
	expect.equality(lines[1].text, "alpha")
	expect.equality(lines[1].line_number, 0)
	expect.equality(lines[4].text, "delta")
	expect.equality(lines[4].line_number, 3)
end

T["lines collector"]["includes line numbers (0-indexed)"] = function()
	helpers.create_buf({ "line1", "line2", "line3" })
	helpers.set_cursor(2, 0) -- cursor on "line2"

	local collector = require("smart-motion.collectors.lines")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()

	local co = collector.run()
	local lines = {}
	local ok, val = coroutine.resume(co, ctx, cfg, ms)

	while ok and val do
		table.insert(lines, val)
		ok, val = coroutine.resume(co)
	end

	-- All 3 lines should be collected regardless of cursor position
	expect.equality(#lines, 3)
	-- line_number is 0-indexed
	expect.equality(lines[1].line_number, 0)
	expect.equality(lines[2].line_number, 1)
	expect.equality(lines[3].line_number, 2)
end

-- =============================================================================
-- Words extractor
-- =============================================================================

T["words extractor"] = MiniTest.new_set()

T["words extractor"]["extracts words from a line"] = function()
	helpers.create_buf({ "hello world test" })
	helpers.set_cursor(1, 0)

	local words = require("smart-motion.extractors.words")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local consts = require("smart-motion.consts")

	local motion_state = {
		word_pattern = consts.WORD_PATTERN,
	}

	local data = {
		line_number = 0,
		text = "hello world test",
		metadata = {},
	}

	local co = words.run(ctx, cfg, motion_state, data)
	local targets = {}
	local ok, val = coroutine.resume(co)

	while ok and val do
		table.insert(targets, val)
		ok, val = coroutine.resume(co)
	end

	expect.equality(#targets, 3)
	expect.equality(targets[1].text, "hello")
	expect.equality(targets[2].text, "world")
	expect.equality(targets[3].text, "test")
end

T["words extractor"]["sets correct start_pos and end_pos"] = function()
	helpers.create_buf({ "foo bar" })
	helpers.set_cursor(1, 0)

	local words = require("smart-motion.extractors.words")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local consts = require("smart-motion.consts")

	local motion_state = { word_pattern = consts.WORD_PATTERN }
	local data = { line_number = 2, text = "foo bar", metadata = {} }

	local co = words.run(ctx, cfg, motion_state, data)
	local targets = {}
	local ok, val = coroutine.resume(co)

	while ok and val do
		table.insert(targets, val)
		ok, val = coroutine.resume(co)
	end

	-- "foo" at col 0-3, "bar" at col 4-7
	expect.equality(targets[1].start_pos.row, 2)
	expect.equality(targets[1].start_pos.col, 0)
	expect.equality(targets[1].end_pos.col, 3)
	expect.equality(targets[2].start_pos.col, 4)
	expect.equality(targets[2].end_pos.col, 7)
end

T["words extractor"]["handles empty line"] = function()
	helpers.create_buf({ "" })
	helpers.set_cursor(1, 0)

	local words = require("smart-motion.extractors.words")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local consts = require("smart-motion.consts")

	local motion_state = { word_pattern = consts.WORD_PATTERN }
	local data = { line_number = 0, text = "", metadata = {} }

	local co = words.run(ctx, cfg, motion_state, data)
	local targets = {}
	local ok, val = coroutine.resume(co)

	while ok and val do
		table.insert(targets, val)
		ok, val = coroutine.resume(co)
	end

	expect.equality(#targets, 0)
end

T["words extractor"]["extracts punctuation as separate targets"] = function()
	helpers.create_buf({ "a + b" })
	helpers.set_cursor(1, 0)

	local words = require("smart-motion.extractors.words")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local consts = require("smart-motion.consts")

	local motion_state = { word_pattern = consts.WORD_PATTERN }
	local data = { line_number = 0, text = "a + b", metadata = {} }

	local co = words.run(ctx, cfg, motion_state, data)
	local targets = {}
	local ok, val = coroutine.resume(co)

	while ok and val do
		table.insert(targets, val)
		ok, val = coroutine.resume(co)
	end

	-- "a", "+", "b" are 3 separate targets
	expect.equality(#targets, 3)
	expect.equality(targets[1].text, "a")
	expect.equality(targets[2].text, "+")
	expect.equality(targets[3].text, "b")
end

T["words extractor"]["sets target type to words"] = function()
	helpers.create_buf({ "test" })
	helpers.set_cursor(1, 0)

	local words = require("smart-motion.extractors.words")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local consts = require("smart-motion.consts")

	local motion_state = { word_pattern = consts.WORD_PATTERN }
	local data = { line_number = 0, text = "test", metadata = {} }

	local co = words.run(ctx, cfg, motion_state, data)
	local ok, val = coroutine.resume(co)

	expect.equality(ok, true)
	expect.equality(val.type, consts.TARGET_TYPES.WORDS)
end

-- =============================================================================
-- Default modifier
-- =============================================================================

T["default modifier"] = MiniTest.new_set()

T["default modifier"]["passes target through unchanged"] = function()
	local modifier = require("smart-motion.modifiers.default")
	local target = { text = "hello", start_pos = { row = 0, col = 0 }, end_pos = { row = 0, col = 5 } }

	local result = modifier.run(nil, nil, nil, target)

	expect.equality(result.text, "hello")
	expect.equality(result.start_pos.row, 0)
	expect.equality(result.start_pos.col, 0)
end

-- =============================================================================
-- Default filter
-- =============================================================================

T["default filter"] = MiniTest.new_set()

T["default filter"]["passes all targets through"] = function()
	local filter = require("smart-motion.filters.default")
	local target = { text = "hello", start_pos = { row = 0, col = 0 }, end_pos = { row = 0, col = 5 } }

	local result = filter.run(nil, nil, nil, target)

	expect.equality(result.text, "hello")
end

-- =============================================================================
-- Direction filters
-- =============================================================================

T["after cursor filter"] = MiniTest.new_set()

T["after cursor filter"]["keeps targets after cursor row"] = function()
	helpers.create_buf({ "line1", "line2", "line3" })
	helpers.set_cursor(2, 0) -- cursor on line2 (0-indexed row 1)

	local filter = require("smart-motion.filters.filter_lines_after_cursor")
	local ctx = helpers.build_ctx()

	-- Target on line3 (0-indexed row 2) - after cursor
	local target_after = { start_pos = { row = 2, col = 0 }, end_pos = { row = 2, col = 5 }, text = "line3" }
	local result = filter.run(ctx, nil, nil, target_after)
	expect.no_equality(result, nil)
end

T["after cursor filter"]["removes targets before cursor row"] = function()
	helpers.create_buf({ "line1", "line2", "line3" })
	helpers.set_cursor(2, 0) -- cursor on line2 (0-indexed row 1)

	local filter = require("smart-motion.filters.filter_lines_after_cursor")
	local ctx = helpers.build_ctx()

	-- Target on line1 (0-indexed row 0) - before cursor
	local target_before = { start_pos = { row = 0, col = 0 }, end_pos = { row = 0, col = 5 }, text = "line1" }
	local result = filter.run(ctx, nil, nil, target_before)
	expect.equality(result, nil)
end

T["after cursor filter"]["removes targets on cursor row"] = function()
	helpers.create_buf({ "line1", "line2", "line3" })
	helpers.set_cursor(2, 0)

	local filter = require("smart-motion.filters.filter_lines_after_cursor")
	local ctx = helpers.build_ctx()

	-- Target on cursor row
	local target_same = { start_pos = { row = 1, col = 0 }, end_pos = { row = 1, col = 5 }, text = "line2" }
	local result = filter.run(ctx, nil, nil, target_same)
	expect.equality(result, nil)
end

T["words after cursor filter"] = MiniTest.new_set()

T["words after cursor filter"]["keeps words after cursor on same line"] = function()
	helpers.create_buf({ "foo bar baz" })
	helpers.set_cursor(1, 2) -- cursor at col 2 in "foo"

	local filter = require("smart-motion.filters.filter_words_after_cursor")
	local ctx = helpers.build_ctx()
	local motion_state = { hint_position = "start" }

	-- "bar" starts at col 4, after cursor col 2
	local target = { start_pos = { row = 0, col = 4 }, end_pos = { row = 0, col = 7 }, text = "bar" }
	local result = filter.run(ctx, nil, motion_state, target)
	expect.no_equality(result, nil)
end

T["words after cursor filter"]["removes words before cursor on same line"] = function()
	helpers.create_buf({ "foo bar baz" })
	helpers.set_cursor(1, 6) -- cursor at col 6 in "bar"

	local filter = require("smart-motion.filters.filter_words_after_cursor")
	local ctx = helpers.build_ctx()
	local motion_state = { hint_position = "start" }

	-- "foo" starts at col 0, before cursor col 6
	local target = { start_pos = { row = 0, col = 0 }, end_pos = { row = 0, col = 3 }, text = "foo" }
	local result = filter.run(ctx, nil, motion_state, target)
	expect.equality(result, nil)
end

T["words after cursor filter"]["keeps all words on lines after cursor"] = function()
	helpers.create_buf({ "first", "second" })
	helpers.set_cursor(1, 3) -- cursor on line 1

	local filter = require("smart-motion.filters.filter_words_after_cursor")
	local ctx = helpers.build_ctx()
	local motion_state = { hint_position = "start" }

	-- Target on line 2 (row 1) - different line after cursor
	local target = { start_pos = { row = 1, col = 0 }, end_pos = { row = 1, col = 6 }, text = "second" }
	local result = filter.run(ctx, nil, motion_state, target)
	expect.no_equality(result, nil)
end

-- =============================================================================
-- Collector + Extractor integration
-- =============================================================================

T["collector extractor"] = MiniTest.new_set()

T["collector extractor"]["lines collector feeds words extractor"] = function()
	helpers.create_buf({ "hello world", "foo bar" })
	helpers.set_cursor(1, 0)

	local lines_collector = require("smart-motion.collectors.lines")
	local words_extractor = require("smart-motion.extractors.words")
	local consts = require("smart-motion.consts")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()
	ms.word_pattern = consts.WORD_PATTERN

	-- Collect lines
	local co = lines_collector.run()
	local collected_lines = {}
	local ok, val = coroutine.resume(co, ctx, cfg, ms)

	while ok and val do
		table.insert(collected_lines, val)
		ok, val = coroutine.resume(co)
	end

	-- Extract words from all collected lines
	local all_targets = {}
	for _, line_data in ipairs(collected_lines) do
		line_data.metadata = {}
		local word_co = words_extractor.run(ctx, cfg, ms, line_data)
		local wok, wval = coroutine.resume(word_co)

		while wok and wval do
			table.insert(all_targets, wval)
			wok, wval = coroutine.resume(word_co)
		end
	end

	-- Should have 4 targets: hello, world, foo, bar
	expect.equality(#all_targets, 4)
	expect.equality(all_targets[1].text, "hello")
	expect.equality(all_targets[2].text, "world")
	expect.equality(all_targets[3].text, "foo")
	expect.equality(all_targets[4].text, "bar")
end

T["collector extractor"]["targets have correct line associations"] = function()
	helpers.create_buf({ "alpha", "beta gamma" })
	helpers.set_cursor(1, 0)

	local lines_collector = require("smart-motion.collectors.lines")
	local words_extractor = require("smart-motion.extractors.words")
	local consts = require("smart-motion.consts")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()
	ms.word_pattern = consts.WORD_PATTERN

	local co = lines_collector.run()
	local collected_lines = {}
	local ok, val = coroutine.resume(co, ctx, cfg, ms)

	while ok and val do
		table.insert(collected_lines, val)
		ok, val = coroutine.resume(co)
	end

	local all_targets = {}
	for _, line_data in ipairs(collected_lines) do
		line_data.metadata = {}
		local word_co = words_extractor.run(ctx, cfg, ms, line_data)
		local wok, wval = coroutine.resume(word_co)

		while wok and wval do
			table.insert(all_targets, wval)
			wok, wval = coroutine.resume(word_co)
		end
	end

	-- "alpha" is on row 0, "beta" and "gamma" on row 1
	expect.equality(all_targets[1].start_pos.row, 0)
	expect.equality(all_targets[2].start_pos.row, 1)
	expect.equality(all_targets[3].start_pos.row, 1)
end

-- =============================================================================
-- Full pipeline: collect → extract → filter
-- =============================================================================

T["full pipeline"] = MiniTest.new_set()

T["full pipeline"]["collect + extract + filter after cursor"] = function()
	helpers.create_buf({ "above", "cursor", "below one", "below two" })
	helpers.set_cursor(2, 0) -- cursor on "cursor" (0-indexed row 1)

	local lines_collector = require("smart-motion.collectors.lines")
	local words_extractor = require("smart-motion.extractors.words")
	local after_filter = require("smart-motion.filters.filter_lines_after_cursor")
	local consts = require("smart-motion.consts")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()
	ms.word_pattern = consts.WORD_PATTERN

	-- Step 1: Collect lines
	local co = lines_collector.run()
	local collected = {}
	local ok, val = coroutine.resume(co, ctx, cfg, ms)

	while ok and val do
		table.insert(collected, val)
		ok, val = coroutine.resume(co)
	end

	-- Step 2: Extract words
	local targets = {}
	for _, line_data in ipairs(collected) do
		line_data.metadata = {}
		local word_co = words_extractor.run(ctx, cfg, ms, line_data)
		local wok, wval = coroutine.resume(word_co)

		while wok and wval do
			table.insert(targets, wval)
			wok, wval = coroutine.resume(word_co)
		end
	end

	-- Step 3: Filter to after cursor only
	local filtered = {}
	for _, target in ipairs(targets) do
		local result = after_filter.run(ctx, cfg, ms, target)
		if result then
			table.insert(filtered, result)
		end
	end

	-- "above" (row 0) and "cursor" (row 1) should be filtered out
	-- Only "below", "one", "below", "two" from rows 2,3 should remain
	expect.equality(#filtered, 4)

	for _, target in ipairs(filtered) do
		expect.equality(target.start_pos.row > 1, true)
	end
end

return T
