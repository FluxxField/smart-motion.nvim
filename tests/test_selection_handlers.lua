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
-- select_first
-- =============================================================================

T["select_first"] = MiniTest.new_set()

T["select_first"]["returns true to accept default selection"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local handler = registries.selection_handlers.get_by_name("select_first")
	expect.no_equality(handler, nil)

	local ms = {
		selected_jump_target = { text = "first" },
		jump_targets = { { text = "first" }, { text = "second" } },
	}

	local result = handler.run(nil, nil, ms)
	expect.equality(result, true)
end

-- =============================================================================
-- select_last
-- =============================================================================

T["select_last"] = MiniTest.new_set()

T["select_last"]["selects the last target"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local handler = registries.selection_handlers.get_by_name("select_last")
	expect.no_equality(handler, nil)

	local ms = {
		jump_targets = {
			{ text = "first" },
			{ text = "second" },
			{ text = "third" },
		},
	}

	local result = handler.run(nil, nil, ms)
	expect.equality(result, true)
	expect.equality(ms.selected_jump_target.text, "third")
end

T["select_last"]["handles single target"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local handler = registries.selection_handlers.get_by_name("select_last")

	local ms = {
		jump_targets = { { text = "only" } },
	}

	handler.run(nil, nil, ms)
	expect.equality(ms.selected_jump_target.text, "only")
end

-- =============================================================================
-- toggle_hint_position
-- =============================================================================

T["toggle_hint_position"] = MiniTest.new_set()

T["toggle_hint_position"]["toggles start to end"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local handler = registries.selection_handlers.get_by_name("toggle_hint_position")
	expect.no_equality(handler, nil)

	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = {
		hint_position = "start",
		assigned_hint_labels = {},
		affected_buffers = {},
	}

	local result = handler.run(ctx, cfg, ms)
	expect.equality(result, false) -- should stay in selection
	expect.equality(ms.hint_position, "end")
end

T["toggle_hint_position"]["toggles end to start"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local handler = registries.selection_handlers.get_by_name("toggle_hint_position")

	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = {
		hint_position = "end",
		assigned_hint_labels = {},
		affected_buffers = {},
	}

	handler.run(ctx, cfg, ms)
	expect.equality(ms.hint_position, "start")
end

-- =============================================================================
-- toggle_direction
-- =============================================================================

T["toggle_direction"] = MiniTest.new_set()

T["toggle_direction"]["flips after to before"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local handler = registries.selection_handlers.get_by_name("toggle_direction")
	expect.no_equality(handler, nil)

	local ms = {
		direction = "after_cursor",
		motion = { filter = "filter_words_after_cursor" },
	}

	local result = handler.run(nil, nil, ms)
	expect.equality(result, "rerun")
	expect.equality(ms.direction, "before_cursor")
	expect.equality(ms.motion.filter, "filter_words_before_cursor")
end

T["toggle_direction"]["flips before to after"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local handler = registries.selection_handlers.get_by_name("toggle_direction")

	local ms = {
		direction = "before_cursor",
		motion = { filter = "filter_lines_before_cursor" },
	}

	handler.run(nil, nil, ms)
	expect.equality(ms.direction, "after_cursor")
	expect.equality(ms.motion.filter, "filter_lines_after_cursor")
end

-- =============================================================================
-- toggle_multi_window
-- =============================================================================

T["toggle_multi_window"] = MiniTest.new_set()

T["toggle_multi_window"]["toggles false to true"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local handler = registries.selection_handlers.get_by_name("toggle_multi_window")
	expect.no_equality(handler, nil)

	local ms = { multi_window = false }
	local result = handler.run(nil, nil, ms)

	expect.equality(result, "rerun")
	expect.equality(ms.multi_window, true)
end

T["toggle_multi_window"]["toggles true to false"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local handler = registries.selection_handlers.get_by_name("toggle_multi_window")

	local ms = { multi_window = true }
	handler.run(nil, nil, ms)
	expect.equality(ms.multi_window, false)
end

-- =============================================================================
-- expand_search_scope
-- =============================================================================

T["expand_search_scope"] = MiniTest.new_set()

T["expand_search_scope"]["doubles max_lines"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local handler = registries.selection_handlers.get_by_name("expand_search_scope")
	expect.no_equality(handler, nil)

	-- Need enough lines so doubled value doesn't get clamped
	local lines = {}
	for i = 1, 200 do
		table.insert(lines, "line " .. i)
	end
	helpers.create_buf(lines)
	local ctx = helpers.build_ctx()

	local ms = { max_lines = 50 }
	local result = handler.run(ctx, nil, ms)

	expect.equality(result, "rerun")
	expect.equality(ms.max_lines, 100)
end

T["expand_search_scope"]["clamps to buffer size"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local handler = registries.selection_handlers.get_by_name("expand_search_scope")

	helpers.create_buf({ "only", "three", "lines" })
	local ctx = helpers.build_ctx()

	local ms = { max_lines = 5 }
	handler.run(ctx, nil, ms)

	-- Should clamp to buffer line count (3)
	expect.equality(ms.max_lines, 3)
end

-- =============================================================================
-- All handlers registered
-- =============================================================================

T["all registered"] = MiniTest.new_set()

T["all registered"]["all expected handlers exist"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local handlers = registries.selection_handlers

	local expected = {
		"select_first",
		"select_last",
		"toggle_hint_position",
		"toggle_direction",
		"toggle_multi_window",
		"expand_search_scope",
	}

	for _, name in ipairs(expected) do
		local h = handlers.get_by_name(name)
		expect.no_equality(h, nil)
		expect.no_equality(h.run, nil)
	end
end

return T
