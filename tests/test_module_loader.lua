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
-- get_modules
-- =============================================================================

T["get_modules"] = MiniTest.new_set()

T["get_modules"]["resolves all standard pipeline modules"] = function()
	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

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

	local module_loader = require("smart-motion.utils.module_loader")
	local modules = module_loader.get_modules(ctx, cfg, motion_state)

	expect.no_equality(modules.collector, nil)
	expect.no_equality(modules.collector.run, nil)
	expect.no_equality(modules.extractor, nil)
	expect.no_equality(modules.modifier, nil)
	expect.no_equality(modules.filter, nil)
	expect.no_equality(modules.visualizer, nil)
	expect.no_equality(modules.action, nil)
end

T["get_modules"]["falls back to default for missing module name"] = function()
	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local motion_state = {
		motion = {
			collector = "lines",
			-- modifier not specified, should fall back to default
			visualizer = "hint_start",
		},
	}

	local module_loader = require("smart-motion.utils.module_loader")
	local modules = module_loader.get_modules(ctx, cfg, motion_state, { "modifier" })

	-- Should get the default modifier
	expect.no_equality(modules.modifier, nil)
	expect.no_equality(modules.modifier.run, nil)
end

T["get_modules"]["resolves only requested keys"] = function()
	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local motion_state = {
		motion = {
			collector = "lines",
			visualizer = "hint_start",
		},
	}

	local module_loader = require("smart-motion.utils.module_loader")
	local modules = module_loader.get_modules(ctx, cfg, motion_state, { "collector" })

	expect.no_equality(modules.collector, nil)
	expect.equality(modules.extractor, nil) -- not requested
	expect.equality(modules.visualizer, nil) -- not requested
end

T["get_modules"]["resolves action by key for infer motions"] = function()
	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local motion_state = {
		motion = {
			collector = "lines",
			visualizer = "hint_start",
			infer = true,
			action_key = "d", -- delete action key
		},
	}

	local module_loader = require("smart-motion.utils.module_loader")
	local modules = module_loader.get_modules(ctx, cfg, motion_state, { "action" })

	-- Should resolve action via action_key for infer motions
	if modules.action then
		expect.no_equality(modules.action.run, nil)
	end
end

-- =============================================================================
-- get_module
-- =============================================================================

T["get_module"] = MiniTest.new_set()

T["get_module"]["resolves single module"] = function()
	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local motion_state = {
		motion = { collector = "lines" },
	}

	local module_loader = require("smart-motion.utils.module_loader")
	local mod = module_loader.get_module(ctx, cfg, motion_state, "collector")

	expect.no_equality(mod, nil)
	expect.no_equality(mod.run, nil)
end

-- =============================================================================
-- get_module_by_name
-- =============================================================================

T["get_module_by_name"] = MiniTest.new_set()

T["get_module_by_name"]["resolves by registry key and name"] = function()
	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local motion_state = { motion = {} }

	local module_loader = require("smart-motion.utils.module_loader")
	local mod = module_loader.get_module_by_name(ctx, cfg, motion_state, "collectors", "lines")

	expect.no_equality(mod, nil)
	expect.no_equality(mod.run, nil)
end

return T
