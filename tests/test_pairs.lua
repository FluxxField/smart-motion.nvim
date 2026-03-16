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
-- pair_defs
-- =============================================================================

T["pair_defs"] = MiniTest.new_set()

T["pair_defs"]["get_pair returns correct pair for open char"] = function()
	local pair_defs = require("smart-motion.utils.pair_defs")

	local p = pair_defs.get_pair("(")
	expect.equality(p.open, "(")
	expect.equality(p.close, ")")

	p = pair_defs.get_pair("{")
	expect.equality(p.open, "{")
	expect.equality(p.close, "}")

	p = pair_defs.get_pair("[")
	expect.equality(p.open, "[")
	expect.equality(p.close, "]")

	p = pair_defs.get_pair("<")
	expect.equality(p.open, "<")
	expect.equality(p.close, ">")
end

T["pair_defs"]["get_pair returns correct pair for close char"] = function()
	local pair_defs = require("smart-motion.utils.pair_defs")

	local p = pair_defs.get_pair(")")
	expect.equality(p.open, "(")
	expect.equality(p.close, ")")

	p = pair_defs.get_pair("}")
	expect.equality(p.open, "{")
	expect.equality(p.close, "}")
end

T["pair_defs"]["get_pair handles symmetric delimiters"] = function()
	local pair_defs = require("smart-motion.utils.pair_defs")

	local p = pair_defs.get_pair('"')
	expect.equality(p.open, '"')
	expect.equality(p.close, '"')

	p = pair_defs.get_pair("'")
	expect.equality(p.open, "'")
	expect.equality(p.close, "'")

	p = pair_defs.get_pair("`")
	expect.equality(p.open, "`")
	expect.equality(p.close, "`")
end

T["pair_defs"]["get_pair returns nil for unknown char"] = function()
	local pair_defs = require("smart-motion.utils.pair_defs")
	expect.equality(pair_defs.get_pair("x"), nil)
	expect.equality(pair_defs.get_pair("1"), nil)
end

-- =============================================================================
-- pairs collector
-- =============================================================================

T["pairs collector"] = MiniTest.new_set()

