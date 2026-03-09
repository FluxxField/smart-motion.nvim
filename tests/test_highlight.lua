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
-- dim_background
-- =============================================================================

T["dim_background"] = MiniTest.new_set()

T["dim_background"]["skips when cfg.dim_background is false"] = function()
	local hl = require("smart-motion.core.highlight")
	local consts = require("smart-motion.consts")
	local bufnr = helpers.create_buf({ "hello", "world" })
	local ctx = helpers.build_ctx()

	local cfg = require("smart-motion.config").validated
	-- dim_background is already false in test config

	local ms = { affected_buffers = {} }

	hl.dim_background(ctx, cfg, ms)

	-- No extmarks should have been set
	local marks = vim.api.nvim_buf_get_extmarks(bufnr, consts.ns_id, 0, -1, {})
	expect.equality(#marks, 0)
end

T["dim_background"]["skips when motion_state.dim_background is false"] = function()
	-- Setup with dim_background enabled in config
	helpers.cleanup()
	helpers.setup_plugin({ dim_background = true })

	local hl = require("smart-motion.core.highlight")
	local consts = require("smart-motion.consts")
	local bufnr = helpers.create_buf({ "hello", "world" })
	local ctx = helpers.build_ctx()

	local cfg = require("smart-motion.config").validated
	local ms = { dim_background = false, affected_buffers = {} }

	hl.dim_background(ctx, cfg, ms)

	-- Should skip due to motion_state override
	local marks = vim.api.nvim_buf_get_extmarks(bufnr, consts.ns_id, 0, -1, {})
	expect.equality(#marks, 0)
end

T["dim_background"]["applies highlights when enabled"] = function()
	helpers.cleanup()
	helpers.setup_plugin({ dim_background = true })

	local hl = require("smart-motion.core.highlight")
	local consts = require("smart-motion.consts")
	local bufnr = helpers.create_buf({ "hello", "world" })
	local ctx = helpers.build_ctx()

	local cfg = require("smart-motion.config").validated
	local ms = { affected_buffers = {} }

	hl.dim_background(ctx, cfg, ms)

	-- Should have applied highlights
	local marks = vim.api.nvim_buf_get_extmarks(bufnr, consts.ns_id, 0, -1, { details = true })
	expect.equality(#marks > 0, true)
	-- Buffer should be tracked
	expect.equality(ms.affected_buffers[bufnr], true)
end

-- =============================================================================
-- clear
-- =============================================================================

T["clear"] = MiniTest.new_set()

T["clear"]["clears extmarks from buffer"] = function()
	local hl = require("smart-motion.core.highlight")
	local consts = require("smart-motion.consts")
	local bufnr = helpers.create_buf({ "hello world" })
	local ctx = helpers.build_ctx()

	-- Place an extmark manually
	vim.api.nvim_buf_set_extmark(bufnr, consts.ns_id, 0, 0, {
		virt_text = { { "x", "Normal" } },
		virt_text_pos = "overlay",
	})

	-- Verify extmark exists
	local marks = vim.api.nvim_buf_get_extmarks(bufnr, consts.ns_id, 0, -1, {})
	expect.equality(#marks > 0, true)

	-- Clear
	hl.clear(ctx, {}, { affected_buffers = { [bufnr] = true } })

	-- Verify cleared
	marks = vim.api.nvim_buf_get_extmarks(bufnr, consts.ns_id, 0, -1, {})
	expect.equality(#marks, 0)
end

T["clear"]["clears from multiple affected buffers"] = function()
	local hl = require("smart-motion.core.highlight")
	local consts = require("smart-motion.consts")

	local buf1 = helpers.create_buf({ "buf one" })
	local buf2 = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf2, 0, -1, false, { "buf two" })

	-- Place extmarks in both
	vim.api.nvim_buf_set_extmark(buf1, consts.ns_id, 0, 0, {
		virt_text = { { "x", "Normal" } },
		virt_text_pos = "overlay",
	})
	vim.api.nvim_buf_set_extmark(buf2, consts.ns_id, 0, 0, {
		virt_text = { { "y", "Normal" } },
		virt_text_pos = "overlay",
	})

	local ctx = helpers.build_ctx()
	hl.clear(ctx, {}, { affected_buffers = { [buf1] = true, [buf2] = true } })

	local marks1 = vim.api.nvim_buf_get_extmarks(buf1, consts.ns_id, 0, -1, {})
	local marks2 = vim.api.nvim_buf_get_extmarks(buf2, consts.ns_id, 0, -1, {})
	expect.equality(#marks1, 0)
	expect.equality(#marks2, 0)
end

-- =============================================================================
-- apply_single_hint_label
-- =============================================================================

T["single hint"] = MiniTest.new_set()

T["single hint"]["places extmark at target position"] = function()
	local hl = require("smart-motion.core.highlight")
	local consts = require("smart-motion.consts")
	local bufnr = helpers.create_buf({ "hello world" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local target = {
		start_pos = { row = 0, col = 0 },
		end_pos = { row = 0, col = 5 },
		text = "hello",
		metadata = {},
	}

	local ms = { hint_position = "start", affected_buffers = {} }

	hl.apply_single_hint_label(ctx, cfg, ms, target, "f")

	local marks = vim.api.nvim_buf_get_extmarks(bufnr, consts.ns_id, 0, -1, { details = true })
	expect.equality(#marks, 1)
	-- Mark should be at row 0
	expect.equality(marks[1][2], 0)
end

T["single hint"]["places at end_pos when hint_position is end"] = function()
	local hl = require("smart-motion.core.highlight")
	local consts = require("smart-motion.consts")
	local bufnr = helpers.create_buf({ "hello world" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local target = {
		start_pos = { row = 0, col = 0 },
		end_pos = { row = 0, col = 5 },
		text = "hello",
		metadata = {},
	}

	local ms = { hint_position = "end", affected_buffers = {} }

	hl.apply_single_hint_label(ctx, cfg, ms, target, "f")

	local marks = vim.api.nvim_buf_get_extmarks(bufnr, consts.ns_id, 0, -1, { details = true })
	expect.equality(#marks, 1)
	-- Should be at end_pos.col - 1 = 4
	expect.equality(marks[1][3], 4)
end

T["single hint"]["tracks affected buffer"] = function()
	local hl = require("smart-motion.core.highlight")
	local bufnr = helpers.create_buf({ "hello" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local target = {
		start_pos = { row = 0, col = 0 },
		end_pos = { row = 0, col = 5 },
		text = "hello",
		metadata = {},
	}

	local ms = { hint_position = "start", affected_buffers = {} }

	hl.apply_single_hint_label(ctx, cfg, ms, target, "f")

	expect.equality(ms.affected_buffers[bufnr], true)
end

-- =============================================================================
-- apply_double_hint_label
-- =============================================================================

T["double hint"] = MiniTest.new_set()

T["double hint"]["places extmark with two characters"] = function()
	local hl = require("smart-motion.core.highlight")
	local consts = require("smart-motion.consts")
	local bufnr = helpers.create_buf({ "hello world" })
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local target = {
		start_pos = { row = 0, col = 0 },
		end_pos = { row = 0, col = 5 },
		text = "hello",
		metadata = {},
	}

	local ms = { hint_position = "start", affected_buffers = {} }

	hl.apply_double_hint_label(ctx, cfg, ms, target, "fj")

	local marks = vim.api.nvim_buf_get_extmarks(bufnr, consts.ns_id, 0, -1, { details = true })
	expect.equality(#marks, 1)

	-- virt_text should have 2 entries (first char + second char)
	local virt_text = marks[1][4].virt_text
	expect.equality(#virt_text, 2)
	expect.equality(virt_text[1][1], "f")
	expect.equality(virt_text[2][1], "j")
end

return T
