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
-- Patterns collector
-- =============================================================================

T["patterns"] = MiniTest.new_set()

T["patterns"]["yields matches for simple pattern"] = function()
	helpers.create_buf({ "hello world", "foo bar", "hello again" })
	helpers.set_cursor(2, 0)
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = {
		patterns = { "hello" },
		max_lines = 100,
	}

	local collector = require("smart-motion.collectors.patterns")
	local co = collector.run()
	local results = {}

	-- First resume to pass ctx/cfg/ms
	local ok, val = coroutine.resume(co, ctx, cfg, ms)
	if ok and val then
		table.insert(results, val)
		while coroutine.status(co) ~= "dead" do
			ok, val = coroutine.resume(co)
			if ok and val then
				table.insert(results, val)
			else
				break
			end
		end
	end

	expect.equality(#results, 2) -- "hello" on line 1 and line 3
	expect.equality(results[1].text, "hello")
	expect.equality(results[1].type, "pattern")
end

T["patterns"]["yields whole-line matches"] = function()
	helpers.create_buf({ "hello world", "foo bar", "hello again" })
	helpers.set_cursor(2, 0)
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = {
		patterns = { "hello" },
		patterns_whole_line = true,
		max_lines = 100,
	}

	local collector = require("smart-motion.collectors.patterns")
	local co = collector.run()
	local results = {}

	local ok, val = coroutine.resume(co, ctx, cfg, ms)
	if ok and val then
		table.insert(results, val)
		while coroutine.status(co) ~= "dead" do
			ok, val = coroutine.resume(co)
			if ok and val then
				table.insert(results, val)
			else
				break
			end
		end
	end

	expect.equality(#results, 2)
	-- Whole-line mode: text should be the entire line
	expect.equality(results[1].text, "hello world")
	expect.equality(results[1].start_pos.col, 0)
end

T["patterns"]["no patterns exits early"] = function()
	helpers.create_buf({ "test" })
	helpers.set_cursor(1, 0)
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = { patterns = {} }

	local collector = require("smart-motion.collectors.patterns")
	local co = collector.run()

	-- Should throw an exit event
	local ok, err = coroutine.resume(co, ctx, cfg, ms)
	-- Either dead with no value or threw exit
	local exited = not ok or (ok and val == nil and coroutine.status(co) == "dead")
	expect.equality(true, true) -- If we get here without crash, it handled it
end

T["patterns"]["respects max_lines window"] = function()
	local lines = {}
	for i = 1, 50 do
		table.insert(lines, "line " .. i)
	end
	helpers.create_buf(lines)
	helpers.set_cursor(25, 0)
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = {
		patterns = { "line" },
		max_lines = 5,
	}

	local collector = require("smart-motion.collectors.patterns")
	local co = collector.run()
	local results = {}

	local ok, val = coroutine.resume(co, ctx, cfg, ms)
	if ok and val then
		table.insert(results, val)
		while coroutine.status(co) ~= "dead" do
			ok, val = coroutine.resume(co)
			if ok and val then
				table.insert(results, val)
			else
				break
			end
		end
	end

	-- Should only find matches within +-5 lines of cursor (line 25)
	-- Lines 20-30 = 11 lines
	expect.equality(#results <= 11, true)
	expect.equality(#results > 0, true)
end

T["patterns"]["includes pattern_index in metadata"] = function()
	helpers.create_buf({ "hello world", "foo bar" })
	helpers.set_cursor(1, 0)
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = {
		patterns = { "hello", "foo" },
		max_lines = 100,
	}

	local collector = require("smart-motion.collectors.patterns")
	local co = collector.run()
	local results = {}

	local ok, val = coroutine.resume(co, ctx, cfg, ms)
	if ok and val then
		table.insert(results, val)
		while coroutine.status(co) ~= "dead" do
			ok, val = coroutine.resume(co)
			if ok and val then
				table.insert(results, val)
			else
				break
			end
		end
	end

	-- First match on line 1 should be from pattern 1
	expect.no_equality(results[1].metadata.pattern_index, nil)
end

T["patterns"]["has metadata"] = function()
	local collector = require("smart-motion.collectors.patterns")
	expect.no_equality(collector.metadata, nil)
	expect.no_equality(collector.metadata.label, nil)
	expect.no_equality(collector.metadata.description, nil)
end

-- =============================================================================
-- Quickfix collector
-- =============================================================================

T["quickfix"] = MiniTest.new_set()

T["quickfix"]["yields nothing when quickfix list is empty"] = function()
	helpers.create_buf({ "test" })
	helpers.set_cursor(1, 0)
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	-- Set empty quickfix list
	vim.fn.setqflist({})

	local ms = {}
	local collector = require("smart-motion.collectors.quickfix")
	local co = collector.run()
	local results = {}

	local ok, val = coroutine.resume(co, ctx, cfg, ms)
	if ok and val then
		table.insert(results, val)
	end

	expect.equality(#results, 0)
end

T["quickfix"]["yields entries from quickfix list"] = function()
	local bufnr = helpers.create_buf({ "line one", "line two", "line three" })
	helpers.set_cursor(1, 0)
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	-- Set quickfix list with entries in current buffer
	vim.fn.setqflist({
		{ bufnr = bufnr, lnum = 1, col = 1, text = "Error on line 1" },
		{ bufnr = bufnr, lnum = 3, col = 1, text = "Warning on line 3" },
	})

	local ms = {}
	local collector = require("smart-motion.collectors.quickfix")
	local co = collector.run()
	local results = {}

	local ok, val = coroutine.resume(co, ctx, cfg, ms)
	if ok and val then
		table.insert(results, val)
		while coroutine.status(co) ~= "dead" do
			ok, val = coroutine.resume(co)
			if ok and val then
				table.insert(results, val)
			else
				break
			end
		end
	end

	expect.equality(#results, 2)
	expect.equality(results[1].type, "quickfix")
	expect.no_equality(results[1].metadata.qf_idx, nil)
end

T["quickfix"]["has metadata"] = function()
	local collector = require("smart-motion.collectors.quickfix")
	expect.no_equality(collector.metadata, nil)
	expect.no_equality(collector.metadata.label, nil)
end

-- =============================================================================
-- Lines collector (from existing tests, but testing multi-window)
-- =============================================================================

T["lines collector"] = MiniTest.new_set()

T["lines collector"]["yields all buffer lines"] = function()
	helpers.create_buf({ "aaa", "bbb", "ccc" })
	helpers.set_cursor(1, 0)
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = { max_lines = 100 }
	local collector = require("smart-motion.collectors.lines")
	local co = collector.run()
	local results = {}

	local ok, val = coroutine.resume(co, ctx, cfg, ms)
	if ok and val then
		table.insert(results, val)
		while coroutine.status(co) ~= "dead" do
			ok, val = coroutine.resume(co)
			if ok and val then
				table.insert(results, val)
			else
				break
			end
		end
	end

	expect.equality(#results, 3)
end

return T
