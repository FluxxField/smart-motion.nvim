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
-- action utils: resolve_range
-- =============================================================================

T["resolve_range"] = MiniTest.new_set()

T["resolve_range"]["returns target range by default"] = function()
	local utils = require("smart-motion.actions.utils")
	local ctx = { cursor_line = 0, cursor_col = 0 }
	local target = { start_pos = { row = 1, col = 5 }, end_pos = { row = 1, col = 10 } }
	local ms = { selected_jump_target = target }

	local sr, sc, er, ec = utils.resolve_range(ctx, ms)
	expect.equality(sr, 1)
	expect.equality(sc, 5)
	expect.equality(er, 1)
	expect.equality(ec, 10)
end

T["resolve_range"]["exclude_target forward: cursor to target start"] = function()
	local utils = require("smart-motion.actions.utils")
	local ctx = { cursor_line = 0, cursor_col = 0 }
	local target = { start_pos = { row = 0, col = 10 }, end_pos = { row = 0, col = 15 } }
	local ms = { selected_jump_target = target, exclude_target = true }

	local sr, sc, er, ec = utils.resolve_range(ctx, ms)
	expect.equality(sr, 0)
	expect.equality(sc, 0)
	expect.equality(er, 0)
	expect.equality(ec, 10)
end

T["resolve_range"]["exclude_target backward: target end to cursor"] = function()
	local utils = require("smart-motion.actions.utils")
	local ctx = { cursor_line = 0, cursor_col = 20 }
	local target = { start_pos = { row = 0, col = 5 }, end_pos = { row = 0, col = 10 } }
	local ms = { selected_jump_target = target, exclude_target = true }

	local sr, sc, er, ec = utils.resolve_range(ctx, ms)
	expect.equality(sr, 0)
	expect.equality(sc, 10) -- target.end_pos.col
	expect.equality(er, 0)
	expect.equality(ec, 20) -- cursor_col
end

T["resolve_range"]["cursor_to_target forward: cursor to target end"] = function()
	local utils = require("smart-motion.actions.utils")
	local ctx = { cursor_line = 0, cursor_col = 0 }
	local target = { start_pos = { row = 0, col = 10 }, end_pos = { row = 0, col = 15 } }
	local ms = { selected_jump_target = target, cursor_to_target = true }

	local sr, sc, er, ec = utils.resolve_range(ctx, ms)
	expect.equality(sr, 0)
	expect.equality(sc, 0)
	expect.equality(er, 0)
	expect.equality(ec, 15)
end

T["resolve_range"]["cursor_to_target backward: target start to cursor"] = function()
	local utils = require("smart-motion.actions.utils")
	local ctx = { cursor_line = 0, cursor_col = 20 }
	local target = { start_pos = { row = 0, col = 5 }, end_pos = { row = 0, col = 10 } }
	local ms = { selected_jump_target = target, cursor_to_target = true }

	local sr, sc, er, ec = utils.resolve_range(ctx, ms)
	expect.equality(sr, 0)
	expect.equality(sc, 5)
	expect.equality(er, 0)
	expect.equality(ec, 20)
end

T["resolve_range"]["cross-line forward exclude"] = function()
	local utils = require("smart-motion.actions.utils")
	local ctx = { cursor_line = 0, cursor_col = 5 }
	local target = { start_pos = { row = 2, col = 3 }, end_pos = { row = 2, col = 8 } }
	local ms = { selected_jump_target = target, exclude_target = true }

	local sr, sc, er, ec = utils.resolve_range(ctx, ms)
	expect.equality(sr, 0)
	expect.equality(sc, 5)
	expect.equality(er, 2)
	expect.equality(ec, 3)
end

-- =============================================================================
-- action utils: set_register
-- =============================================================================

T["set_register"] = MiniTest.new_set()

T["set_register"]["sets unnamed register with text"] = function()
	local utils = require("smart-motion.actions.utils")
	local bufnr = helpers.create_buf({ "hello world" })

	utils.set_register(bufnr, 0, 0, 0, 5, "hello", "c", "y")

	expect.equality(vim.fn.getreg('"'), "hello")
