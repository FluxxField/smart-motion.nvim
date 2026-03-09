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
-- weight_distance modifier
-- =============================================================================

T["weight_distance"] = MiniTest.new_set()

T["weight_distance"]["adds sort_weight based on manhattan distance"] = function()
	local modifier = require("smart-motion.modifiers.weight_distance")

	local ctx = { cursor_line = 5, cursor_col = 10 }
	local target = {
		start_pos = { row = 8, col = 15 },
		end_pos = { row = 8, col = 20 },
		text = "test",
		metadata = {},
	}

	local result = modifier.run(ctx, nil, nil, target)

	-- Manhattan distance: |8-5| + |15-10| = 3 + 5 = 8
	expect.equality(result.metadata.sort_weight, 8)
end

T["weight_distance"]["zero distance for cursor position"] = function()
	local modifier = require("smart-motion.modifiers.weight_distance")

	local ctx = { cursor_line = 3, cursor_col = 7 }
	local target = {
		start_pos = { row = 3, col = 7 },
		end_pos = { row = 3, col = 10 },
		text = "here",
		metadata = {},
	}

	local result = modifier.run(ctx, nil, nil, target)
	expect.equality(result.metadata.sort_weight, 0)
end

T["weight_distance"]["preserves existing metadata"] = function()
	local modifier = require("smart-motion.modifiers.weight_distance")

	local ctx = { cursor_line = 0, cursor_col = 0 }
	local target = {
		start_pos = { row = 1, col = 1 },
		end_pos = { row = 1, col = 5 },
		text = "test",
		metadata = { custom = "value" },
	}

	local result = modifier.run(ctx, nil, nil, target)
	expect.equality(result.metadata.custom, "value")
	expect.no_equality(result.metadata.sort_weight, nil)
end

T["weight_distance"]["creates metadata if nil"] = function()
	local modifier = require("smart-motion.modifiers.weight_distance")

	local ctx = { cursor_line = 0, cursor_col = 0 }
	local target = {
		start_pos = { row = 2, col = 3 },
		end_pos = { row = 2, col = 6 },
		text = "test",
	}

	local result = modifier.run(ctx, nil, nil, target)
	expect.no_equality(result.metadata, nil)
	expect.equality(result.metadata.sort_weight, 5) -- |2| + |3| = 5
end

T["weight_distance"]["has correct metadata for sorting"] = function()
	local modifier = require("smart-motion.modifiers.weight_distance")

	expect.equality(modifier.metadata.motion_state.sort_by, "sort_weight")
	expect.equality(modifier.metadata.motion_state.sort_descending, false)
end

-- =============================================================================
-- modifier registry
-- =============================================================================

T["modifier registry"] = MiniTest.new_set()

T["modifier registry"]["all modifiers are registered"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local modifiers = registries.modifiers

	expect.no_equality(modifiers.get_by_name("default"), nil)
	expect.no_equality(modifiers.get_by_name("weight_distance"), nil)
end

return T
