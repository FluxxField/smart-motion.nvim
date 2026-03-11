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
-- Composed filter registrations
-- =============================================================================

T["composed filters"] = MiniTest.new_set()

T["composed filters"]["filter_words_on_cursor_line_after_cursor is registered"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local f = registries.filters.get_by_name("filter_words_on_cursor_line_after_cursor")
	expect.no_equality(f, nil)
	expect.no_equality(f.run, nil)
	expect.equality(f.metadata.merged, true)
end

T["composed filters"]["filter_words_on_cursor_line_before_cursor is registered"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local f = registries.filters.get_by_name("filter_words_on_cursor_line_before_cursor")
	expect.no_equality(f, nil)
	expect.no_equality(f.run, nil)
end

T["composed filters"]["filter_lines_after_cursor has direction metadata"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local consts = require("smart-motion.consts")
	local f = registries.filters.get_by_name("filter_lines_after_cursor")

	expect.no_equality(f.metadata.motion_state, nil)
	expect.equality(f.metadata.motion_state.direction, consts.DIRECTION.AFTER_CURSOR)
end

T["composed filters"]["filter_lines_before_cursor has direction metadata"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local consts = require("smart-motion.consts")
	local f = registries.filters.get_by_name("filter_lines_before_cursor")

	expect.equality(f.metadata.motion_state.direction, consts.DIRECTION.BEFORE_CURSOR)
end

T["composed filters"]["filter_words_around_cursor has BOTH direction"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local consts = require("smart-motion.consts")
	local f = registries.filters.get_by_name("filter_words_around_cursor")

	expect.equality(f.metadata.motion_state.direction, consts.DIRECTION.BOTH)
end

T["composed filters"]["filter_lines_around_cursor has BOTH direction"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local consts = require("smart-motion.consts")
	local f = registries.filters.get_by_name("filter_lines_around_cursor")

	expect.equality(f.metadata.motion_state.direction, consts.DIRECTION.BOTH)
end

-- =============================================================================
-- Composed filters behavioral tests
-- =============================================================================

T["cursor line after cursor"] = MiniTest.new_set()

T["cursor line after cursor"]["keeps only words after cursor on same line"] = function()
	helpers.create_buf({ "alpha beta gamma", "delta epsilon" })
	helpers.set_cursor(1, 6) -- at "beta"

	-- Use raw filter functions directly (not the wrapped registry versions)
	local cursor_line_filter = require("smart-motion.filters.filter_cursor_line_only")
	local words_after_filter = require("smart-motion.filters.filter_words_after_cursor")
	local ctx = helpers.build_ctx()

	local targets = {
		{ start_pos = { row = 0, col = 0 }, end_pos = { row = 0, col = 5 }, text = "alpha", metadata = {} },
		{ start_pos = { row = 0, col = 6 }, end_pos = { row = 0, col = 10 }, text = "beta", metadata = {} },
		{ start_pos = { row = 0, col = 11 }, end_pos = { row = 0, col = 16 }, text = "gamma", metadata = {} },
		{ start_pos = { row = 1, col = 0 }, end_pos = { row = 1, col = 5 }, text = "delta", metadata = {} },
	}

	local ms = { hint_position = "start" }
	local results = {}

	for _, t in ipairs(targets) do
		-- Apply cursor_line_only first, then words_after_cursor
		local pass1 = cursor_line_filter.run(ctx, nil, ms, t)
		if pass1 then
			local pass2 = words_after_filter.run(ctx, nil, ms, pass1)
			if pass2 then
				table.insert(results, pass2)
			end
		end
	end

	-- Should only get "gamma" (after cursor on cursor line)
	expect.equality(#results, 1)
	expect.equality(results[1].text, "gamma")
end

-- =============================================================================
-- Filter metadata has merged info
-- =============================================================================

T["filter metadata"] = MiniTest.new_set()

T["filter metadata"]["merged filters have module_names"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local f = registries.filters.get_by_name("filter_lines_after_cursor")

	expect.equality(f.metadata.merged, true)
	expect.no_equality(f.metadata.module_names, nil)
	expect.equality(#f.metadata.module_names > 0, true)
end

T["filter metadata"]["default filter is not merged"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local f = registries.filters.get_by_name("default")

	expect.equality(f.metadata.merged, nil)
end

return T