end

T["set_register"]["sets linewise register type"] = function()
	local utils = require("smart-motion.actions.utils")
	local bufnr = helpers.create_buf({ "hello", "world" })

	utils.set_register(bufnr, 0, 0, 1, 5, "hello\nworld", "l", "y")

	-- Linewise registers include trailing newline
	local reg = vim.fn.getreg('"')
	expect.equality(reg:find("hello") ~= nil, true)
	expect.equality(reg:find("world") ~= nil, true)
	expect.equality(vim.fn.getregtype('"'), "V")
end

-- =============================================================================
-- delete action
-- =============================================================================

T["delete"] = MiniTest.new_set()

T["delete"]["deletes word from buffer"] = function()
	local bufnr = helpers.create_buf({ "hello world test" })
	local winid = vim.api.nvim_get_current_win()
	helpers.set_cursor(1, 0)

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local target = make_target(bufnr, winid, 0, 6, 11, "world")

	local ms = {
		selected_jump_target = target,
	}

	require("smart-motion.actions.delete").run(ctx, cfg, ms)

	local lines = helpers.get_buf_lines()
	expect.equality(lines[1], "hello  test")
	-- Deleted text should be in register
	expect.equality(vim.fn.getreg('"'), "world")
end

T["delete"]["deletes with characterwise register type"] = function()
	local bufnr = helpers.create_buf({ "abc def ghi" })
	local winid = vim.api.nvim_get_current_win()
	helpers.set_cursor(1, 0)

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local target = make_target(bufnr, winid, 0, 4, 7, "def")
	local ms = { selected_jump_target = target }

	require("smart-motion.actions.delete").run(ctx, cfg, ms)

	expect.equality(vim.fn.getreg('"'), "def")
	expect.equality(vim.fn.getregtype('"'), "v")
end

-- =============================================================================
-- delete_line action
-- =============================================================================

T["delete_line"] = MiniTest.new_set()

