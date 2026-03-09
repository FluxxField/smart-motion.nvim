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
-- text_search extractor .run()
-- =============================================================================

T["text_search run"] = MiniTest.new_set()

T["text_search run"]["finds literal matches in line"] = function()
	helpers.create_buf({ "hello world hello" })
	helpers.set_cursor(1, 0)

	local ts = require("smart-motion.extractors.text_search")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = { search_text = "hello" }
	local data = { text = "hello world hello", line_number = 0, metadata = {} }

	local co = ts.run(ctx, cfg, ms, data)
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
	expect.equality(results[2].start_pos.col, 12)
end

T["text_search run"]["returns empty for no match"] = function()
	helpers.create_buf({ "hello world" })
	helpers.set_cursor(1, 0)

	local ts = require("smart-motion.extractors.text_search")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = { search_text = "xyz" }
	local data = { text = "hello world", line_number = 0, metadata = {} }

	local co = ts.run(ctx, cfg, ms, data)
	local results = {}

	while coroutine.status(co) ~= "dead" do
		local ok, val = coroutine.resume(co)
		if ok and val then
			table.insert(results, val)
		else
			break
		end
	end

	expect.equality(#results, 0)
end

T["text_search run"]["sets correct target type"] = function()
	helpers.create_buf({ "foo" })
	helpers.set_cursor(1, 0)

	local ts = require("smart-motion.extractors.text_search")
	local consts = require("smart-motion.consts")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = { search_text = "foo" }
	local data = { text = "foo", line_number = 0, metadata = {} }

	local co = ts.run(ctx, cfg, ms, data)
	local ok, val = coroutine.resume(co)

	expect.equality(ok, true)
	expect.equality(val.type, consts.TARGET_TYPES.SEARCH)
end

T["text_search run"]["preserves metadata from data"] = function()
	helpers.create_buf({ "test" })
	helpers.set_cursor(1, 0)

	local ts = require("smart-motion.extractors.text_search")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = { search_text = "test" }
	local data = {
		text = "test",
		line_number = 0,
		metadata = { bufnr = 42, winid = 99 },
	}

	local co = ts.run(ctx, cfg, ms, data)
	local ok, val = coroutine.resume(co)

	expect.equality(ok, true)
	expect.equality(val.metadata.bufnr, 42)
	expect.equality(val.metadata.winid, 99)
end

-- =============================================================================
-- text_search metadata
-- =============================================================================

T["text_search metadata"] = MiniTest.new_set()

T["text_search metadata"]["has correct fields"] = function()
	local ts = require("smart-motion.extractors.text_search")

	expect.no_equality(ts.metadata, nil)
	expect.no_equality(ts.metadata.label, nil)
	expect.no_equality(ts.metadata.motion_state, nil)
	expect.equality(ts.metadata.motion_state.is_searching_mode, true)
	expect.equality(ts.metadata.motion_state.search_text, "")
end

-- =============================================================================
-- text_search extractor registry
-- =============================================================================

T["text_search registry"] = MiniTest.new_set()

T["text_search registry"]["text_search variants registered"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local extractors = registries.extractors

	-- 1-char and 2-char search extractors should be registered
	expect.no_equality(extractors.get_by_name("text_search_1_char"), nil)
	expect.no_equality(extractors.get_by_name("text_search_2_char"), nil)
	expect.no_equality(extractors.get_by_name("text_search_2_char_until"), nil)
end

T["text_search registry"]["1_char has num_of_char=1"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local ext = registries.extractors.get_by_name("text_search_1_char")

	expect.equality(ext.metadata.motion_state.num_of_char, 1)
end

T["text_search registry"]["2_char_until has exclude_target"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local ext = registries.extractors.get_by_name("text_search_2_char_until")

	expect.equality(ext.metadata.motion_state.num_of_char, 2)
	expect.equality(ext.metadata.motion_state.exclude_target, true)
end

return T
