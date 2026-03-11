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
-- Plugin API after setup
-- =============================================================================

T["api"] = MiniTest.new_set()

T["api"]["exposes motions registry interface"] = function()
	local sm = require("smart-motion")

	expect.no_equality(sm.motions, nil)
	expect.no_equality(sm.motions.register, nil)
	expect.no_equality(sm.motions.register_many, nil)
	expect.no_equality(sm.motions.map_motion, nil)
	expect.no_equality(sm.motions.get_by_key, nil)
	expect.no_equality(sm.motions.get_by_name, nil)
end

T["api"]["exposes collectors registry interface"] = function()
	local sm = require("smart-motion")

	expect.no_equality(sm.collectors, nil)
	expect.no_equality(sm.collectors.register, nil)
	expect.no_equality(sm.collectors.get_by_name, nil)
end

T["api"]["exposes extractors registry interface"] = function()
	local sm = require("smart-motion")

	expect.no_equality(sm.extractors, nil)
	expect.no_equality(sm.extractors.register, nil)
	expect.no_equality(sm.extractors.get_by_name, nil)
end

T["api"]["exposes filters registry interface"] = function()
	local sm = require("smart-motion")

	expect.no_equality(sm.filters, nil)
	expect.no_equality(sm.filters.register, nil)
	expect.no_equality(sm.filters.get_by_name, nil)
end

T["api"]["exposes visualizers registry interface"] = function()
	local sm = require("smart-motion")

	expect.no_equality(sm.visualizers, nil)
	expect.no_equality(sm.visualizers.register, nil)
	expect.no_equality(sm.visualizers.get_by_name, nil)
end

T["api"]["exposes actions registry interface"] = function()
	local sm = require("smart-motion")

	expect.no_equality(sm.actions, nil)
	expect.no_equality(sm.actions.register, nil)
	expect.no_equality(sm.actions.get_by_name, nil)
end

T["api"]["exposes selection_handlers registry interface"] = function()
	local sm = require("smart-motion")

	expect.no_equality(sm.selection_handlers, nil)
	expect.no_equality(sm.selection_handlers.register, nil)
	expect.no_equality(sm.selection_handlers.get_by_name, nil)
end

T["api"]["exposes merge utilities"] = function()
	local sm = require("smart-motion")

	expect.no_equality(sm.merge_actions, nil)
	expect.no_equality(sm.merge_filters, nil)
end

T["api"]["exposes consts"] = function()
	local sm = require("smart-motion")

	expect.no_equality(sm.consts, nil)
	expect.no_equality(sm.consts.DIRECTION, nil)
	expect.no_equality(sm.consts.EXIT_TYPE, nil)
end

T["api"]["can register custom motion via API"] = function()
	local sm = require("smart-motion")

	sm.motions.register("custom_api_motion", {
		collector = "lines",
		visualizer = "hint_start",
		extractor = "words",
	})

	local motion = sm.motions.get_by_name("custom_api_motion")
	expect.no_equality(motion, nil)
	expect.equality(motion.collector, "lines")
end

T["api"]["can register custom collector via API"] = function()
	local sm = require("smart-motion")

	sm.collectors.register("custom_test_collector", {
		run = function()
			return coroutine.create(function() end)
		end,
	})

	local collector = sm.collectors.get_by_name("custom_test_collector")
	expect.no_equality(collector, nil)
	expect.no_equality(collector.run, nil)
end

T["api"]["can register custom action via API"] = function()
	local sm = require("smart-motion")

	sm.actions.register("custom_test_action", {
		run = function() end,
	})

	local action = sm.actions.get_by_name("custom_test_action")
	expect.no_equality(action, nil)
end

-- =============================================================================
-- Setup with different configs
-- =============================================================================

T["setup"] = MiniTest.new_set()

T["setup"]["can be called multiple times"] = function()
	helpers.cleanup()

	helpers.setup_plugin({ presets = { words = true } })
	local sm = require("smart-motion")
	expect.no_equality(sm.motions.get_by_name("w"), nil)

	helpers.cleanup()

	helpers.setup_plugin({ presets = { lines = true } })
	sm = require("smart-motion")
	expect.no_equality(sm.motions.get_by_name("j"), nil)
end

T["setup"]["respects preset false to skip registration"] = function()
	helpers.cleanup()

	helpers.setup_plugin({
		presets = {
			words = false,
			lines = true,
		},
	})

	local sm = require("smart-motion")
	expect.equality(sm.motions.get_by_name("w"), nil)
	expect.no_equality(sm.motions.get_by_name("j"), nil)
end

return T
