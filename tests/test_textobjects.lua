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
-- Textobject Registry
-- =============================================================================

T["textobject_registry"] = MiniTest.new_set()

T["textobject_registry"]["register and get textobject"] = function()
	local motions = require("smart-motion.motions")

	motions.register_textobject("x", {
		collector = "treesitter",
		extractor = "pass_through",
		metadata = {
			label = "Test",
			motion_state = { test_flag = true },
		},
		inside = { test_inside = true },
		around = { test_around = true },
		default = "around",
	})

	local to = motions.get_textobject("x")
	expect.no_equality(to, nil)
	expect.equality(to.key, "x")
	expect.equality(to.collector, "treesitter")
	expect.equality(to.metadata.label, "Test")
	expect.equality(to.metadata.motion_state.test_flag, true)
	expect.equality(to.inside.test_inside, true)
	expect.equality(to.around.test_around, true)
	expect.equality(to.default, "around")
end

T["textobject_registry"]["get returns nil for unregistered key"] = function()
	local motions = require("smart-motion.motions")
	expect.equality(motions.get_textobject("Z"), nil)
end

T["textobject_registry"]["has returns true for registered, false for not"] = function()
	local motions = require("smart-motion.motions")

	motions.register_textobject("q", {
		collector = "treesitter",
		extractor = "pass_through",
	})

	expect.equality(motions.has_textobject("q"), true)
	expect.equality(motions.has_textobject("Z"), false)
end

T["textobject_registry"]["register_many registers multiple textobjects"] = function()
	local motions = require("smart-motion.motions")

	motions.register_many_textobjects({
		m = { collector = "treesitter", extractor = "pass_through" },
		n = { collector = "treesitter", extractor = "pass_through" },
	})

	expect.equality(motions.has_textobject("m"), true)
	expect.equality(motions.has_textobject("n"), true)
end

T["textobject_registry"]["defaults inside and around to empty tables"] = function()
	local motions = require("smart-motion.motions")

	motions.register_textobject("v", {
		collector = "treesitter",
		extractor = "pass_through",
	})

	local to = motions.get_textobject("v")
	expect.equality(type(to.inside), "table")
	expect.equality(type(to.around), "table")
	expect.equality(to.default, "around")
end

-- =============================================================================
-- Key Resolver
-- =============================================================================

T["key_resolver"] = MiniTest.new_set()

T["key_resolver"]["RESOLVE_TYPE constants exist"] = function()
	local key_resolver = require("smart-motion.core.key_resolver")
	expect.equality(key_resolver.RESOLVE_TYPE.TEXTOBJECT, "textobject")
	expect.equality(key_resolver.RESOLVE_TYPE.COMPOSABLE, "composable")
	expect.equality(key_resolver.RESOLVE_TYPE.FALLBACK, "fallback")
end

-- =============================================================================
-- Treesitter Textobject Registrations
-- =============================================================================

T["treesitter_textobjects"] = MiniTest.new_set({
	hooks = {
		pre_case = function()
			helpers.setup_plugin({ presets = { treesitter = true } })
		end,
		post_case = helpers.cleanup,
	},
})

