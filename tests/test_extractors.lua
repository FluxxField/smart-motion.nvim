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
-- Lines extractor
-- =============================================================================

T["lines extractor"] = MiniTest.new_set()

T["lines extractor"]["extracts line targets with correct positions"] = function()
	helpers.create_buf({ "  hello", "world", "  indented" })
	helpers.set_cursor(1, 0)

	local extractor = require("smart-motion.extractors.lines")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = { ignore_whitespace = true }
	local data = { line_number = 0, text = "  hello", metadata = {} }

	-- lines extractor returns a table directly, not a coroutine
	local result = extractor.run(ctx, cfg, ms, data)

	expect.no_equality(result, nil)
	expect.equality(result.text, "  hello")
	-- With ignore_whitespace, start_pos.col should be at first non-whitespace
	expect.equality(result.start_pos.col, 2)
	expect.equality(result.type, "lines")
end

T["lines extractor"]["handles empty line"] = function()
	helpers.create_buf({ "" })
	helpers.set_cursor(1, 0)

	local extractor = require("smart-motion.extractors.lines")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = { ignore_whitespace = true }
	local data = { line_number = 0, text = "", metadata = {} }

	local result = extractor.run(ctx, cfg, ms, data)

	-- Empty line should still produce a target at col 0
	expect.no_equality(result, nil)
	expect.equality(result.start_pos.col, 0)
end

-- =============================================================================
-- Pass-through extractor
-- =============================================================================

T["pass_through extractor"] = MiniTest.new_set()

T["pass_through extractor"]["returns data unchanged"] = function()
	helpers.create_buf({ "test" })

	local extractor = require("smart-motion.extractors.pass_through")
	local data = { text = "hello", start_pos = { row = 0, col = 0 }, end_pos = { row = 0, col = 5 } }

	-- pass_through returns data directly, not a coroutine
	local result = extractor.run(nil, nil, nil, data)

	expect.no_equality(result, nil)
	expect.equality(result.text, "hello")
end

-- =============================================================================
-- Extractor registry
-- =============================================================================

T["extractor registry"] = MiniTest.new_set()

T["extractor registry"]["all extractors are registered"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local extractors = registries.extractors

	local expected = { "words", "lines", "text_search_1_char", "text_search_2_char_until", "pass_through" }
	for _, name in ipairs(expected) do
		expect.no_equality(extractors.get_by_name(name), nil)
	end
end

T["extractor registry"]["words has key 'w'"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local extractors = registries.extractors

	local by_key = extractors.get_by_key("w")
	expect.no_equality(by_key, nil)
	expect.equality(by_key.name, "words")
end

T["extractor registry"]["text_search_1_char has key 'f'"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local extractors = registries.extractors

	local by_key = extractors.get_by_key("f")
	expect.no_equality(by_key, nil)
	expect.equality(by_key.name, "text_search_1_char")
end

T["extractor registry"]["text_search metadata sets num_of_char"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local extractors = registries.extractors

	local one_char = extractors.get_by_name("text_search_1_char")
	expect.equality(one_char.metadata.motion_state.num_of_char, 1)

	local two_char = extractors.get_by_name("text_search_2_char_until")
	expect.equality(two_char.metadata.motion_state.num_of_char, 2)
	expect.equality(two_char.metadata.motion_state.exclude_target, true)
end

return T
