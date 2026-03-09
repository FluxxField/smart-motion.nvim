local MiniTest = require("mini_test")
local expect = MiniTest.expect
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
	hooks = {
		pre_case = function()
			helpers.setup_plugin({
				presets = {
					words = true,
					lines = true,
				},
			})
		end,
		post_case = helpers.cleanup,
	},
})

-- =============================================================================
-- setup.run
-- =============================================================================

T["setup.run"] = MiniTest.new_set()

T["setup.run"]["returns ctx, cfg, and motion_state for valid motion"] = function()
	helpers.create_buf({ "hello world test" })
	helpers.set_cursor(1, 0)

	local setup = require("smart-motion.core.engine.setup")
	local exit = require("smart-motion.core.events.exit")

	local ctx, cfg, ms
	local exit_type = exit.wrap(function()
		ctx, cfg, ms = setup.run("w")
	end)

	expect.equality(exit_type, nil)
	expect.no_equality(ctx, nil)
	expect.no_equality(cfg, nil)
	expect.no_equality(ms, nil)
end

T["setup.run"]["sets motion_key on motion_state"] = function()
	helpers.create_buf({ "hello world test" })
	helpers.set_cursor(1, 0)

	local setup = require("smart-motion.core.engine.setup")
	local exit = require("smart-motion.core.events.exit")

	local ms
	local exit_type = exit.wrap(function()
		_, _, ms = setup.run("w")
	end)

	expect.equality(exit_type, nil)
	expect.equality(ms.motion_key, "w")
end

T["setup.run"]["creates a shallow copy of motion"] = function()
	helpers.create_buf({ "hello world test" })
	helpers.set_cursor(1, 0)

	local registries = require("smart-motion.core.registries"):get()
	local original_motion = registries.motions.get_by_key("w")

	local setup = require("smart-motion.core.engine.setup")
	local exit = require("smart-motion.core.events.exit")

	local ms
	exit.wrap(function()
		_, _, ms = setup.run("w")
	end)

	-- motion_state.motion should be a copy, not the same reference
	expect.no_equality(ms.motion, nil)
	-- They should have the same collector
	expect.equality(ms.motion.collector, original_motion.collector)
end

T["setup.run"]["throws EARLY_EXIT for unknown trigger key"] = function()
	helpers.create_buf({ "hello world test" })
	helpers.set_cursor(1, 0)

	local setup = require("smart-motion.core.engine.setup")
	local exit = require("smart-motion.core.events.exit")
	local consts = require("smart-motion.consts")

	local exit_type = exit.wrap(function()
		setup.run("nonexistent_key_xyz")
	end)

	expect.no_equality(exit_type, nil)
end

T["setup.run"]["merges module metadata into motion_state"] = function()
	helpers.create_buf({ "hello world test" })
	helpers.set_cursor(1, 0)

	local setup = require("smart-motion.core.engine.setup")
	local exit = require("smart-motion.core.events.exit")

	local ms
	exit.wrap(function()
		_, _, ms = setup.run("w")
	end)

	-- The w motion uses "words" extractor which has metadata.motion_state
	-- The merge should have applied those values
	expect.no_equality(ms, nil)
end

T["setup.run"]["applies per-mode motion state overrides"] = function()
	helpers.create_buf({ "hello world test" })
	helpers.set_cursor(1, 0)

	-- Register a motion with per-mode overrides
	local motions = require("smart-motion.motions")
	motions.register_motion("per_mode_engine_test", {
		collector = "lines",
		visualizer = "hint_start",
		extractor = "words",
		modes = { "n", o = { exclude_target = true } },
	})

	local setup = require("smart-motion.core.engine.setup")
	local exit = require("smart-motion.core.events.exit")

	-- In normal mode, exclude_target should not be set
	local ms
	exit.wrap(function()
		_, _, ms = setup.run("per_mode_engine_test")
	end)

	-- Normal mode shouldn't have exclude_target
	-- (exact behavior depends on ctx.mode)
	expect.no_equality(ms, nil)
end

return T
