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
-- filetype_dispatch.apply
-- =============================================================================

T["apply"] = MiniTest.new_set()

T["apply"]["does nothing when motion has no metadata"] = function()
	local dispatch = require("smart-motion.core.engine.filetype_dispatch")

	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()

	local motion_state = { motion = {} }
	dispatch.apply(ctx, motion_state)

	-- Should not error, motion_state unchanged
	expect.equality(motion_state.motion.collector, nil)
end

T["apply"]["does nothing when no filetype_overrides"] = function()
	local dispatch = require("smart-motion.core.engine.filetype_dispatch")

	helpers.create_buf({ "test" })
	local ctx = helpers.build_ctx()

	local motion_state = {
		motion = {
			metadata = {
				motion_state = { some_field = true },
			},
		},
	}

	dispatch.apply(ctx, motion_state)
	expect.equality(motion_state.motion.metadata.motion_state.some_field, true)
end

T["apply"]["does nothing when filetype does not match"] = function()
	local dispatch = require("smart-motion.core.engine.filetype_dispatch")

	local bufnr = helpers.create_buf({ "test" })
	vim.bo[bufnr].filetype = "text"
	local ctx = helpers.build_ctx()

	local motion_state = {
		motion = {
			collector = "lines",
			metadata = {
				motion_state = {
					filetype_overrides = {
						lua = { collector = "patterns" },
					},
				},
			},
		},
	}

	dispatch.apply(ctx, motion_state)
	expect.equality(motion_state.motion.collector, "lines")
end

T["apply"]["swaps pipeline modules for matching filetype"] = function()
	local dispatch = require("smart-motion.core.engine.filetype_dispatch")

	local bufnr = helpers.create_buf({ "test" })
	vim.bo[bufnr].filetype = "lua"
	local ctx = helpers.build_ctx()

	local motion_state = {
		motion = {
			collector = "lines",
			extractor = "words",
			metadata = {
				motion_state = {
					filetype_overrides = {
						lua = { collector = "patterns", extractor = "pass_through" },
					},
				},
			},
		},
	}

	dispatch.apply(ctx, motion_state)
	expect.equality(motion_state.motion.collector, "patterns")
	expect.equality(motion_state.motion.extractor, "pass_through")
end

T["apply"]["merges motion_state overrides"] = function()
	local dispatch = require("smart-motion.core.engine.filetype_dispatch")

	local bufnr = helpers.create_buf({ "test" })
	vim.bo[bufnr].filetype = "python"
	local ctx = helpers.build_ctx()

	local motion_state = {
		motion = {
			collector = "lines",
			metadata = {
				motion_state = {
					existing_field = "keep",
					filetype_overrides = {
						python = {
							motion_state = { ignore_whitespace = false },
						},
					},
				},
			},
		},
	}

	dispatch.apply(ctx, motion_state)
	expect.equality(motion_state.motion.metadata.motion_state.ignore_whitespace, false)
	-- filetype_overrides should be removed after apply
	expect.equality(motion_state.motion.metadata.motion_state.filetype_overrides, nil)
end

T["apply"]["removes filetype_overrides after apply"] = function()
	local dispatch = require("smart-motion.core.engine.filetype_dispatch")

	local bufnr = helpers.create_buf({ "test" })
	vim.bo[bufnr].filetype = "javascript"
	local ctx = helpers.build_ctx()

	local motion_state = {
		motion = {
			collector = "lines",
			metadata = {
				motion_state = {
					filetype_overrides = {
						javascript = { collector = "patterns" },
					},
				},
			},
		},
	}

	dispatch.apply(ctx, motion_state)
	expect.equality(motion_state.motion.metadata.motion_state.filetype_overrides, nil)
end

T["apply"]["does not mutate original metadata (deep copy)"] = function()
	local dispatch = require("smart-motion.core.engine.filetype_dispatch")

	local bufnr = helpers.create_buf({ "test" })
	vim.bo[bufnr].filetype = "lua"
	local ctx = helpers.build_ctx()

	local original_metadata = {
		motion_state = {
			filetype_overrides = {
				lua = { collector = "patterns" },
			},
		},
	}

	local motion_state = {
		motion = {
			collector = "lines",
			metadata = original_metadata,
		},
	}

	dispatch.apply(ctx, motion_state)

	-- motion_state.motion.metadata should now be a deep copy, not the original
	-- The original should still have filetype_overrides
	expect.no_equality(original_metadata.motion_state.filetype_overrides, nil)
end

return T
