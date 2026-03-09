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

--- Build a target at the given position
local function make_target(bufnr, winid, row, col, end_col, text, target_type)
	return {
		start_pos = { row = row, col = col },
		end_pos = { row = row, col = end_col or (col + #(text or "")) },
		text = text or "",
		type = target_type or "words",
		metadata = { bufnr = bufnr, winid = winid },
	}
end

-- =============================================================================
-- Jump action
-- =============================================================================

T["jump"] = MiniTest.new_set()

T["jump"]["moves cursor to target position"] = function()
	local bufnr = helpers.create_buf({ "hello world", "foo bar baz", "line three" })
	local winid = vim.api.nvim_get_current_win()
	helpers.set_cursor(1, 0)

	local cfg = require("smart-motion.config").validated
	local ctx = helpers.build_ctx()
	local target = make_target(bufnr, winid, 1, 4, 7, "bar")

	local motion_state = {
		selected_jump_target = target,
		hint_position = "start",
	}

	require("smart-motion.actions.jump").run(ctx, cfg, motion_state)

	local row, col = helpers.get_cursor()
	expect.equality(row, 2) -- 1-indexed
	expect.equality(col, 4)
end

T["jump"]["moves cursor to different line"] = function()
	local bufnr = helpers.create_buf({ "first", "second", "third", "fourth" })
	local winid = vim.api.nvim_get_current_win()
	helpers.set_cursor(1, 0)

	local cfg = require("smart-motion.config").validated
	local ctx = helpers.build_ctx()
	local target = make_target(bufnr, winid, 2, 0, 5, "third")

	local motion_state = {
		selected_jump_target = target,
		hint_position = "start",
	}

	require("smart-motion.actions.jump").run(ctx, cfg, motion_state)

	local row, col = helpers.get_cursor()
	expect.equality(row, 3) -- 0-indexed row 2 = 1-indexed row 3
	expect.equality(col, 0)
end

-- =============================================================================
-- Restore action
-- =============================================================================

T["restore"] = MiniTest.new_set()

T["restore"]["returns cursor to original position"] = function()
	helpers.create_buf({ "hello world", "foo bar baz" })
	helpers.set_cursor(1, 3)

	local ctx = helpers.build_ctx()
	-- ctx captures cursor_line=0 (0-indexed), cursor_col=3

	-- Move cursor away
	helpers.set_cursor(2, 5)
	local row, col = helpers.get_cursor()
	expect.equality(row, 2)
	expect.equality(col, 5)

	-- Restore should bring it back
	require("smart-motion.actions.restore").run(ctx, {}, {})

	row, col = helpers.get_cursor()
	expect.equality(row, 1) -- back to original
	expect.equality(col, 3)
end

-- =============================================================================
-- Yank action
-- =============================================================================

T["yank"] = MiniTest.new_set()

T["yank"]["copies target text to unnamed register"] = function()
	local bufnr = helpers.create_buf({ "hello world test" })
	local winid = vim.api.nvim_get_current_win()
	helpers.set_cursor(1, 0)

	local cfg = require("smart-motion.config").validated
	local ctx = helpers.build_ctx()
	local target = make_target(bufnr, winid, 0, 6, 11, "world")

	local motion_state = {
		selected_jump_target = target,
	}

	require("smart-motion.actions.yank").run(ctx, cfg, motion_state)

	expect.equality(vim.fn.getreg('"'), "world")
end

-- =============================================================================
-- Action merge (composable chains)
-- =============================================================================

T["merge"] = MiniTest.new_set()

T["merge"]["executes actions in order"] = function()
	local order = {}
	local action_a = { run = function() table.insert(order, "a") end }
	local action_b = { run = function() table.insert(order, "b") end }
	local action_c = { run = function() table.insert(order, "c") end }

	local merged = require("smart-motion.actions.utils").merge({ action_a, action_b, action_c })
	merged(nil, nil, nil)

	expect.equality(#order, 3)
	expect.equality(order[1], "a")
	expect.equality(order[2], "b")
	expect.equality(order[3], "c")
end

-- =============================================================================
-- Yank + Restore (issue #140: yank should restore cursor)
-- =============================================================================

T["yank restore"] = MiniTest.new_set()

T["yank restore"]["jump + yank + restore preserves cursor position"] = function()
	local bufnr = helpers.create_buf({ "alpha beta gamma", "delta epsilon zeta" })
	local winid = vim.api.nvim_get_current_win()
	helpers.set_cursor(1, 0) -- cursor at "alpha"

	local cfg = require("smart-motion.config").validated
	local ctx = helpers.build_ctx()

	-- Target "epsilon" on line 2 (0-indexed row 1, col 6)
	local target = make_target(bufnr, winid, 1, 6, 13, "epsilon")

	local motion_state = {
		selected_jump_target = target,
		hint_position = "start",
	}

	-- Execute the full yank_jump chain: jump → yank → restore
	local jump = require("smart-motion.actions.jump")
	local yank = require("smart-motion.actions.yank")
	local restore = require("smart-motion.actions.restore")
	local merge = require("smart-motion.actions.utils").merge

	local yank_jump = merge({ jump, yank, restore })
	yank_jump(ctx, cfg, motion_state)

	-- Cursor should be back at original position
	local row, col = helpers.get_cursor()
	expect.equality(row, 1)
	expect.equality(col, 0)

	-- But the text should be yanked
	expect.equality(vim.fn.getreg('"'), "epsilon")
end

T["yank restore"]["jump + yank without restore moves cursor"] = function()
	local bufnr = helpers.create_buf({ "alpha beta gamma", "delta epsilon zeta" })
	local winid = vim.api.nvim_get_current_win()
	helpers.set_cursor(1, 0)

	local cfg = require("smart-motion.config").validated
	local ctx = helpers.build_ctx()

	local target = make_target(bufnr, winid, 1, 6, 13, "epsilon")

	local motion_state = {
		selected_jump_target = target,
		hint_position = "start",
	}

	local jump = require("smart-motion.actions.jump")
	local yank = require("smart-motion.actions.yank")
	local merge = require("smart-motion.actions.utils").merge

	local yank_no_restore = merge({ jump, yank })
	yank_no_restore(ctx, cfg, motion_state)

	-- Cursor should have moved to target
	local row, col = helpers.get_cursor()
	expect.equality(row, 2) -- moved to line 2
	expect.equality(col, 6)

	-- Text should still be yanked
	expect.equality(vim.fn.getreg('"'), "epsilon")
end

-- =============================================================================
-- Registered action chains
-- =============================================================================

T["registered actions"] = MiniTest.new_set()

T["registered actions"]["yank_jump includes restore in its chain"] = function()
	-- Verify the registered yank_jump action has the correct composition
	local registries = require("smart-motion.core.registries"):get()
	local yank_jump = registries.actions.get_by_name("yank_jump")

	expect.no_equality(yank_jump, nil)
	expect.no_equality(yank_jump.run, nil)

	-- Execute it and verify cursor restores
	local bufnr = helpers.create_buf({ "one two three", "four five six" })
	local winid = vim.api.nvim_get_current_win()
	helpers.set_cursor(1, 0)

	local cfg = require("smart-motion.config").validated
	local ctx = helpers.build_ctx()
	local target = make_target(bufnr, winid, 1, 5, 9, "five")

	local motion_state = {
		selected_jump_target = target,
		hint_position = "start",
	}

	yank_jump.run(ctx, cfg, motion_state)

	-- Cursor should be restored
	local row, col = helpers.get_cursor()
	expect.equality(row, 1)
	expect.equality(col, 0)

	-- Text should be yanked
	expect.equality(vim.fn.getreg('"'), "five")
end

return T
