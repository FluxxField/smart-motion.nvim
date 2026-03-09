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
-- merge_actions
-- =============================================================================

T["merge_actions"] = MiniTest.new_set()

T["merge_actions"]["merges registered actions into chain"] = function()
	local merge = require("smart-motion.merge")

	-- jump and restore are both registered actions
	local merged = merge.merge_actions({ "jump", "restore" })

	expect.no_equality(merged, nil)
	expect.no_equality(merged.run, nil)
	expect.no_equality(merged.metadata, nil)
	expect.equality(merged.metadata.merged, true)
end

T["merge_actions"]["executes actions in correct order"] = function()
	local merge = require("smart-motion.merge")

	-- Test with jump + restore: should jump then restore cursor
	local bufnr = helpers.create_buf({ "hello world", "foo bar" })
	local winid = vim.api.nvim_get_current_win()
	helpers.set_cursor(1, 0)

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local motion_state = {
		selected_jump_target = {
			start_pos = { row = 1, col = 4 },
			end_pos = { row = 1, col = 7 },
			text = "bar",
			metadata = { bufnr = bufnr, winid = winid },
		},
		hint_position = "start",
	}

	local merged = merge.merge_actions({ "jump", "restore" })
	merged.run(ctx, cfg, motion_state)

	-- Cursor should be restored to original position
	local row, col = helpers.get_cursor()
	expect.equality(row, 1)
	expect.equality(col, 0)
end

T["merge_actions"]["errors on unknown action"] = function()
	local merge = require("smart-motion.merge")

	expect.error(function()
		merge.merge_actions({ "nonexistent_action_xyz" })
	end)
end

T["merge_actions"]["metadata includes module names"] = function()
	local merge = require("smart-motion.merge")

	local merged = merge.merge_actions({ "jump", "restore" })
	expect.no_equality(merged.metadata.module_names, nil)
	expect.equality(#merged.metadata.module_names, 2)
	expect.equality(merged.metadata.module_names[1], "jump")
	expect.equality(merged.metadata.module_names[2], "restore")
end

-- =============================================================================
-- merge_filters
-- =============================================================================

T["merge_filters"] = MiniTest.new_set()

T["merge_filters"]["merges registered filters"] = function()
	local merge = require("smart-motion.merge")

	local merged = merge.merge_filters({ "filter_lines_after_cursor", "filter_visible" })

	expect.no_equality(merged, nil)
	expect.no_equality(merged.run, nil)
	expect.equality(merged.metadata.merged, true)
end

T["merge_filters"]["errors on unknown filter"] = function()
	local merge = require("smart-motion.merge")

	expect.error(function()
		merge.merge_filters({ "nonexistent_filter_xyz" })
	end)
end

return T
