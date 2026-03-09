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
-- _validate_motion_entry
-- =============================================================================

T["_validate_motion_entry"] = MiniTest.new_set()

T["_validate_motion_entry"]["accepts valid motion"] = function()
	local motions = require("smart-motion.motions")

	local result = motions._validate_motion_entry("test_valid", {
		collector = "lines",
		visualizer = "hint_start",
	})

	expect.equality(result, true)
end

T["_validate_motion_entry"]["rejects empty name"] = function()
	local motions = require("smart-motion.motions")

	local result = motions._validate_motion_entry("", {
		collector = "lines",
		visualizer = "hint_start",
	})

	expect.equality(result, false)
end

T["_validate_motion_entry"]["rejects missing collector"] = function()
	local motions = require("smart-motion.motions")

	local result = motions._validate_motion_entry("test_no_collector", {
		visualizer = "hint_start",
	})

	expect.equality(result, false)
end

T["_validate_motion_entry"]["rejects missing visualizer"] = function()
	local motions = require("smart-motion.motions")

	local result = motions._validate_motion_entry("test_no_viz", {
		collector = "lines",
	})

	expect.equality(result, false)
end

T["_validate_motion_entry"]["rejects unknown collector"] = function()
	local motions = require("smart-motion.motions")

	local result = motions._validate_motion_entry("test_bad_collector", {
		collector = "nonexistent_collector",
		visualizer = "hint_start",
	})

	expect.equality(result, false)
end

T["_validate_motion_entry"]["rejects unknown visualizer"] = function()
	local motions = require("smart-motion.motions")

	local result = motions._validate_motion_entry("test_bad_viz", {
		collector = "lines",
		visualizer = "nonexistent_visualizer",
	})

	expect.equality(result, false)
end

-- =============================================================================
-- register_motion
-- =============================================================================

T["register_motion"] = MiniTest.new_set()

T["register_motion"]["sets name and defaults"] = function()
	local motions = require("smart-motion.motions")

	motions.register_motion("test_reg", {
		collector = "lines",
		visualizer = "hint_start",
	})

	local motion = motions.get_by_name("test_reg")
	expect.no_equality(motion, nil)
	expect.equality(motion.name, "test_reg")
	expect.equality(motion.trigger_key, "test_reg")
	expect.equality(motion.action_key, "test_reg")
	expect.no_equality(motion.metadata, nil)
	expect.no_equality(motion.metadata.label, nil)
	expect.no_equality(motion.metadata.description, nil)
end

T["register_motion"]["uses custom trigger_key"] = function()
	local motions = require("smart-motion.motions")

	motions.register_motion("custom_key", {
		collector = "lines",
		visualizer = "hint_start",
		trigger_key = "ck",
	})

	local motion = motions.get_by_key("ck")
	expect.no_equality(motion, nil)
	expect.equality(motion.name, "custom_key")
end

T["register_motion"]["does not register invalid motion"] = function()
	local motions = require("smart-motion.motions")

	motions.register_motion("invalid_motion", {
		-- missing collector and visualizer
	})

	local motion = motions.get_by_name("invalid_motion")
	expect.equality(motion, nil)
end

T["register_motion"]["parses per-mode motion state from modes"] = function()
	local motions = require("smart-motion.motions")

	motions.register_motion("per_mode_test", {
		collector = "lines",
		visualizer = "hint_start",
		modes = { "n", "x", o = { exclude_target = true } },
	})

	local motion = motions.get_by_name("per_mode_test")
	expect.no_equality(motion, nil)
	expect.no_equality(motion.per_mode_motion_state, nil)
	expect.equality(motion.per_mode_motion_state.o.exclude_target, true)
end

-- =============================================================================
-- register_many_motions
-- =============================================================================

T["register_many_motions"] = MiniTest.new_set()

T["register_many_motions"]["registers multiple motions"] = function()
	local motions = require("smart-motion.motions")

	motions.register_many_motions({
		multi_a = { collector = "lines", visualizer = "hint_start" },
		multi_b = { collector = "lines", visualizer = "hint_end" },
	})

	expect.no_equality(motions.get_by_name("multi_a"), nil)
	expect.no_equality(motions.get_by_name("multi_b"), nil)
end

T["register_many_motions"]["skips already registered without override"] = function()
	local motions = require("smart-motion.motions")

	motions.register_motion("dup_test", {
		collector = "lines",
		visualizer = "hint_start",
	})

	-- Try to register again without override
	motions.register_many_motions({
		dup_test = { collector = "lines", visualizer = "hint_end" },
	}, { override = false })

	-- Should still have original
	local motion = motions.get_by_name("dup_test")
	expect.equality(motion.visualizer, "hint_start")
end

T["register_many_motions"]["overrides with override flag"] = function()
	local motions = require("smart-motion.motions")

	motions.register_motion("override_test", {
		collector = "lines",
		visualizer = "hint_start",
	})

	motions.register_many_motions({
		override_test = { collector = "lines", visualizer = "hint_end" },
	}, { override = true })

	local motion = motions.get_by_name("override_test")
	expect.equality(motion.visualizer, "hint_end")
end

-- =============================================================================
-- has_composable_with_prefix
-- =============================================================================

T["has_composable_with_prefix"] = MiniTest.new_set()

T["has_composable_with_prefix"]["finds composable with prefix"] = function()
	local motions = require("smart-motion.motions")

	-- Register a composable motion with a multi-char trigger key
	motions.register_motion("gx_test", {
		collector = "lines",
		visualizer = "hint_start",
		trigger_key = "gx",
		composable = true,
	})

	-- There should be a composable motion starting with "g" but not equal to "g"
	local result = motions.has_composable_with_prefix("g")
	expect.equality(result, true)
end

T["has_composable_with_prefix"]["returns false for no match"] = function()
	local motions = require("smart-motion.motions")

	local result = motions.has_composable_with_prefix("zzz")
	expect.equality(result, false)
end

-- =============================================================================
-- get_composable_by_key
-- =============================================================================

T["get_composable_by_key"] = MiniTest.new_set()

T["get_composable_by_key"]["returns composable motion"] = function()
	local motions = require("smart-motion.motions")

	local motion = motions.get_composable_by_key("w")
	expect.no_equality(motion, nil)
	expect.equality(motion.composable, true)
end

T["get_composable_by_key"]["returns nil for non-composable"] = function()
	local motions = require("smart-motion.motions")

	-- Register a non-composable motion for this test
	motions.register_motion("nc_test", {
		collector = "lines",
		visualizer = "hint_start",
		trigger_key = "nc_test",
		composable = false,
	})

	local motion = motions.get_composable_by_key("nc_test")
	expect.equality(motion, nil)
end

T["get_composable_by_key"]["returns nil for unregistered key"] = function()
	local motions = require("smart-motion.motions")

	local motion = motions.get_composable_by_key("zzz")
	expect.equality(motion, nil)
end

return T
