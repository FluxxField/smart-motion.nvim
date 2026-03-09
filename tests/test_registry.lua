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
-- Registry creation and lookup
-- =============================================================================

T["registry"] = MiniTest.new_set()

T["registry"]["register and get_by_name"] = function()
	local make_registry = require("smart-motion.core.registry")
	local reg = make_registry("test")

	reg.register("my_module", {
		run = function() end,
		metadata = { label = "Test" },
	})

	local entry = reg.get_by_name("my_module")
	expect.no_equality(entry, nil)
	expect.equality(entry.name, "my_module")
end

T["registry"]["register and get_by_key"] = function()
	local make_registry = require("smart-motion.core.registry")
	local reg = make_registry("test")

	reg.register("my_module", {
		keys = { "x", "y" },
		run = function() end,
	})

	local by_x = reg.get_by_key("x")
	local by_y = reg.get_by_key("y")
	expect.no_equality(by_x, nil)
	expect.equality(by_x.name, "my_module")
	expect.equality(by_y.name, "my_module")
end

T["registry"]["get_by_name returns nil for unknown"] = function()
	local make_registry = require("smart-motion.core.registry")
	local reg = make_registry("test")

	expect.equality(reg.get_by_name("nonexistent"), nil)
end

T["registry"]["get_by_key returns nil for unknown"] = function()
	local make_registry = require("smart-motion.core.registry")
	local reg = make_registry("test")

	expect.equality(reg.get_by_key("z"), nil)
end

T["registry"]["register_many adds multiple modules"] = function()
	local make_registry = require("smart-motion.core.registry")
	local reg = make_registry("test")

	reg.register_many({
		alpha = { run = function() end },
		beta = { run = function() end },
	})

	expect.no_equality(reg.get_by_name("alpha"), nil)
	expect.no_equality(reg.get_by_name("beta"), nil)
end

T["registry"]["register_many skips duplicates without override"] = function()
	local make_registry = require("smart-motion.core.registry")
	local reg = make_registry("test")

	reg.register("dup", {
		run = function() return "first" end,
		metadata = { label = "First" },
	})

	reg.register_many({
		dup = {
			run = function() return "second" end,
			metadata = { label = "Second" },
		},
	})

	-- Should still have the first registration
	expect.equality(reg.get_by_name("dup").metadata.label, "First")
end

T["registry"]["register_many with override replaces"] = function()
	local make_registry = require("smart-motion.core.registry")
	local reg = make_registry("test")

	reg.register("dup", {
		run = function() return "first" end,
		metadata = { label = "First" },
	})

	reg.register_many({
		dup = {
			run = function() return "second" end,
			metadata = { label = "Second" },
		},
	}, { override = true })

	expect.equality(reg.get_by_name("dup").metadata.label, "Second")
end

T["registry"]["sets default metadata when missing"] = function()
	local make_registry = require("smart-motion.core.registry")
	local reg = make_registry("test")

	reg.register("bare_module", {
		run = function() end,
	})

	local entry = reg.get_by_name("bare_module")
	expect.no_equality(entry.metadata, nil)
	expect.no_equality(entry.metadata.label, nil)
	expect.no_equality(entry.metadata.description, nil)
	expect.equality(type(entry.metadata.motion_state), "table")
end

-- =============================================================================
-- Registries manager
-- =============================================================================

T["registries"] = MiniTest.new_set()

T["registries"]["all standard registries are present after setup"] = function()
	local registries = require("smart-motion.core.registries"):get()

	local expected = {
		"collectors",
		"extractors",
		"filters",
		"modifiers",
		"visualizers",
		"actions",
		"motions",
	}

	for _, name in ipairs(expected) do
		expect.no_equality(registries[name], nil)
	end
end

T["registries"]["standard modules are registered"] = function()
	local registries = require("smart-motion.core.registries"):get()

	-- Collectors
	expect.no_equality(registries.collectors.get_by_name("lines"), nil)

	-- Extractors
	expect.no_equality(registries.extractors.get_by_name("words"), nil)

	-- Filters
	expect.no_equality(registries.filters.get_by_name("default"), nil)

	-- Modifiers
	expect.no_equality(registries.modifiers.get_by_name("default"), nil)

	-- Actions
	expect.no_equality(registries.actions.get_by_name("jump"), nil)
	expect.no_equality(registries.actions.get_by_name("yank_jump"), nil)
end

return T
