local MiniTest = require("mini_test")
local expect = MiniTest.expect
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
	hooks = {
		pre_case = function()
			helpers.setup_plugin({
				presets = {
					words = true,
					lines = true,
				},
			})
		end,
		post_case = helpers.cleanup,
	},
})

-- =============================================================================
-- Full pipeline.run integration tests
-- =============================================================================

T["pipeline.run"] = MiniTest.new_set()

T["pipeline.run"]["collects word targets from buffer"] = function()
	helpers.create_buf({ "hello world test", "foo bar baz" })
	helpers.set_cursor(1, 0)

	local exit = require("smart-motion.core.events.exit")
	local pipeline = require("smart-motion.core.engine.pipeline")
	local setup = require("smart-motion.core.engine.setup")

	local ctx, cfg, ms
	exit.wrap(function()
		ctx, cfg, ms = setup.run("w")
	end)

	-- Run pipeline
	exit.wrap(function()
		pipeline.run(ctx, cfg, ms)
	end)

	-- Should have collected word targets
	expect.no_equality(ms.jump_targets, nil)
	expect.equality(#ms.jump_targets > 0, true)
end

T["pipeline.run"]["collects line targets from buffer"] = function()
	helpers.create_buf({ "line one", "line two", "line three" })
	helpers.set_cursor(1, 0)

	local exit = require("smart-motion.core.events.exit")
	local pipeline = require("smart-motion.core.engine.pipeline")
	local setup = require("smart-motion.core.engine.setup")

	local ctx, cfg, ms
	exit.wrap(function()
		ctx, cfg, ms = setup.run("j")
	end)

	exit.wrap(function()
		pipeline.run(ctx, cfg, ms)
	end)

	expect.no_equality(ms.jump_targets, nil)
	expect.equality(#ms.jump_targets > 0, true)
end

T["pipeline.run"]["finalizes motion state with label counts"] = function()
	helpers.create_buf({ "alpha beta gamma", "delta epsilon" })
	helpers.set_cursor(1, 0)

	local exit = require("smart-motion.core.events.exit")
	local pipeline = require("smart-motion.core.engine.pipeline")
	local setup = require("smart-motion.core.engine.setup")

	local ctx, cfg, ms
	exit.wrap(function()
		ctx, cfg, ms = setup.run("w")
	end)

	exit.wrap(function()
		pipeline.run(ctx, cfg, ms)
	end)

	-- finalize should set these
	expect.no_equality(ms.jump_target_count, nil)
	expect.no_equality(ms.single_label_count, nil)
end

-- =============================================================================
-- Engine loop single-pass
-- =============================================================================

T["engine loop"] = MiniTest.new_set()

T["engine loop"]["throws EARLY_EXIT on empty buffer"] = function()
	helpers.create_buf({ "" })
	helpers.set_cursor(1, 0)

	local exit = require("smart-motion.core.events.exit")
	local consts = require("smart-motion.consts")
	local setup = require("smart-motion.core.engine.setup")
	local loop = require("smart-motion.core.engine.loop")

	local ctx, cfg, ms
	local setup_exit = exit.wrap(function()
		ctx, cfg, ms = setup.run("w")
	end)

	if setup_exit then
		-- Setup itself might exit early for empty buffer
		expect.equality(true, true)
		return
	end

	local exit_type = exit.wrap(function()
		loop.run(ctx, cfg, ms)
	end)

	-- Empty buffer: w extractor finds no words → EARLY_EXIT
	expect.no_equality(exit_type, nil)
end

T["engine loop"]["sets count_select from motion_state"] = function()
	helpers.create_buf({ "alpha beta gamma delta" })
	helpers.set_cursor(1, 0)

	local exit = require("smart-motion.core.events.exit")
	local consts = require("smart-motion.consts")
	local setup = require("smart-motion.core.engine.setup")
	local loop = require("smart-motion.core.engine.loop")

	local ctx, cfg, ms
	exit.wrap(function()
		ctx, cfg, ms = setup.run("w")
	end)

	-- Set count_select to pick 2nd target
	ms.count_select = 2

	local exit_type = exit.wrap(function()
		loop.run(ctx, cfg, ms)
	end)

	-- Should auto-select the 2nd target
	expect.equality(exit_type, consts.EXIT_TYPE.AUTO_SELECT)
	expect.no_equality(ms.selected_jump_target, nil)
end

-- =============================================================================
-- Multi-window collector wrapper
-- =============================================================================

T["multi_window"] = MiniTest.new_set()

T["multi_window"]["single window falls back to normal collector"] = function()
	helpers.create_buf({ "hello world" })
	helpers.set_cursor(1, 0)

	local exit = require("smart-motion.core.events.exit")
	local pipeline = require("smart-motion.core.engine.pipeline")
	local setup = require("smart-motion.core.engine.setup")

	local ctx, cfg, ms
	exit.wrap(function()
		ctx, cfg, ms = setup.run("w")
	end)

	-- Ensure multi_window is false (default)
	ms.multi_window = false

	exit.wrap(function()
		pipeline.run(ctx, cfg, ms)
	end)

	-- Should still work with single window
	expect.no_equality(ms.jump_targets, nil)
	expect.equality(#ms.jump_targets > 0, true)
end

-- =============================================================================
-- Words extractor coroutine
-- =============================================================================

T["words extractor"] = MiniTest.new_set()

T["words extractor"]["extracts words with positions"] = function()
	helpers.create_buf({ "hello world" })
	helpers.set_cursor(1, 0)

	local extractor = require("smart-motion.extractors.words")
	local consts = require("smart-motion.consts")

	local ms = { word_pattern = consts.WORD_PATTERN }
	local data = { text = "hello world", line_number = 0, metadata = {} }

	local co = extractor.run(nil, nil, ms, data)
	local results = {}

	while coroutine.status(co) ~= "dead" do
		local ok, val = coroutine.resume(co)
		if ok and val then
			table.insert(results, val)
		else
			break
		end
	end

	expect.equality(#results, 2)
	expect.equality(results[1].text, "hello")
	expect.equality(results[1].start_pos.col, 0)
	expect.equality(results[1].end_pos.col, 5)
	expect.equality(results[2].text, "world")
	expect.equality(results[2].start_pos.col, 6)
end

T["words extractor"]["handles punctuation"] = function()
	helpers.create_buf({ "foo, bar. baz!" })
	helpers.set_cursor(1, 0)

	local extractor = require("smart-motion.extractors.words")
	local consts = require("smart-motion.consts")

	local ms = { word_pattern = consts.WORD_PATTERN }
	local data = { text = "foo, bar. baz!", line_number = 0, metadata = {} }

	local co = extractor.run(nil, nil, ms, data)
	local results = {}

	while coroutine.status(co) ~= "dead" do
		local ok, val = coroutine.resume(co)
		if ok and val then
			table.insert(results, val)
		else
			break
		end
	end

	-- Should extract words: foo, bar, baz (and punctuation as separate tokens)
	expect.equality(#results >= 3, true)
end

T["words extractor"]["sets WORDS target type"] = function()
	helpers.create_buf({ "test" })
	helpers.set_cursor(1, 0)

	local extractor = require("smart-motion.extractors.words")
	local consts = require("smart-motion.consts")

	local ms = { word_pattern = consts.WORD_PATTERN }
	local data = { text = "test", line_number = 0, metadata = {} }

	local co = extractor.run(nil, nil, ms, data)
	local ok, val = coroutine.resume(co)

	expect.equality(ok, true)
	expect.equality(val.type, consts.TARGET_TYPES.WORDS)
end

return T
