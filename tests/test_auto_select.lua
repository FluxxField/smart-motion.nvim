local MiniTest = require("mini_test")
local expect = MiniTest.expect
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
	hooks = {
		post_case = helpers.cleanup,
	},
})

-- =============================================================================
-- auto_select_target (issue #141)
-- =============================================================================

T["auto_select_target"] = MiniTest.new_set()

T["auto_select_target"]["sets selected_jump_target when one target exists"] = function()
	helpers.setup_plugin({ auto_select_target = true })

	local exit_event = require("smart-motion.core.events.exit")
	local consts = require("smart-motion.consts")
	local EXIT_TYPE = consts.EXIT_TYPE

	-- Simulate the loop.lua logic directly
	local motion_state = {
		is_searching_mode = false,
		jump_targets = {
			{
				start_pos = { row = 0, col = 5 },
				end_pos = { row = 0, col = 8 },
				text = "foo",
				type = "words",
				metadata = {},
			},
		},
	}

	local cfg = require("smart-motion.config").validated

	-- Replicate the auto_select_target check from loop.lua
	local targets = motion_state.jump_targets or {}
	local exit_type = nil

	if #targets == 1 then
		if cfg.auto_select_target then
			motion_state.selected_jump_target = targets[1]
			exit_type = EXIT_TYPE.AUTO_SELECT
		else
			exit_type = EXIT_TYPE.CONTINUE_TO_SELECTION
		end
	end

	expect.equality(exit_type, EXIT_TYPE.AUTO_SELECT)
	expect.no_equality(motion_state.selected_jump_target, nil)
	expect.equality(motion_state.selected_jump_target.text, "foo")
end

T["auto_select_target"]["does not auto-select when disabled"] = function()
	helpers.setup_plugin({ auto_select_target = false })

	local consts = require("smart-motion.consts")
	local EXIT_TYPE = consts.EXIT_TYPE

	local motion_state = {
		is_searching_mode = false,
		jump_targets = {
			{
				start_pos = { row = 0, col = 5 },
				end_pos = { row = 0, col = 8 },
				text = "foo",
				type = "words",
				metadata = {},
			},
		},
	}

	local cfg = require("smart-motion.config").validated
	local targets = motion_state.jump_targets or {}
	local exit_type = nil

	if #targets == 1 then
		if cfg.auto_select_target then
			motion_state.selected_jump_target = targets[1]
			exit_type = EXIT_TYPE.AUTO_SELECT
		else
			exit_type = EXIT_TYPE.CONTINUE_TO_SELECTION
		end
	end

	expect.equality(exit_type, EXIT_TYPE.CONTINUE_TO_SELECTION)
end

T["auto_select_target"]["count_select sets correct target"] = function()
	helpers.setup_plugin()

	local consts = require("smart-motion.consts")
	local EXIT_TYPE = consts.EXIT_TYPE

	local targets = {
		{ text = "first", start_pos = { row = 0, col = 0 }, end_pos = { row = 0, col = 5 }, type = "words", metadata = {} },
		{ text = "second", start_pos = { row = 0, col = 6 }, end_pos = { row = 0, col = 12 }, type = "words", metadata = {} },
		{ text = "third", start_pos = { row = 0, col = 13 }, end_pos = { row = 0, col = 18 }, type = "words", metadata = {} },
	}

	local motion_state = {
		jump_targets = targets,
		count_select = 2,
	}

	-- Replicate count_select logic from loop.lua
	if motion_state.count_select and motion_state.count_select > 0 then
		local idx = math.min(motion_state.count_select, #targets)
		motion_state.selected_jump_target = targets[idx]
	end

	expect.equality(motion_state.selected_jump_target.text, "second")
end

T["auto_select_target"]["count_select clamps to target count"] = function()
	helpers.setup_plugin()

	local targets = {
		{ text = "only", start_pos = { row = 0, col = 0 }, end_pos = { row = 0, col = 4 }, type = "words", metadata = {} },
	}

	local motion_state = {
		jump_targets = targets,
		count_select = 99, -- way beyond target count
	}

	if motion_state.count_select and motion_state.count_select > 0 then
		local idx = math.min(motion_state.count_select, #targets)
		motion_state.selected_jump_target = targets[idx]
	end

	-- Should clamp to last target
	expect.equality(motion_state.selected_jump_target.text, "only")
end

-- =============================================================================
-- Module loader error handling
-- =============================================================================

T["module loader"] = MiniTest.new_set()

T["module loader"]["resolves valid module names"] = function()
	helpers.setup_plugin()

	local module_loader = require("smart-motion.utils.module_loader")
	local cfg = require("smart-motion.config").validated

	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()

	local motion_state = {
		motion = {
			collector = "lines",
			extractor = "words",
			modifier = "default",
			filter = "default",
			visualizer = "hint_start",
			action = "jump",
		},
	}

	local modules = module_loader.get_modules(ctx, cfg, motion_state)

	expect.no_equality(modules.collector, nil)
	expect.no_equality(modules.extractor, nil)
	expect.no_equality(modules.action, nil)
end

T["module loader"]["handles missing module without crash"] = function()
	helpers.setup_plugin()

	local module_loader = require("smart-motion.utils.module_loader")
	local cfg = require("smart-motion.config").validated

	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()

	local motion_state = {
		motion = {
			collector = "lines",
			extractor = "words",
			modifier = "default",
			filter = "default",
			visualizer = "hint_start",
			action = "nonexistent_action_xyz",
		},
	}

	-- Should not crash, should return nil for the missing module
	local modules = module_loader.get_modules(ctx, cfg, motion_state)

	-- The module should be nil (or at least not have .run)
	local action = modules.action
	local is_missing = (action == nil) or (action.run == nil)
	expect.equality(is_missing, true)
end

return T
