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
-- _collect_word_targets
-- =============================================================================

T["_collect_word_targets"] = MiniTest.new_set()

T["_collect_word_targets"]["collects words from buffer"] = function()
	helpers.create_buf({ "hello world test", "foo bar" })
	helpers.set_cursor(1, 0)

	local vs = require("smart-motion.actions.visual_select")
	local context = require("smart-motion.core.context")
	local ctx = context.get()

	local targets = vs._collect_word_targets(ctx)

	expect.equality(#targets >= 5, true) -- hello, world, test, foo, bar
	expect.equality(targets[1].type, "words")
	expect.no_equality(targets[1].metadata.bufnr, nil)
	expect.no_equality(targets[1].metadata.winid, nil)
end

T["_collect_word_targets"]["returns empty for empty buffer"] = function()
	helpers.create_buf({ "" })
	helpers.set_cursor(1, 0)

	local vs = require("smart-motion.actions.visual_select")
	local context = require("smart-motion.core.context")
	local ctx = context.get()

	local targets = vs._collect_word_targets(ctx)
	expect.equality(#targets, 0)
end

T["_collect_word_targets"]["includes position data"] = function()
	helpers.create_buf({ "hello world" })
	helpers.set_cursor(1, 0)

	local vs = require("smart-motion.actions.visual_select")
	local context = require("smart-motion.core.context")
	local ctx = context.get()

	local targets = vs._collect_word_targets(ctx)
	expect.equality(#targets >= 2, true)

	-- First word should start at col 0
	expect.equality(targets[1].start_pos.row, 0)
	expect.equality(targets[1].start_pos.col, 0)
	expect.equality(targets[1].text, "hello")
end

-- =============================================================================
-- textobject_select action
-- =============================================================================

T["textobject_select"] = MiniTest.new_set()

T["textobject_select"]["sets visual selection over target range"] = function()
	helpers.create_buf({ "hello world test" })
	helpers.set_cursor(1, 0)

	local ts_action = require("smart-motion.actions.textobject_select")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local motion_state = {
		selected_jump_target = {
			start_pos = { row = 0, col = 6 },
			end_pos = { row = 0, col = 11 },
			text = "world",
		},
	}

	ts_action.run(ctx, cfg, motion_state)

	-- Should be in visual mode
	local mode = vim.fn.mode(true)
	-- Exit visual for cleanup
	vim.cmd("normal! " .. vim.api.nvim_replace_termcodes("<Esc>", true, false, true))

	-- Mode should have been visual (v)
	expect.equality(mode:find("v") ~= nil or mode:find("V") ~= nil or mode:find("\22") ~= nil, true)
end

return T
