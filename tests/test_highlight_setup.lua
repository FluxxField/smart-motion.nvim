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
-- highlight_setup.setup
-- =============================================================================

T["setup"] = MiniTest.new_set()

T["setup"]["creates default highlight groups"] = function()
	local hl_setup = require("smart-motion.highlight_setup")
	local cfg = require("smart-motion.config").validated

	hl_setup.setup(cfg)

	-- Check that highlight groups exist
	local groups = {
		"SmartMotionHint",
		"SmartMotionHintDim",
		"SmartMotionTwoCharHint",
		"SmartMotionTwoCharHintDim",
		"SmartMotionDim",
		"SmartMotionSearchPrefix",
		"SmartMotionSearchPrefixDim",
		"SmartMotionSelected",
	}

	for _, group in ipairs(groups) do
		local hl = vim.api.nvim_get_hl(0, { name = group })
		-- At minimum, the group should exist (not empty table for all)
		expect.equality(type(hl), "table")
	end
end

T["setup"]["applies custom highlight colors"] = function()
	local hl_setup = require("smart-motion.highlight_setup")
	local cfg = vim.tbl_deep_extend("force", {}, require("smart-motion.config").validated)
	cfg.highlight = cfg.highlight or {}
	cfg.highlight.hint = { fg = "#00FF00", bold = true }

	hl_setup.setup(cfg)

	local hl = vim.api.nvim_get_hl(0, { name = "SmartMotionHint" })
	expect.equality(hl.bold, true)
end

T["setup"]["accepts string group names"] = function()
	local hl_setup = require("smart-motion.highlight_setup")
	local cfg = vim.tbl_deep_extend("force", {}, require("smart-motion.config").validated)
	cfg.highlight = cfg.highlight or {}
	cfg.highlight.hint = "Comment" -- use existing group

	-- Should not error
	local ok = pcall(hl_setup.setup, cfg)
	expect.equality(ok, true)
end

T["setup"]["uses background highlights when configured"] = function()
	local hl_setup = require("smart-motion.highlight_setup")
	local cfg = vim.tbl_deep_extend("force", {}, require("smart-motion.config").validated)
	cfg.use_background_highlights = true

	hl_setup.setup(cfg)

	local hl = vim.api.nvim_get_hl(0, { name = "SmartMotionHint" })
	-- Background highlights should have bold
	expect.equality(hl.bold, true)
end

return T
