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
-- context.get
-- =============================================================================

T["context"] = MiniTest.new_set()

T["context"]["returns bufnr and winid"] = function()
	local bufnr = helpers.create_buf({ "hello world" })
	local context = require("smart-motion.core.context")

	local ctx = context.get()

	expect.equality(ctx.bufnr, bufnr)
	expect.no_equality(ctx.winid, nil)
end

T["context"]["returns cursor position (0-indexed line)"] = function()
	helpers.create_buf({ "line1", "line2", "line3" })
	helpers.set_cursor(2, 3)

	local context = require("smart-motion.core.context")
	local ctx = context.get()

	expect.equality(ctx.cursor_line, 1) -- 0-indexed
	expect.equality(ctx.cursor_col, 3)
end

T["context"]["returns last_line count"] = function()
	helpers.create_buf({ "a", "b", "c", "d" })

	local context = require("smart-motion.core.context")
	local ctx = context.get()

	expect.equality(ctx.last_line, 4)
end

T["context"]["returns mode"] = function()
	helpers.create_buf({ "test" })

	local context = require("smart-motion.core.context")
	local ctx = context.get()

	-- Should be normal mode in tests
	expect.equality(ctx.mode, "n")
end

T["context"]["includes windows list"] = function()
	helpers.create_buf({ "test" })

	local context = require("smart-motion.core.context")
	local ctx = context.get()

	expect.equality(type(ctx.windows), "table")
	expect.equality(#ctx.windows >= 1, true)
	-- Current window should be first
	expect.equality(ctx.windows[1].winid, ctx.winid)
end

T["context"]["window entries have expected fields"] = function()
	helpers.create_buf({ "test" })

	local context = require("smart-motion.core.context")
	local ctx = context.get()

	local win = ctx.windows[1]
	expect.no_equality(win.winid, nil)
	expect.no_equality(win.bufnr, nil)
	expect.no_equality(win.cursor_line, nil)
	expect.no_equality(win.cursor_col, nil)
	expect.no_equality(win.last_line, nil)
end

return T
