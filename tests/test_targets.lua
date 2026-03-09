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
-- format_target
-- =============================================================================

T["format_target"] = MiniTest.new_set()

T["format_target"]["adds metadata with bufnr and winid"] = function()
	local targets = require("smart-motion.core.targets")
	local bufnr = helpers.create_buf({ "hello world" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local raw = {
		start_pos = { row = 0, col = 0 },
		end_pos = { row = 0, col = 5 },
		text = "hello",
	}

	local result = targets.format_target(ctx, cfg, {}, raw)

	expect.equality(result.metadata.bufnr, bufnr)
	expect.no_equality(result.metadata.winid, nil)
	expect.equality(result.text, "hello")
end

T["format_target"]["sets default type to unknown"] = function()
	local targets = require("smart-motion.core.targets")
	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local raw = {
		start_pos = { row = 0, col = 0 },
		end_pos = { row = 0, col = 4 },
		text = "test",
	}

	local result = targets.format_target(ctx, cfg, {}, raw)
	expect.equality(result.type, "unknown")
end

T["format_target"]["preserves existing type"] = function()
	local targets = require("smart-motion.core.targets")
	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local raw = {
		start_pos = { row = 0, col = 0 },
		end_pos = { row = 0, col = 4 },
		text = "test",
		type = "words",
	}

	local result = targets.format_target(ctx, cfg, {}, raw)
	expect.equality(result.type, "words")
end

T["format_target"]["preserves positions"] = function()
	local targets = require("smart-motion.core.targets")
	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local raw = {
		start_pos = { row = 3, col = 7 },
		end_pos = { row = 3, col = 12 },
		text = "hello",
	}

	local result = targets.format_target(ctx, cfg, {}, raw)
	expect.equality(result.start_pos.row, 3)
	expect.equality(result.start_pos.col, 7)
	expect.equality(result.end_pos.row, 3)
	expect.equality(result.end_pos.col, 12)
end

-- =============================================================================
-- get_target_under_cursor
-- =============================================================================

T["get_target_under_cursor"] = MiniTest.new_set()

T["get_target_under_cursor"]["finds word target at cursor"] = function()
	local targets = require("smart-motion.core.targets")
	helpers.create_buf({ "hello world test" })
	helpers.set_cursor(1, 6) -- cursor in "world"

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local consts = require("smart-motion.consts")

	local ms = { target_type = consts.TARGET_TYPES.WORDS }

	local result = targets.get_target_under_cursor(ctx, cfg, ms)

	expect.no_equality(result, nil)
	-- Text from cursor position to end of word
	expect.equality(result.text, "world")
	expect.equality(result.start_pos.col, 6)
end

T["get_target_under_cursor"]["finds word when cursor is mid-word"] = function()
	local targets = require("smart-motion.core.targets")
	helpers.create_buf({ "hello world" })
	helpers.set_cursor(1, 8) -- cursor at 'r' in "world" (h=0,e=1,l=2,l=3,o=4,' '=5,w=6,o=7,r=8)

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local consts = require("smart-motion.consts")

	local ms = { target_type = consts.TARGET_TYPES.WORDS }

	local result = targets.get_target_under_cursor(ctx, cfg, ms)

	expect.no_equality(result, nil)
	-- Should return text from cursor to end of word
	expect.equality(result.text, "rld")
	expect.equality(result.start_pos.col, 8)
end

T["get_target_under_cursor"]["returns nil on empty line"] = function()
	local targets = require("smart-motion.core.targets")
	helpers.create_buf({ "" })
	helpers.set_cursor(1, 0)

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local consts = require("smart-motion.consts")

	local ms = { target_type = consts.TARGET_TYPES.WORDS }

	local result = targets.get_target_under_cursor(ctx, cfg, ms)
	expect.equality(result, nil)
end

T["get_target_under_cursor"]["returns line target for line type"] = function()
	local targets = require("smart-motion.core.targets")
	helpers.create_buf({ "first line", "second line" })
	helpers.set_cursor(1, 3) -- cursor somewhere on first line

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local consts = require("smart-motion.consts")

	local ms = { target_type = consts.TARGET_TYPES.LINES }

	local result = targets.get_target_under_cursor(ctx, cfg, ms)

	expect.no_equality(result, nil)
	expect.equality(result.text, "first line")
	expect.equality(result.start_pos.col, 0)
	expect.equality(result.type, consts.TARGET_TYPES.LINES)
end

-- =============================================================================
-- get_targets (with coroutine generator)
-- =============================================================================

T["get_targets"] = MiniTest.new_set()

T["get_targets"]["collects targets from generator into motion_state"] = function()
	local targets_mod = require("smart-motion.core.targets")
	helpers.create_buf({ "test content" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = {
		jump_targets = {},
	}

	-- Create a simple generator that yields 3 targets
	local gen = coroutine.create(function()
		coroutine.yield({
			start_pos = { row = 0, col = 0 },
			end_pos = { row = 0, col = 3 },
			text = "one",
			type = "words",
		})
		coroutine.yield({
			start_pos = { row = 0, col = 4 },
			end_pos = { row = 0, col = 7 },
			text = "two",
			type = "words",
		})
		coroutine.yield({
			start_pos = { row = 1, col = 0 },
			end_pos = { row = 1, col = 5 },
			text = "three",
			type = "words",
		})
	end)

	targets_mod.get_targets(ctx, cfg, ms, gen)

	expect.equality(#ms.jump_targets, 3)
	expect.equality(ms.jump_targets[1].text, "one")
	expect.equality(ms.jump_targets[2].text, "two")
	expect.equality(ms.jump_targets[3].text, "three")
	-- First target should be auto-selected
	expect.equality(ms.selected_jump_target.text, "one")
end

T["get_targets"]["reverses targets for before_cursor direction"] = function()
	local targets_mod = require("smart-motion.core.targets")
	local consts = require("smart-motion.consts")
	helpers.create_buf({ "test content" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = {
		jump_targets = {},
		direction = consts.DIRECTION.BEFORE_CURSOR,
	}

	local gen = coroutine.create(function()
		coroutine.yield({
			start_pos = { row = 0, col = 0 },
			end_pos = { row = 0, col = 3 },
			text = "first",
			type = "words",
		})
		coroutine.yield({
			start_pos = { row = 0, col = 4 },
			end_pos = { row = 0, col = 9 },
			text = "second",
			type = "words",
		})
	end)

	targets_mod.get_targets(ctx, cfg, ms, gen)

	-- Should be reversed
	expect.equality(ms.jump_targets[1].text, "second")
	expect.equality(ms.jump_targets[2].text, "first")
end

return T
