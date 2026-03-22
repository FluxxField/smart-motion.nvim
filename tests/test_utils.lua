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
-- is_non_empty_string
-- =============================================================================

T["is_non_empty_string"] = MiniTest.new_set()

T["is_non_empty_string"]["returns true for normal string"] = function()
	local utils = require("smart-motion.utils")
	expect.equality(utils.is_non_empty_string("hello"), true)
end

T["is_non_empty_string"]["returns false for empty string"] = function()
	local utils = require("smart-motion.utils")
	expect.equality(utils.is_non_empty_string(""), false)
end

T["is_non_empty_string"]["returns false for whitespace only"] = function()
	local utils = require("smart-motion.utils")
	expect.equality(utils.is_non_empty_string("   "), false)
	expect.equality(utils.is_non_empty_string("\t"), false)
	expect.equality(utils.is_non_empty_string("\n"), false)
end

T["is_non_empty_string"]["returns false for nil"] = function()
	local utils = require("smart-motion.utils")
	expect.equality(utils.is_non_empty_string(nil), false)
end

T["is_non_empty_string"]["returns false for number"] = function()
	local utils = require("smart-motion.utils")
	expect.equality(utils.is_non_empty_string(123), false)
end

T["is_non_empty_string"]["returns false for table"] = function()
	local utils = require("smart-motion.utils")
	expect.equality(utils.is_non_empty_string({}), false)
end

T["is_non_empty_string"]["returns false for boolean"] = function()
	local utils = require("smart-motion.utils")
	expect.equality(utils.is_non_empty_string(true), false)
end

-- =============================================================================
-- prepare_motion
-- =============================================================================

T["prepare_motion"] = MiniTest.new_set()

T["prepare_motion"]["returns ctx, cfg, and motion_state"] = function()
	helpers.create_buf({ "test content" })
	helpers.set_cursor(1, 0)

	local utils = require("smart-motion.utils")
	local ctx, cfg, ms = utils.prepare_motion()

	expect.no_equality(ctx, nil)
	expect.no_equality(cfg, nil)
	expect.no_equality(ms, nil)

	-- ctx should have buffer info
	expect.no_equality(ctx.bufnr, nil)
	expect.no_equality(ctx.winid, nil)
	expect.no_equality(ctx.cursor_line, nil)

	-- cfg should have keys
	expect.equality(type(cfg.keys), "table")

	-- ms should have defaults
	expect.equality(ms.jump_target_count, 0)
end

-- =============================================================================
-- close_floating_windows
-- =============================================================================

T["close_floating_windows"] = MiniTest.new_set()

T["close_floating_windows"]["closes only smart-motion owned floating windows"] = function()
	helpers.create_buf({ "test" })

	local utils = require("smart-motion.utils")
	local owned_buf = vim.api.nvim_create_buf(false, true)
	local foreign_buf = vim.api.nvim_create_buf(false, true)

	local owned_win = vim.api.nvim_open_win(owned_buf, false, {
		relative = "editor",
		row = 1,
		col = 1,
		width = 10,
		height = 1,
		style = "minimal",
	})
	local foreign_win = vim.api.nvim_open_win(foreign_buf, false, {
		relative = "editor",
		row = 3,
		col = 1,
		width = 10,
		height = 1,
		style = "minimal",
	})

	vim.api.nvim_win_set_var(owned_win, "smart_motion_owned", true)

	utils.close_floating_windows()

	expect.equality(vim.api.nvim_win_is_valid(owned_win), false)
	expect.equality(vim.api.nvim_win_is_valid(foreign_win), true)
end

-- =============================================================================
-- module_wrapper
-- =============================================================================

T["module_wrapper"] = MiniTest.new_set()

T["module_wrapper"]["wraps a run function into a coroutine chain"] = function()
	helpers.create_buf({ "test" })

	local utils = require("smart-motion.utils")

	-- Simple run_fn that returns a table (single target)
	local run_fn = function(ctx, cfg, ms, data)
		return { text = data.text .. "_modified", start_pos = data.start_pos, end_pos = data.end_pos }
	end

	local wrapper = utils.module_wrapper(run_fn)

	-- Create an input generator
	local input_gen = coroutine.create(function()
		coroutine.yield({ text = "hello", start_pos = { row = 0, col = 0 }, end_pos = { row = 0, col = 5 } })
		coroutine.yield({ text = "world", start_pos = { row = 0, col = 6 }, end_pos = { row = 0, col = 11 } })
	end)

	local chain = wrapper(input_gen)

	local results = {}
	local ok, val = coroutine.resume(chain, nil, nil, {})
	while ok and val do
		table.insert(results, val)
		ok, val = coroutine.resume(chain)
	end

	expect.equality(#results, 2)
	expect.equality(results[1].text, "hello_modified")
	expect.equality(results[2].text, "world_modified")
end

T["module_wrapper"]["wraps a run function that returns a coroutine"] = function()
	helpers.create_buf({ "test" })

	local utils = require("smart-motion.utils")

	-- run_fn that returns a coroutine (like words extractor)
	local run_fn = function(ctx, cfg, ms, data)
		return coroutine.create(function()
			coroutine.yield({ text = data.text .. "_a" })
			coroutine.yield({ text = data.text .. "_b" })
		end)
	end

	local wrapper = utils.module_wrapper(run_fn)

	local input_gen = coroutine.create(function()
		coroutine.yield({ text = "item" })
	end)

	local chain = wrapper(input_gen)
	local results = {}
	local ok, val = coroutine.resume(chain, nil, nil, {})
	while ok and val do
		table.insert(results, val)
		ok, val = coroutine.resume(chain)
	end

	expect.equality(#results, 2)
	expect.equality(results[1].text, "item_a")
	expect.equality(results[2].text, "item_b")
end

return T
