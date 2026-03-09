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
-- init_motion_state
-- =============================================================================

T["init"] = MiniTest.new_set()

T["init"]["initializes static state from config"] = function()
	local state = require("smart-motion.core.state")

	expect.equality(state.static.total_keys, 16) -- "fjdksleirughtynm"
	expect.equality(state.static.max_labels, 16 * 16) -- keys squared
	expect.equality(state.static.max_lines, 16 * 16)
end

-- =============================================================================
-- create_motion_state
-- =============================================================================

T["create"] = MiniTest.new_set()

T["create"]["returns fresh state with correct defaults"] = function()
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()

	expect.equality(ms.total_keys, 16)
	expect.equality(ms.max_labels, 256)
	expect.equality(ms.max_lines, 256)
	expect.equality(ms.ignore_whitespace, true)
	expect.equality(ms.hint_position, "start")
	expect.equality(ms.jump_target_count, 0)
	expect.equality(#ms.jump_targets, 0)
	expect.equality(ms.single_label_count, 0)
	expect.equality(ms.double_label_count, 0)
	expect.equality(ms.selection_mode, "first")
	expect.equality(ms.selected_jump_target, nil)
end

T["create"]["creates independent instances"] = function()
	local state = require("smart-motion.core.state")
	local ms1 = state.create_motion_state()
	local ms2 = state.create_motion_state()

	ms1.jump_target_count = 99
	expect.equality(ms2.jump_target_count, 0) -- should be unaffected
end

-- =============================================================================
-- finalize_motion_state
-- =============================================================================

T["finalize"] = MiniTest.new_set()

T["finalize"]["calculates single-only labels when targets fit in keys"] = function()
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()

	-- Add 5 targets (less than 16 keys)
	for i = 1, 5 do
		table.insert(ms.jump_targets, { text = "t" .. i })
	end

	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	state.finalize_motion_state(ctx, cfg, ms)

	expect.equality(ms.jump_target_count, 5)
	expect.equality(ms.single_label_count, 5)
	expect.equality(ms.double_label_count, 0)
	expect.equality(ms.sacrificed_keys_count, 0)
end

T["finalize"]["calculates double labels when targets exceed keys"] = function()
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()

	-- Add 30 targets (more than 16 keys)
	for i = 1, 30 do
		table.insert(ms.jump_targets, { text = "t" .. i })
	end

	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	state.finalize_motion_state(ctx, cfg, ms)

	expect.equality(ms.jump_target_count, 30)
	expect.equality(ms.double_label_count > 0, true)
	expect.equality(ms.sacrificed_keys_count > 0, true)
	expect.equality(ms.single_label_count + ms.sacrificed_keys_count, ms.total_keys)
end

T["finalize"]["exactly total_keys targets uses all singles"] = function()
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()

	for i = 1, 16 do
		table.insert(ms.jump_targets, { text = "t" .. i })
	end

	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	state.finalize_motion_state(ctx, cfg, ms)

	expect.equality(ms.single_label_count, 16)
	expect.equality(ms.double_label_count, 0)
end

-- =============================================================================
-- reset
-- =============================================================================

T["reset"] = MiniTest.new_set()

T["reset"]["clears all selection and target state"] = function()
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()

	-- Set some state
	ms.jump_target_count = 10
	ms.jump_targets = { { text = "a" }, { text = "b" } }
	ms.single_label_count = 5
	ms.double_label_count = 3
	ms.selected_jump_target = { text = "a" }
	ms.selection_mode = "second"

	state.reset(ms)

	expect.equality(ms.jump_target_count, 0)
	expect.equality(#ms.jump_targets, 0)
	expect.equality(ms.single_label_count, 0)
	expect.equality(ms.double_label_count, 0)
	expect.equality(ms.selected_jump_target, nil)
	expect.equality(ms.selection_mode, "first")
end

-- =============================================================================
-- merge_motion_state
-- =============================================================================

T["merge"] = MiniTest.new_set()

T["merge"]["merges motion metadata into motion_state"] = function()
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()

	local motion = {
		metadata = {
			motion_state = {
				direction = "after_cursor",
				word_pattern = "custom",
			},
		},
	}

	local result = state.merge_motion_state(ms, motion, {})

	expect.equality(result.direction, "after_cursor")
	expect.equality(result.word_pattern, "custom")
end

T["merge"]["merges module metadata on top of motion metadata"] = function()
	local state = require("smart-motion.core.state")
	local ms = state.create_motion_state()

	local motion = {
		metadata = {
			motion_state = {
				direction = "after_cursor",
			},
		},
	}

	local modules = {
		extractor = {
			metadata = {
				motion_state = {
					target_type = "words",
				},
			},
		},
	}

	local result = state.merge_motion_state(ms, motion, modules)

	expect.equality(result.direction, "after_cursor")
	expect.equality(result.target_type, "words")
end

return T
