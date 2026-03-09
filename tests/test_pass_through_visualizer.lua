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
-- pass_through visualizer
-- =============================================================================

T["pass_through"] = MiniTest.new_set()

T["pass_through"]["selects first target when targets exist"] = function()
	helpers.create_buf({ "hello world" })
	helpers.set_cursor(1, 0)

	local visualizer = require("smart-motion.visualizers.pass_through")
	local exit = require("smart-motion.core.events.exit")

	local ms = {
		jump_targets = {
			{ text = "hello", start_pos = { row = 0, col = 0 } },
			{ text = "world", start_pos = { row = 0, col = 6 } },
		},
	}

	local exit_type = exit.wrap(function()
		visualizer.run(nil, nil, ms)
	end)

	-- Should throw AUTO_SELECT
	expect.equality(exit_type, "auto_select")
	expect.no_equality(ms.selected_jump_target, nil)
	expect.equality(ms.selected_jump_target.text, "hello")
end

T["pass_through"]["throws EARLY_EXIT when no targets"] = function()
	helpers.create_buf({ "" })
	helpers.set_cursor(1, 0)

	local visualizer = require("smart-motion.visualizers.pass_through")
	local exit = require("smart-motion.core.events.exit")

	local ms = {
		jump_targets = {},
	}

	local exit_type = exit.wrap(function()
		visualizer.run(nil, nil, ms)
	end)

	expect.equality(exit_type, "early_exit")
end

T["pass_through"]["uses pre-selected target if set"] = function()
	helpers.create_buf({ "hello world" })
	helpers.set_cursor(1, 0)

	local visualizer = require("smart-motion.visualizers.pass_through")
	local exit = require("smart-motion.core.events.exit")

	local pre_selected = { text = "pre", start_pos = { row = 0, col = 0 } }
	local ms = {
		selected_jump_target = pre_selected,
		jump_targets = {
			{ text = "hello", start_pos = { row = 0, col = 0 } },
		},
	}

	local exit_type = exit.wrap(function()
		visualizer.run(nil, nil, ms)
	end)

	-- Should use pre-selected target
	expect.equality(exit_type, "auto_select")
	expect.equality(ms.selected_jump_target.text, "pre")
end

T["pass_through"]["has dim_background=false in metadata"] = function()
	local visualizer = require("smart-motion.visualizers.pass_through")
	expect.no_equality(visualizer.metadata, nil)
	expect.equality(visualizer.metadata.motion_state.dim_background, false)
end

return T
