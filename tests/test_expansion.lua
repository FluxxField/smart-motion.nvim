local helpers = require("tests.helpers")
local MiniTest = require("mini_test")
local T = MiniTest.new_set()

-- Setup
T["expansion"] = MiniTest.new_set({
	hooks = {
		pre_case = function()
			helpers.setup_plugin({
				presets = { words = true, delete = true, yank = true, change = true },
			})
		end,
	},
})

-- =============================================================================
-- Module loading
-- =============================================================================

T["expansion"]["module loads"] = function()
	local expansion = require("smart-motion.core.expansion")
	MiniTest.expect.equality(type(expansion.run), "function")
end

-- =============================================================================
-- Config
-- =============================================================================

T["expansion"]["config has expansion_keys defaults"] = function()
	local config = require("smart-motion.config")
	local cfg = config.validated
	MiniTest.expect.equality(type(cfg.expansion_keys), "table")
	MiniTest.expect.equality(cfg.expansion_keys["+"], "expand_forward")
	MiniTest.expect.equality(cfg.expansion_keys["-"], "expand_backward")
	MiniTest.expect.equality(cfg.expansion_keys["<BS>"], "shrink")
end

T["expansion"]["config validates expansion_keys"] = function()
	helpers.setup_plugin({
		expansion_keys = {
			["<M-n>"] = "expand_forward",
			["<M-p>"] = "expand_backward",
		},
	})
	local config = require("smart-motion.config")
	MiniTest.expect.equality(config.validated.expansion_keys["<M-n>"], "expand_forward")
	MiniTest.expect.equality(config.validated.expansion_keys["<M-p>"], "expand_backward")
end

T["expansion"]["config expansion_keys = false disables"] = function()
	helpers.setup_plugin({ expansion_keys = false })
	local config = require("smart-motion.config")
	MiniTest.expect.equality(config.validated.expansion_keys, false)
end

-- =============================================================================
-- Expansion enabled on operators
-- =============================================================================

T["expansion"]["d/y/c do NOT have expansion_enabled"] = function()
	local motions = require("smart-motion.motions")
	MiniTest.expect.equality(motions.get_by_key("d").metadata.motion_state.expansion_enabled, nil)
	MiniTest.expect.equality(motions.get_by_key("y").metadata.motion_state.expansion_enabled, nil)
	MiniTest.expect.equality(motions.get_by_key("c").metadata.motion_state.expansion_enabled, nil)
end

T["expansion"]["surround presets have expansion_enabled"] = function()
	helpers.setup_plugin({
		presets = { words = true, surround = true },
	})
	local motions = require("smart-motion.motions")
	local ys = motions.get_by_key("ys")
	MiniTest.expect.equality(ys.metadata.motion_state.expansion_enabled, true)
	local gza = motions.get_by_key("gza")
	MiniTest.expect.equality(gza.metadata.motion_state.expansion_enabled, true)
end

-- =============================================================================
-- Expansion logic (unit tests on internals)
-- =============================================================================

T["expansion"]["skips when expansion_enabled is false"] = function()
	local expansion = require("smart-motion.core.expansion")
	local motion_state = {
		expansion_enabled = false,
		selected_jump_target = { start_pos = { row = 0, col = 0 }, end_pos = { row = 0, col = 3 } },
	}
	-- Should return immediately without blocking
	expansion.run({}, {}, motion_state)
	-- Target should be unchanged
	MiniTest.expect.equality(motion_state.selected_jump_target.start_pos.col, 0)
end

T["expansion"]["skips when no selected target"] = function()
	local expansion = require("smart-motion.core.expansion")
	local motion_state = {
		expansion_enabled = true,
		selected_jump_target = nil,
	}
	expansion.run({}, {}, motion_state)
	MiniTest.expect.equality(motion_state.selected_jump_target, nil)
end

T["expansion"]["skips when fewer than 2 targets"] = function()
	local expansion = require("smart-motion.core.expansion")
	local target = { start_pos = { row = 0, col = 0 }, end_pos = { row = 0, col = 3 } }
	local motion_state = {
		expansion_enabled = true,
		selected_jump_target = target,
		jump_targets = { target },
	}
	expansion.run({}, {}, motion_state)
	MiniTest.expect.equality(motion_state.selected_jump_target, target)
end

T["expansion"]["skips when no expansion_keys in config"] = function()
	local expansion = require("smart-motion.core.expansion")
	local target = {
		start_pos = { row = 0, col = 0 },
		end_pos = { row = 0, col = 3 },
		metadata = {},
	}
	local motion_state = {
		expansion_enabled = true,
		selected_jump_target = target,
		jump_targets = { target, { start_pos = { row = 0, col = 4 }, end_pos = { row = 0, col = 7 } } },
	}
	expansion.run({}, { expansion_keys = nil }, motion_state)
	MiniTest.expect.equality(motion_state.selected_jump_target, target)
end

-- =============================================================================
-- resolve_range with is_expanded_range
-- =============================================================================

T["expansion"]["resolve_range uses full range when is_expanded_range"] = function()
	local utils = require("smart-motion.actions.utils")
	local ctx = { cursor_line = 0, cursor_col = 0 }
	local motion_state = {
		is_expanded_range = true,
		exclude_target = true, -- would normally change behavior
		selected_jump_target = {
			start_pos = { row = 2, col = 5 },
			end_pos = { row = 2, col = 20 },
		},
	}
	local sr, sc, er, ec = utils.resolve_range(ctx, motion_state)
	MiniTest.expect.equality(sr, 2)
	MiniTest.expect.equality(sc, 5)
	MiniTest.expect.equality(er, 2)
	MiniTest.expect.equality(ec, 20)
end

T["expansion"]["resolve_range normal behavior without is_expanded_range"] = function()
	local utils = require("smart-motion.actions.utils")
	local ctx = { cursor_line = 0, cursor_col = 0 }
	local motion_state = {
		selected_jump_target = {
			start_pos = { row = 2, col = 5 },
			end_pos = { row = 2, col = 20 },
		},
	}
	local sr, sc, er, ec = utils.resolve_range(ctx, motion_state)
	MiniTest.expect.equality(sr, 2)
	MiniTest.expect.equality(sc, 5)
	MiniTest.expect.equality(er, 2)
	MiniTest.expect.equality(ec, 20)
end

-- =============================================================================
-- Integration into exit flow
-- =============================================================================

T["expansion"]["exit.lua loads expansion module"] = function()
	local exit = require("smart-motion.core.engine.exit")
	MiniTest.expect.equality(type(exit.run), "function")
	-- Verify expansion module is loadable
	local expansion = require("smart-motion.core.expansion")
	MiniTest.expect.equality(type(expansion.run), "function")
end

return T
