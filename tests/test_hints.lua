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
-- generate_hint_labels
-- =============================================================================

T["generate_hint_labels"] = MiniTest.new_set()

T["generate_hint_labels"]["generates correct number of single labels"] = function()
	local hints = require("smart-motion.visualizers.hints")
	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = {
		single_label_count = 5,
		double_label_count = 0,
	}

	local labels = hints.generate_hint_labels(ctx, cfg, ms)
	expect.equality(#labels, 5)
	-- Each should be a single character
	for _, label in ipairs(labels) do
		expect.equality(#label, 1)
	end
end

T["generate_hint_labels"]["generates single + double labels"] = function()
	local hints = require("smart-motion.visualizers.hints")
	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = {
		single_label_count = 10,
		double_label_count = 5,
	}

	local labels = hints.generate_hint_labels(ctx, cfg, ms)
	expect.equality(#labels, 15) -- 10 singles + 5 doubles

	-- First 10 should be single-char
	for i = 1, 10 do
		expect.equality(#labels[i], 1)
	end
	-- Last 5 should be double-char
	for i = 11, 15 do
		expect.equality(#labels[i], 2)
	end
end

T["generate_hint_labels"]["returns empty for invalid keys"] = function()
	local hints = require("smart-motion.visualizers.hints")
	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = vim.tbl_extend("force", {}, require("smart-motion.config").validated)
	cfg.keys = {} -- empty keys

	local ms = { single_label_count = 5, double_label_count = 0 }
	local labels = hints.generate_hint_labels(ctx, cfg, ms)
	expect.equality(#labels, 0)
end

T["generate_hint_labels"]["stores labels in motion_state"] = function()
	local hints = require("smart-motion.visualizers.hints")
	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ms = { single_label_count = 3, double_label_count = 0 }
	hints.generate_hint_labels(ctx, cfg, ms)

	expect.no_equality(ms.hint_labels, nil)
	expect.equality(#ms.hint_labels, 3)
end

-- =============================================================================
-- hints.run (full label assignment and rendering)
-- =============================================================================

T["hints run"] = MiniTest.new_set()

T["hints run"]["assigns labels to targets"] = function()
	local hints = require("smart-motion.visualizers.hints")
	local consts = require("smart-motion.consts")
	local bufnr = helpers.create_buf({ "hello world test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()

	-- Add some targets
	ms.jump_targets = {
		{
			start_pos = { row = 0, col = 0 },
			end_pos = { row = 0, col = 5 },
			text = "hello",
			metadata = { bufnr = bufnr },
		},
		{
			start_pos = { row = 0, col = 6 },
			end_pos = { row = 0, col = 11 },
			text = "world",
			metadata = { bufnr = bufnr },
		},
	}
	ms.jump_target_count = 2
	ms.single_label_count = 2
	ms.double_label_count = 0

	hints.run(ctx, cfg, ms)

	-- Should have assigned labels
	expect.no_equality(ms.assigned_hint_labels, nil)

	-- Count assigned labels (excluding prefix markers)
	local single_count = 0
	for _, entry in pairs(ms.assigned_hint_labels) do
		if entry.is_single_prefix then
			single_count = single_count + 1
		end
	end
	expect.equality(single_count, 2)
end

T["hints run"]["handles empty targets gracefully"] = function()
	local hints = require("smart-motion.visualizers.hints")
	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()
	ms.jump_targets = {}

	-- Should not error
	local ok = pcall(hints.run, ctx, cfg, ms)
	expect.equality(ok, true)
end

T["hints run"]["uses label_keys when specified"] = function()
	local hints = require("smart-motion.visualizers.hints")
	local bufnr = helpers.create_buf({ "a b c" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()

	ms.jump_targets = {}
	for i = 1, 3 do
		table.insert(ms.jump_targets, {
			start_pos = { row = 0, col = (i - 1) * 2 },
			end_pos = { row = 0, col = (i - 1) * 2 + 1 },
			text = string.char(96 + i),
			metadata = { bufnr = bufnr },
		})
	end
	ms.jump_target_count = 3
	ms.single_label_count = 3
	ms.double_label_count = 0
	ms.label_keys = "xyz" -- only use x, y, z as labels

	hints.run(ctx, cfg, ms)

	-- Labels should only contain x, y, z - not the default key set
	expect.equality(ms.hint_labels[1], "x")
	expect.equality(ms.hint_labels[2], "y")
	expect.equality(ms.hint_labels[3], "z")
end

T["hints run"]["excludes motion key when allow_quick_action is set"] = function()
	local hints = require("smart-motion.visualizers.hints")
	local bufnr = helpers.create_buf({ "word1 word2 word3" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()

	ms.jump_targets = {}
	for i = 1, 3 do
		table.insert(ms.jump_targets, {
			start_pos = { row = 0, col = (i - 1) * 6 },
			end_pos = { row = 0, col = (i - 1) * 6 + 5 },
			text = "word" .. i,
			metadata = { bufnr = bufnr },
		})
	end
	ms.jump_target_count = 3
	ms.single_label_count = 3
	ms.double_label_count = 0
	ms.allow_quick_action = true
	ms.motion_key = "f" -- 'f' is in the default key set

	hints.run(ctx, cfg, ms)

	-- 'f' should not appear as a label
	expect.equality(ms.assigned_hint_labels["f"], nil)
end

-- =============================================================================
-- Visualizer registry
-- =============================================================================

T["visualizer registry"] = MiniTest.new_set()

T["visualizer registry"]["all visualizers are registered"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local visualizers = registries.visualizers

	local expected = { "hint_start", "hint_end", "pass_through" }
	for _, name in ipairs(expected) do
		expect.no_equality(visualizers.get_by_name(name), nil)
	end
end

return T