T["delete_line"]["deletes current line"] = function()
	helpers.create_buf({ "line1", "line2", "line3" })
	helpers.set_cursor(2, 0) -- cursor on line2

	require("smart-motion.actions.delete_line").run(nil, nil, nil)

	local lines = helpers.get_buf_lines()
	expect.equality(#lines, 2)
	expect.equality(lines[1], "line1")
	expect.equality(lines[2], "line3")
end

-- =============================================================================
-- yank_line action
-- =============================================================================

T["yank_line"] = MiniTest.new_set()

T["yank_line"]["yanks current line"] = function()
	local bufnr = helpers.create_buf({ "line one", "line two", "line three" })
	helpers.set_cursor(2, 0)

	local target = {
		start_pos = { row = 1, col = 0 },
		end_pos = { row = 1, col = 8 },
		text = "line two",
		bufnr = bufnr,
	}

	require("smart-motion.actions.yank_line").run(nil, nil, { selected_jump_target = target })

	-- yy yanks the full line
	local reg = vim.fn.getreg('"')
	expect.equality(reg:find("line two") ~= nil, true)
end

-- =============================================================================
-- change_line action
-- =============================================================================

T["change_line"] = MiniTest.new_set()

T["change_line"]["clears line and enters insert mode"] = function()
	helpers.create_buf({ "line1", "replace me", "line3" })
	helpers.set_cursor(2, 0)

	require("smart-motion.actions.change_line").run(nil, nil, nil)

	-- After cc, the line should be empty/blank
	local lines = helpers.get_buf_lines()
	expect.equality(#lines, 3)
	-- Line 2 should be cleared (cc replaces with empty)
	expect.equality(lines[2], "")

	-- Headless mode may not fully enter insert mode; just ensure it ran without error
	-- Exit any mode for cleanup
	pcall(vim.cmd, "stopinsert")
end

-- =============================================================================
-- paste action
-- =============================================================================

T["paste"] = MiniTest.new_set()

T["paste"]["pastes text at target location"] = function()
	local bufnr = helpers.create_buf({ "hello world" })
	local winid = vim.api.nvim_get_current_win()
	helpers.set_cursor(1, 0)

	-- Put something in register
	vim.fn.setreg('"', "PASTED")

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local target = make_target(bufnr, winid, 0, 5, 10, "world")

	local ms = {
		selected_jump_target = target,
	}

	require("smart-motion.actions.paste").run(ctx, cfg, ms)

	local lines = helpers.get_buf_lines()
	-- "p" pastes after cursor position at target
	expect.equality(lines[1]:find("PASTED") ~= nil, true)
end

T["paste"]["respects paste_mode before"] = function()
	local bufnr = helpers.create_buf({ "hello world" })
	local winid = vim.api.nvim_get_current_win()
	helpers.set_cursor(1, 0)

	vim.fn.setreg('"', "X")

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local target = make_target(bufnr, winid, 0, 5, 10, "world")

	local ms = {
		selected_jump_target = target,
		paste_mode = "before",
	}

	require("smart-motion.actions.paste").run(ctx, cfg, ms)

	local lines = helpers.get_buf_lines()
	expect.equality(lines[1]:find("X") ~= nil, true)
end

-- =============================================================================
-- paste_line action
-- =============================================================================

T["paste_line"] = MiniTest.new_set()

T["paste_line"]["pastes line below"] = function()
	helpers.create_buf({ "line1", "line2" })
	helpers.set_cursor(1, 0)

	vim.fn.setreg('"', "pasted line\n", "l")

	require("smart-motion.actions.paste_line").run(nil, nil, {})

	local lines = helpers.get_buf_lines()
	-- Should have inserted a line
	expect.equality(#lines, 3)
end

-- =============================================================================
-- center action
-- =============================================================================

T["center"] = MiniTest.new_set()

T["center"]["executes without error"] = function()
	helpers.create_buf({ "line1", "line2", "line3" })
	helpers.set_cursor(2, 0)

	-- center just runs zz, should not error
	local ok = pcall(require("smart-motion.actions.center").run, nil, nil, nil)
	expect.equality(ok, true)
end

-- =============================================================================
-- change action
-- =============================================================================

T["change"] = MiniTest.new_set()

T["change"]["deletes text from buffer"] = function()
	local bufnr = helpers.create_buf({ "hello world test" })
	local winid = vim.api.nvim_get_current_win()
	helpers.set_cursor(1, 0)

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local target = make_target(bufnr, winid, 0, 6, 11, "world")

	local ms = {
		selected_jump_target = target,
	}

	require("smart-motion.actions.change").run(ctx, cfg, ms)

	local lines = helpers.get_buf_lines()
	-- "world" should be deleted
	expect.equality(lines[1]:find("world"), nil)

	-- Headless mode may not fully enter insert mode
	pcall(vim.cmd, "stopinsert")
end

-- =============================================================================
-- Registered action chains in init.lua
-- =============================================================================

T["registered chains"] = MiniTest.new_set()

T["registered chains"]["all expected actions are registered"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local actions = registries.actions

	local expected = { "jump", "yank_jump", "yank_line", "delete_jump", "delete_line" }
	for _, name in ipairs(expected) do
		expect.no_equality(actions.get_by_name(name), nil)
	end
end

T["registered chains"]["delete_jump chain works end-to-end"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local delete_jump = registries.actions.get_by_name("delete_jump")
	expect.no_equality(delete_jump, nil)

	local bufnr = helpers.create_buf({ "hello world test" })
	local winid = vim.api.nvim_get_current_win()
	helpers.set_cursor(1, 0)

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local target = make_target(bufnr, winid, 0, 6, 11, "world")

	local ms = {
		selected_jump_target = target,
		hint_position = "start",
	}

	delete_jump.run(ctx, cfg, ms)

	-- Text should be deleted
	local lines = helpers.get_buf_lines()
	expect.equality(lines[1]:find("world"), nil)
	-- Deleted text should be in register
	expect.equality(vim.fn.getreg('"'), "world")
end

return T