T["pairs collector"]["finds matching parentheses"] = function()
	helpers.create_buf({ "foo(bar) baz(qux)" })
	helpers.set_cursor(1, 0)

	local collector = require("smart-motion.collectors.pairs")
	local gen = collector.run()

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local ms = { pair_chars = { { "(", ")" } } }

	local results = {}
	local ok, data = coroutine.resume(gen, ctx, cfg, ms)
	while ok and data do
		table.insert(results, data)
		ok, data = coroutine.resume(gen, ctx, cfg, ms)
	end

	expect.equality(#results >= 2, true)
	-- First pair: (bar)
	expect.equality(results[1].pair_open, "(")
	expect.equality(results[1].pair_close, ")")
	expect.equality(results[1].content_text, "bar")
end

T["pairs collector"]["finds nested pairs"] = function()
	helpers.create_buf({ "foo(bar(baz))" })
	helpers.set_cursor(1, 0)

	local collector = require("smart-motion.collectors.pairs")
	local gen = collector.run()

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local ms = { pair_chars = { { "(", ")" } } }

	local results = {}
	local ok, data = coroutine.resume(gen, ctx, cfg, ms)
	while ok and data do
		table.insert(results, data)
		ok, data = coroutine.resume(gen, ctx, cfg, ms)
	end

	expect.equality(#results >= 2, true)
end

T["pairs collector"]["finds curly braces"] = function()
	helpers.create_buf({ "if {x} then {y}" })
	helpers.set_cursor(1, 0)

	local collector = require("smart-motion.collectors.pairs")
	local gen = collector.run()

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local ms = { pair_chars = { { "{", "}" } } }

	local results = {}
	local ok, data = coroutine.resume(gen, ctx, cfg, ms)
	while ok and data do
		table.insert(results, data)
		ok, data = coroutine.resume(gen, ctx, cfg, ms)
	end

	expect.equality(#results >= 2, true)
	expect.equality(results[1].pair_open, "{")
	expect.equality(results[1].pair_close, "}")
end

T["pairs collector"]["finds quotes on same line"] = function()
	helpers.create_buf({ 'foo "bar" baz "qux"' })
	helpers.set_cursor(1, 0)

	local collector = require("smart-motion.collectors.pairs")
	local gen = collector.run()

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local ms = { pair_chars = { { '"', '"' } } }

	local results = {}
	local ok, data = coroutine.resume(gen, ctx, cfg, ms)
	while ok and data do
		table.insert(results, data)
		ok, data = coroutine.resume(gen, ctx, cfg, ms)
	end

	expect.equality(#results >= 2, true)
	expect.equality(results[1].content_text, "bar")
end

T["pairs collector"]["returns nothing when no pair_chars specified"] = function()
	helpers.create_buf({ "foo(bar)" })
	helpers.set_cursor(1, 0)

	local collector = require("smart-motion.collectors.pairs")
	local gen = collector.run()

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local ms = {} -- no pair_chars

	local results = {}
	local ok, data = coroutine.resume(gen, ctx, cfg, ms)
	while ok and data do
		table.insert(results, data)
		ok, data = coroutine.resume(gen, ctx, cfg, ms)
	end

	expect.equality(#results, 0)
end

-- =============================================================================
-- pairs extractor
-- =============================================================================

T["pairs extractor"] = MiniTest.new_set()

T["pairs extractor"]["inside scope extracts content between delimiters"] = function()
	local extractor = require("smart-motion.extractors.pairs")

	local data = {
		open_pos = { start = { row = 0, col = 3 }, ["end"] = { row = 0, col = 4 } },
		close_pos = { start = { row = 0, col = 7 }, ["end"] = { row = 0, col = 8 } },
		pair_open = "(",
		pair_close = ")",
		content_text = "bar",
		full_text = "(bar)",
	}

	local ms = { pair_scope = "inside", is_surround = false }
	local result = extractor.run(nil, nil, ms, data)

	expect.equality(result.text, "bar")
	expect.equality(result.start_pos.row, 0)
	expect.equality(result.start_pos.col, 4) -- after open delimiter
	expect.equality(result.end_pos.col, 7)   -- before close delimiter
	expect.equality(result.type, "pairs")
end

T["pairs extractor"]["around scope extracts full pair"] = function()
	local extractor = require("smart-motion.extractors.pairs")

	local data = {
		open_pos = { start = { row = 0, col = 3 }, ["end"] = { row = 0, col = 4 } },
		close_pos = { start = { row = 0, col = 7 }, ["end"] = { row = 0, col = 8 } },
		pair_open = "(",
		pair_close = ")",
		content_text = "bar",
		full_text = "(bar)",
	}

	local ms = { pair_scope = "around", is_surround = false }
	local result = extractor.run(nil, nil, ms, data)

	expect.equality(result.text, "(bar)")
	expect.equality(result.start_pos.col, 3) -- open start
	expect.equality(result.end_pos.col, 8)   -- close end
end

T["pairs extractor"]["surround mode preserves delimiter positions in metadata"] = function()
	local extractor = require("smart-motion.extractors.pairs")

	local data = {
		open_pos = { start = { row = 0, col = 3 }, ["end"] = { row = 0, col = 4 } },
		close_pos = { start = { row = 0, col = 7 }, ["end"] = { row = 0, col = 8 } },
		pair_open = "(",
		pair_close = ")",
		content_text = "bar",
		full_text = "(bar)",
	}

	local ms = { is_surround = true }
	local result = extractor.run(nil, nil, ms, data)

	expect.equality(result.text, "(bar)")
	expect.equality(result.metadata.is_surround, true)
	expect.equality(result.metadata.open_pos.start.col, 3)
	expect.equality(result.metadata.close_pos.start.col, 7)
	expect.equality(result.metadata.pair_open, "(")
	expect.equality(result.metadata.pair_close, ")")
end

T["pairs extractor"]["defaults to inside scope"] = function()
	local extractor = require("smart-motion.extractors.pairs")

	local data = {
		open_pos = { start = { row = 0, col = 3 }, ["end"] = { row = 0, col = 4 } },
		close_pos = { start = { row = 0, col = 7 }, ["end"] = { row = 0, col = 8 } },
		pair_open = "(",
		pair_close = ")",
		content_text = "bar",
		full_text = "(bar)",
	}

	-- No pair_scope set — should default to "inside"
	local ms = {}
	local result = extractor.run(nil, nil, ms, data)

	expect.equality(result.text, "bar")
end

-- =============================================================================
-- surround action
-- =============================================================================

T["surround action"] = MiniTest.new_set()

T["surround action"]["delete removes delimiters"] = function()
	local bufnr = helpers.create_buf({ "foo(bar)baz" })
	helpers.set_cursor(1, 0)

	local surround = require("smart-motion.actions.surround")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local ms = {
		motion = { action_key = "d" },
		selected_jump_target = {
			start_pos = { row = 0, col = 3 },
			end_pos = { row = 0, col = 8 },
			text = "(bar)",
			metadata = {
				bufnr = bufnr,
				is_surround = true,
				open_pos = { start = { row = 0, col = 3 }, ["end"] = { row = 0, col = 4 } },
				close_pos = { start = { row = 0, col = 7 }, ["end"] = { row = 0, col = 8 } },
				pair_open = "(",
				pair_close = ")",
			},
		},
	}

	surround.run(ctx, cfg, ms)

	local lines = helpers.get_buf_lines()
	expect.equality(lines[1], "foobarbaz")
end

T["surround action"]["yank stores pair in register and global"] = function()
	local bufnr = helpers.create_buf({ "foo(bar)baz" })
	helpers.set_cursor(1, 0)

	local surround = require("smart-motion.actions.surround")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local ms = {
		motion = { action_key = "y" },
		selected_jump_target = {
			start_pos = { row = 0, col = 3 },
			end_pos = { row = 0, col = 8 },
			text = "(bar)",
			metadata = {
				bufnr = bufnr,
				is_surround = true,
				open_pos = { start = { row = 0, col = 3 }, ["end"] = { row = 0, col = 4 } },
				close_pos = { start = { row = 0, col = 7 }, ["end"] = { row = 0, col = 8 } },
				pair_open = "(",
				pair_close = ")",
			},
		},
	}

	surround.run(ctx, cfg, ms)

	-- Buffer should be unchanged
	local lines = helpers.get_buf_lines()
	expect.equality(lines[1], "foo(bar)baz")

	-- Register should contain the pair characters
	expect.equality(helpers.get_register('"'), "()")

	-- Global should store pair for paste surround
	expect.equality(vim.g.smart_motion_surround_pair, "()")
end

T["surround action"]["delete handles empty pair"] = function()
	local bufnr = helpers.create_buf({ "foo()baz" })
	helpers.set_cursor(1, 0)

	local surround = require("smart-motion.actions.surround")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local ms = {
		motion = { action_key = "d" },
		selected_jump_target = {
			start_pos = { row = 0, col = 3 },
			end_pos = { row = 0, col = 5 },
			text = "()",
			metadata = {
				bufnr = bufnr,
				is_surround = true,
				open_pos = { start = { row = 0, col = 3 }, ["end"] = { row = 0, col = 4 } },
				close_pos = { start = { row = 0, col = 4 }, ["end"] = { row = 0, col = 5 } },
				pair_open = "(",
				pair_close = ")",
			},
		},
	}

	surround.run(ctx, cfg, ms)

	local lines = helpers.get_buf_lines()
	expect.equality(lines[1], "foobaz")
end

T["surround action"]["delete handles curly braces"] = function()
	local bufnr = helpers.create_buf({ "let x = {value}" })
	helpers.set_cursor(1, 0)

	local surround = require("smart-motion.actions.surround")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local ms = {
		motion = { action_key = "d" },
		selected_jump_target = {
			start_pos = { row = 0, col = 8 },
			end_pos = { row = 0, col = 15 },
			text = "{value}",
			metadata = {
				bufnr = bufnr,
				is_surround = true,
				open_pos = { start = { row = 0, col = 8 }, ["end"] = { row = 0, col = 9 } },
				close_pos = { start = { row = 0, col = 14 }, ["end"] = { row = 0, col = 15 } },
				pair_open = "{",
				pair_close = "}",
			},
		},
	}

	surround.run(ctx, cfg, ms)

	local lines = helpers.get_buf_lines()
	expect.equality(lines[1], "let x = value")
end

-- =============================================================================
-- Pairs collector edge cases
-- =============================================================================

T["pairs collector edge cases"] = MiniTest.new_set()

T["pairs collector edge cases"]["handles empty pairs"] = function()
	helpers.create_buf({ "foo() bar()" })
	helpers.set_cursor(1, 0)

	local collector = require("smart-motion.collectors.pairs")
	local gen = collector.run()

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local ms = { pair_chars = { { "(", ")" } } }

	local results = {}
	local ok, data = coroutine.resume(gen, ctx, cfg, ms)
	while ok and data do
		table.insert(results, data)
		ok, data = coroutine.resume(gen, ctx, cfg, ms)
	end

	expect.equality(#results >= 2, true)
	expect.equality(results[1].content_text, "")
end

T["pairs collector edge cases"]["handles multiline pairs"] = function()
	helpers.create_buf({ "foo(", "  bar", ")" })
	helpers.set_cursor(1, 0)

	local collector = require("smart-motion.collectors.pairs")
	local gen = collector.run()

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local ms = { pair_chars = { { "(", ")" } } }

	local results = {}
	local ok, data = coroutine.resume(gen, ctx, cfg, ms)
	while ok and data do
		table.insert(results, data)
		ok, data = coroutine.resume(gen, ctx, cfg, ms)
	end

	expect.equality(#results >= 1, true)
	expect.equality(results[1].open_pos.start.row, 0)
	expect.equality(results[1].close_pos.start.row, 2)
end

-- =============================================================================
-- Registry integration
-- =============================================================================

T["registry"] = MiniTest.new_set()

T["registry"]["pairs collector is registered"] = function()
	local registries = require("smart-motion.core.registries"):get()
	expect.no_equality(registries.collectors.get_by_name("pairs"), nil)
end

T["registry"]["pairs extractors are registered"] = function()
	local registries = require("smart-motion.core.registries"):get()
	expect.no_equality(registries.extractors.get_by_name("pairs_inside"), nil)
	expect.no_equality(registries.extractors.get_by_name("pairs_around"), nil)
	expect.no_equality(registries.extractors.get_by_name("pairs_surround"), nil)
end

T["registry"]["surround action is registered"] = function()
	local registries = require("smart-motion.core.registries"):get()
	expect.no_equality(registries.actions.get_by_name("surround"), nil)
	expect.no_equality(registries.actions.get_by_name("surround_add"), nil)
	expect.no_equality(registries.actions.get_by_name("surround_paste"), nil)
end

T["registry"]["PAIRS target type exists"] = function()
	local consts = require("smart-motion.consts")
	expect.equality(consts.TARGET_TYPES.PAIRS, "pairs")
end

-- =============================================================================
-- Preset registration
-- =============================================================================

T["surround presets"] = MiniTest.new_set({
	hooks = {
		pre_case = function()
			helpers.setup_plugin({
				presets = { surround = true },
			})
		end,
		post_case = helpers.cleanup,
	},
})

T["surround presets"]["registers ( and ) textobjects"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("(")
	expect.no_equality(to, nil)
	expect.equality(to.extractor, "pairs")
	expect.equality(to.collector, "pairs")

	-- ) should also be registered
	local to2 = motions.get_textobject(")")
	expect.no_equality(to2, nil)
	expect.equality(to2.extractor, "pairs")
end

T["surround presets"]["( textobject has inside/around/surround overrides"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("(")
	expect.equality(to.inside.pair_scope, "inside")
	expect.equality(to.around.pair_scope, "around")
	expect.equality(to.surround.pair_scope, "surround")
	expect.equality(to.surround.is_surround, true)
end

T["surround presets"]["registers ds/cs surround operators"] = function()
	local motions = require("smart-motion.motions")
	local ds = motions.get_by_key("ds")
	expect.no_equality(ds, nil)
	expect.equality(ds.infer, true)
	expect.equality(ds.action, "surround")
	expect.equality(ds.action_key, "d")

	local cs = motions.get_by_key("cs")
	expect.no_equality(cs, nil)
	expect.equality(cs.action_key, "c")
end

T["surround presets"]["registers bracket pair textobjects"] = function()
	local motions = require("smart-motion.motions")

	-- Check all bracket types as textobjects
	for _, pair in ipairs({ { "[", "]" }, { "{", "}" }, { "<", ">" } }) do
		expect.no_equality(motions.get_textobject(pair[1]), nil)
		expect.no_equality(motions.get_textobject(pair[2]), nil)
	end
end

T["surround presets"]["registers quote pair textobjects"] = function()
	local motions = require("smart-motion.motions")

	for _, q in ipairs({ '"', "'", "`" }) do
		expect.no_equality(motions.get_textobject(q), nil)
	end
end

T["surround presets"]["( textobject sets pair_chars in metadata"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("(")
	expect.no_equality(to.metadata.motion_state.pair_chars, nil)
	expect.equality(to.metadata.motion_state.pair_chars[1][1], "(")
	expect.equality(to.metadata.motion_state.pair_chars[1][2], ")")
end

T["surround presets"]["( surround overrides set is_surround"] = function()
	local motions = require("smart-motion.motions")
	local to = motions.get_textobject("(")
	expect.equality(to.surround.is_surround, true)
end

-- =============================================================================
-- Module loader action override
-- =============================================================================

T["module loader"] = MiniTest.new_set()

T["module loader"]["explicit motion.action overrides key-based lookup for infer"] = function()
	local registries = require("smart-motion.core.registries"):get()

	-- Simulate an infer motion with explicit action
	local module_loader = require("smart-motion.utils.module_loader")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = {
		motion = {
			infer = true,
			action_key = "d",
			action = "surround",
			collector = "pairs",
			extractor = "pairs_surround",
			filter = "filter_visible",
			visualizer = "hint_start",
		},
	}

	local modules = module_loader.get_modules(ctx, cfg, ms, { "action" })
	expect.no_equality(modules.action, nil)
	expect.equality(modules.action.name, "surround")
end

T["module loader"]["falls back to key-based lookup when no explicit action"] = function()
	local module_loader = require("smart-motion.utils.module_loader")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = {
		motion = {
			infer = true,
			action_key = "d",
			collector = "lines",
			filter = "filter_visible",
			visualizer = "hint_start",
		},
	}

	local modules = module_loader.get_modules(ctx, cfg, ms, { "action" })
	expect.no_equality(modules.action, nil)
	-- Should resolve to delete_jump (key "d")
	expect.equality(modules.action.name, "delete_jump")
end

T["module loader"]["ys operator keeps surround_add action when composable has no override"] = function()
	local module_loader = require("smart-motion.utils.module_loader")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	-- Simulates ysw: ys operator with action=surround_add,
	-- composable w did NOT override (no override_action flag)
	local ms = {
		motion = {
			infer = true,
			action_key = "ys",
			action = "surround_add",
			collector = "lines",
			extractor = "words",
			filter = "filter_visible",
			visualizer = "hint_start",
		},
	}

	local modules = module_loader.get_modules(ctx, cfg, ms, { "action" })
	expect.no_equality(modules.action, nil)
	expect.equality(modules.action.name, "surround_add")
end

T["module loader"]["dw resolves to delete_jump not jump_centered"] = function()
	local module_loader = require("smart-motion.utils.module_loader")
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	-- Simulates dw: d operator, composable w did NOT copy action
	-- (override_action is not set on w), so motion.action stays nil
	local ms = {
		motion = {
			infer = true,
			action_key = "d",
			collector = "lines",
			extractor = "words",
			filter = "filter_visible",
			visualizer = "hint_start",
			-- action is NOT set (w's action was not copied)
		},
	}

	local modules = module_loader.get_modules(ctx, cfg, ms, { "action" })
	expect.no_equality(modules.action, nil)
	expect.equality(modules.action.name, "delete_jump")
end

return T
