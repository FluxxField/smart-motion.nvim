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
					search = true,
					delete = true,
					yank = true,
					change = true,
					paste = true,
				},
			})
		end,
		post_case = helpers.cleanup,
	},
})

-- =============================================================================
-- Words preset motions
-- =============================================================================

T["words preset"] = MiniTest.new_set()

T["words preset"]["registers w motion"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("w")

	expect.no_equality(motion, nil)
	expect.equality(motion.collector, "lines")
	expect.equality(motion.extractor, "words")
	expect.equality(motion.filter, "filter_words_after_cursor")
	expect.equality(motion.visualizer, "hint_start")
end

T["words preset"]["registers b motion"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("b")

	expect.no_equality(motion, nil)
	expect.equality(motion.filter, "filter_words_before_cursor")
end

T["words preset"]["registers e motion with hint_end"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("e")

	expect.no_equality(motion, nil)
	expect.equality(motion.visualizer, "hint_end")
	expect.equality(motion.filter, "filter_words_after_cursor")
end

T["words preset"]["registers ge motion"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("ge")

	expect.no_equality(motion, nil)
	expect.equality(motion.visualizer, "hint_end")
	expect.equality(motion.filter, "filter_words_before_cursor")
end

T["words preset"]["w is composable"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("w")

	expect.equality(motion.composable, true)
end

-- =============================================================================
-- Lines preset motions
-- =============================================================================

T["lines preset"] = MiniTest.new_set()

T["lines preset"]["registers j motion"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("j")

	expect.no_equality(motion, nil)
	expect.equality(motion.extractor, "lines")
	expect.equality(motion.filter, "filter_lines_after_cursor")
end

T["lines preset"]["registers k motion"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("k")

	expect.no_equality(motion, nil)
	expect.equality(motion.filter, "filter_lines_before_cursor")
end

-- =============================================================================
-- Search preset motions
-- =============================================================================

T["search preset"] = MiniTest.new_set()

T["search preset"]["registers s motion with live_search"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("s")

	expect.no_equality(motion, nil)
	expect.equality(motion.extractor, "live_search")
end

T["search preset"]["registers S motion with fuzzy_search"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("S")

	expect.no_equality(motion, nil)
	expect.equality(motion.extractor, "fuzzy_search")
end

T["search preset"]["registers f motion"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("f")

	expect.no_equality(motion, nil)
	expect.equality(motion.extractor, "text_search_2_char")
end

T["search preset"]["registers F motion"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("F")

	expect.no_equality(motion, nil)
end

T["search preset"]["registers t motion"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("t")

	expect.no_equality(motion, nil)
end

T["search preset"]["registers T motion"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("T")

	expect.no_equality(motion, nil)
end

-- =============================================================================
-- Delete preset motions
-- =============================================================================

T["delete preset"] = MiniTest.new_set()

T["delete preset"]["registers d action"] = function()
	local registries = require("smart-motion.core.registries"):get()

	-- d should register as an operator/infer motion
	local motion = registries.motions.get_by_name("d")
	expect.no_equality(motion, nil)
end

-- =============================================================================
-- Yank preset motions
-- =============================================================================

T["yank preset"] = MiniTest.new_set()

T["yank preset"]["registers y action"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("y")

	expect.no_equality(motion, nil)
end

-- =============================================================================
-- Change preset motions
-- =============================================================================

T["change preset"] = MiniTest.new_set()

T["change preset"]["registers c action"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("c")

	expect.no_equality(motion, nil)
end

-- =============================================================================
-- Paste preset motions
-- =============================================================================

T["paste preset"] = MiniTest.new_set()

T["paste preset"]["registers p and P actions"] = function()
	local registries = require("smart-motion.core.registries"):get()

	expect.no_equality(registries.motions.get_by_name("p"), nil)
	expect.no_equality(registries.motions.get_by_name("P"), nil)
end

-- =============================================================================
-- Preset exclusion
-- =============================================================================

T["preset exclusion"] = MiniTest.new_set()

T["preset exclusion"]["disabling a preset skips registration"] = function()
	helpers.cleanup()
	helpers.setup_plugin({
		presets = {
			words = false, -- disabled
			lines = true,
		},
	})

	local registries = require("smart-motion.core.registries"):get()

	-- words motions should not be registered
	expect.equality(registries.motions.get_by_name("w"), nil)
	expect.equality(registries.motions.get_by_name("b"), nil)

	-- lines motions should still work
	expect.no_equality(registries.motions.get_by_name("j"), nil)
end

T["preset exclusion"]["excluding specific keys in preset"] = function()
	helpers.cleanup()
	helpers.setup_plugin({
		presets = {
			words = { ge = false }, -- exclude ge only
		},
	})

	local registries = require("smart-motion.core.registries"):get()

	-- w, b, e should be registered
	expect.no_equality(registries.motions.get_by_name("w"), nil)
	expect.no_equality(registries.motions.get_by_name("b"), nil)
	expect.no_equality(registries.motions.get_by_name("e"), nil)

	-- ge should be excluded
	expect.equality(registries.motions.get_by_name("ge"), nil)
end

-- =============================================================================
-- Motion metadata
-- =============================================================================

T["motion metadata"] = MiniTest.new_set()

T["motion metadata"]["w has label and description"] = function()
	local registries = require("smart-motion.core.registries"):get()
	local motion = registries.motions.get_by_name("w")

	expect.no_equality(motion, nil)
	expect.no_equality(motion.metadata, nil)
	expect.no_equality(motion.metadata.label, nil)
	expect.no_equality(motion.metadata.description, nil)
end

return T