T["treesitter_textobjects"]["f textobject is registered"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("f")
	expect.no_equality(to, nil)
	expect.equality(to.collector, "treesitter")
	expect.equality(to.extractor, "pass_through")
	expect.equality(to.default, "around")
end

T["treesitter_textobjects"]["f inside sets ts_inner_body"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("f")
	expect.equality(to.inside.ts_inner_body, true)
end

T["treesitter_textobjects"]["f around has no extra overrides"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("f")
	expect.equality(next(to.around), nil)
end

T["treesitter_textobjects"]["c textobject is registered for class"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("c")
	expect.no_equality(to, nil)
	expect.equality(to.collector, "treesitter")
	expect.equality(to.inside.ts_inner_body, true)
	expect.equality(to.default, "around")
end

T["treesitter_textobjects"]["a textobject is registered for argument"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("a")
	expect.no_equality(to, nil)
	expect.equality(to.collector, "treesitter")
	expect.equality(to.default, "inside")
end

T["treesitter_textobjects"]["a around sets ts_around_separator"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("a")
	expect.equality(to.around.ts_around_separator, true)
end

T["treesitter_textobjects"]["a inside has no extra overrides"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("a")
	expect.equality(next(to.inside), nil)
end

T["treesitter_textobjects"]["navigation motions still registered as composables"] = function()
	local motions = require("smart-motion.motions")
	-- These should still be regular composable motions, NOT textobjects
	expect.no_equality(motions.get_by_key("]]"), nil)
	expect.no_equality(motions.get_by_key("[["), nil)
	expect.no_equality(motions.get_by_key("]c"), nil)
	expect.no_equality(motions.get_by_key("[c"), nil)
end

T["treesitter_textobjects"]["fn still registered as composable motion"] = function()
	local motions = require("smart-motion.motions")
	local fn = motions.get_composable_by_key("fn")
	expect.no_equality(fn, nil)
	expect.equality(fn.collector, "treesitter")
end

-- =============================================================================
-- Pair Textobject Registrations
-- =============================================================================

T["pair_textobjects"] = MiniTest.new_set({
	hooks = {
		pre_case = function()
			helpers.setup_plugin({ presets = { surround = true } })
		end,
		post_case = helpers.cleanup,
	},
})

T["pair_textobjects"]["( textobject is registered"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("(")
	expect.no_equality(to, nil)
	expect.equality(to.collector, "pairs")
	expect.equality(to.extractor, "pairs")
	expect.equality(to.default, "around")
end

T["pair_textobjects"]["( inside sets pair_scope to inside"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("(")
	expect.equality(to.inside.pair_scope, "inside")
end

T["pair_textobjects"]["( around sets pair_scope to around"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("(")
	expect.equality(to.around.pair_scope, "around")
end

T["pair_textobjects"]["( surround sets pair_scope and is_surround"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("(")
	expect.equality(to.surround.pair_scope, "surround")
	expect.equality(to.surround.is_surround, true)
end

T["pair_textobjects"][") textobject is also registered (closing char)"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject(")")
	expect.no_equality(to, nil)
	expect.equality(to.collector, "pairs")
end

T["pair_textobjects"]["[ and ] textobjects are registered"] = function()
	local motions = require("smart-motion.motions")
	expect.no_equality(motions.get_textobject("["), nil)
	expect.no_equality(motions.get_textobject("]"), nil)
end

T["pair_textobjects"]["{ and } textobjects are registered"] = function()
	local motions = require("smart-motion.motions")
	expect.no_equality(motions.get_textobject("{"), nil)
	expect.no_equality(motions.get_textobject("}"), nil)
end

T["pair_textobjects"]["quote textobjects are registered"] = function()
	local motions = require("smart-motion.motions")
	expect.no_equality(motions.get_textobject('"'), nil)
	expect.no_equality(motions.get_textobject("'"), nil)
	expect.no_equality(motions.get_textobject("`"), nil)
end

T["pair_textobjects"]["symmetric delimiters register only once (no duplicate)"] = function()
	local motions = require("smart-motion.motions")
	-- For symmetric pairs like "", the open and close are the same char
	local to = motions.get_textobject('"')
	expect.no_equality(to, nil)
	expect.equality(to.inside.pair_scope, "inside")
end

-- =============================================================================
-- Surround Operators
-- =============================================================================

T["surround_operators"] = MiniTest.new_set({
	hooks = {
		pre_case = function()
			helpers.setup_plugin({ presets = { surround = true } })
		end,
		post_case = helpers.cleanup,
	},
})

T["surround_operators"]["ds operator is registered"] = function()
	local motions = require("smart-motion.motions")
	local ds = motions.get_by_key("ds")
	expect.no_equality(ds, nil)
	expect.equality(ds.infer, true)
	expect.equality(ds.action, "surround")
	expect.equality(ds.action_key, "d")
end

T["surround_operators"]["cs operator is registered"] = function()
	local motions = require("smart-motion.motions")
	local cs = motions.get_by_key("cs")
	expect.no_equality(cs, nil)
	expect.equality(cs.infer, true)
	expect.equality(cs.action, "surround")
	expect.equality(cs.action_key, "c")
end

T["surround_operators"]["ys operator is registered"] = function()
	local motions = require("smart-motion.motions")
	local ys = motions.get_by_key("ys")
	expect.no_equality(ys, nil)
	expect.equality(ys.infer, true)
	expect.equality(ys.action, "surround_add")
end

T["surround_operators"]["ds has textobject_key = surround in motion_state"] = function()
	local motions = require("smart-motion.motions")
	local ds = motions.get_by_key("ds")
	expect.equality(ds.metadata.motion_state.textobject_key, "surround")
end

T["surround_operators"]["cs has textobject_key = surround in motion_state"] = function()
	local motions = require("smart-motion.motions")
	local cs = motions.get_by_key("cs")
	expect.equality(cs.metadata.motion_state.textobject_key, "surround")
end

T["surround_operators"]["ys does NOT have textobject_key pre-set"] = function()
	local motions = require("smart-motion.motions")
	local ys = motions.get_by_key("ys")
	expect.equality(ys.metadata.motion_state.textobject_key, nil)
end

-- =============================================================================
-- Backwards Compatibility
-- =============================================================================

T["backwards_compat"] = MiniTest.new_set({
	hooks = {
		pre_case = function()
			helpers.setup_plugin({ presets = { treesitter = true, surround = true } })
		end,
		post_case = helpers.cleanup,
	},
})

T["backwards_compat"]["old af/if motions NOT in motion registry (replaced by textobjects)"] = function()
	local motions = require("smart-motion.motions")
	-- These should NOT exist as composable motions anymore
	expect.equality(motions.get_by_key("af"), nil)
	expect.equality(motions.get_by_key("if"), nil)
	expect.equality(motions.get_by_key("ac"), nil)
	expect.equality(motions.get_by_key("ic"), nil)
	expect.equality(motions.get_by_key("aa"), nil)
	expect.equality(motions.get_by_key("ia"), nil)
end

T["backwards_compat"]["old i(/a( motions NOT in motion registry (replaced by textobjects)"] = function()
	local motions = require("smart-motion.motions")
	expect.equality(motions.get_by_key("i("), nil)
	expect.equality(motions.get_by_key("a("), nil)
	expect.equality(motions.get_by_key("i)"), nil)
	expect.equality(motions.get_by_key("a)"), nil)
end

T["backwards_compat"]["old si(/sa( motions NOT in motion registry (replaced by ds/cs)"] = function()
	local motions = require("smart-motion.motions")
	expect.equality(motions.get_by_key("si("), nil)
	expect.equality(motions.get_by_key("sa("), nil)
end

T["backwards_compat"]["textobject f is accessible"] = function()
	local motions = require("smart-motion.motions")
	expect.no_equality(motions.get_textobject("f"), nil)
end

T["backwards_compat"]["textobject ( is accessible"] = function()
	local motions = require("smart-motion.motions")
	expect.no_equality(motions.get_textobject("("), nil)
end

T["backwards_compat"]["pairs extractor still available (legacy alias)"] = function()
	local registries = require("smart-motion.core.registries"):get()
	expect.no_equality(registries.extractors.get_by_name("pairs"), nil)
	expect.no_equality(registries.extractors.get_by_name("pairs_inside"), nil)
	expect.no_equality(registries.extractors.get_by_name("pairs_around"), nil)
	expect.no_equality(registries.extractors.get_by_name("pairs_surround"), nil)
end

-- =============================================================================
-- Infer Integration (textobject resolution)
-- =============================================================================

T["infer_textobject"] = MiniTest.new_set({
	hooks = {
		pre_case = function()
			helpers.setup_plugin({
				presets = {
					words = true,
					delete = true,
					treesitter = true,
					surround = true,
				},
			})
		end,
		post_case = helpers.cleanup,
	},
})

T["infer_textobject"]["apply_textobject merges base motion_state"] = function()
	-- Test the apply_textobject logic by simulating what infer does
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("f")

	-- Verify the textobject has the expected base motion_state
	expect.no_equality(to.metadata.motion_state.ts_node_types, nil)
	expect.equality(to.metadata.motion_state.is_textobject, true)
end

T["infer_textobject"]["apply_textobject merges inside overrides"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("f")

	-- Simulate what infer does: merge base + inside overrides
	local motion_state = {}
	for k, v in pairs(to.metadata.motion_state) do
		motion_state[k] = v
	end
	for k, v in pairs(to.inside) do
		motion_state[k] = v
	end

	expect.equality(motion_state.ts_inner_body, true)
	expect.equality(motion_state.is_textobject, true)
end

T["infer_textobject"]["apply_textobject merges around overrides for argument"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("a")

	local motion_state = {}
	for k, v in pairs(to.metadata.motion_state) do
		motion_state[k] = v
	end
	for k, v in pairs(to.around) do
		motion_state[k] = v
	end

	expect.equality(motion_state.ts_around_separator, true)
	expect.equality(motion_state.ts_yield_children, true)
end

T["infer_textobject"]["apply_textobject merges surround overrides for pair"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("(")

	local motion_state = {}
	for k, v in pairs(to.metadata.motion_state) do
		motion_state[k] = v
	end
	for k, v in pairs(to.surround) do
		motion_state[k] = v
	end

	expect.equality(motion_state.pair_scope, "surround")
	expect.equality(motion_state.is_surround, true)
	expect.equality(motion_state.is_textobject, true)
end

T["infer_textobject"]["composable w is still accessible for dw"] = function()
	local motions = require("smart-motion.motions")
	local w = motions.get_composable_by_key("w")
	expect.no_equality(w, nil)
	expect.equality(w.extractor, "words")
end

T["infer_textobject"]["d operator still resolves to delete action"] = function()
	local motions = require("smart-motion.motions")
	local d = motions.get_by_key("d")
	expect.no_equality(d, nil)
	expect.equality(d.infer, true)
end

-- =============================================================================
-- Module Loader (action resolution for surround operators)
-- =============================================================================

T["module_loader"] = MiniTest.new_set({
	hooks = {
		pre_case = function()
			helpers.setup_plugin({ presets = { surround = true, delete = true, words = true } })
		end,
		post_case = helpers.cleanup,
	},
})

T["module_loader"]["surround action is registered"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local surround_action = registries.actions.get_by_name("surround")
	expect.no_equality(surround_action, nil)
	expect.equality(type(surround_action.run), "function")
end

T["module_loader"]["surround_add action is registered"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local surround_add = registries.actions.get_by_name("surround_add")
	expect.no_equality(surround_add, nil)
	expect.equality(type(surround_add.run), "function")
end

return T
