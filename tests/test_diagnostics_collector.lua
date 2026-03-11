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
-- Diagnostics collector
-- =============================================================================

T["diagnostics"] = MiniTest.new_set()

T["diagnostics"]["yields nothing when no diagnostics"] = function()
	local bufnr = helpers.create_buf({ "test line" })
	helpers.set_cursor(1, 0)
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	-- Ensure clean diagnostics
	vim.diagnostic.reset(nil, bufnr)

	local ms = {}
	local collector = require("smart-motion.collectors.diagnostics")
	local co = collector.run()
	local results = {}

	local ok, val = coroutine.resume(co, ctx, cfg, ms)
	if ok and val then
		table.insert(results, val)
	end

	expect.equality(#results, 0)
end

T["diagnostics"]["yields diagnostics from buffer"] = function()
	local bufnr = helpers.create_buf({ "local x = 1", "print(y)" })
	helpers.set_cursor(1, 0)
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	-- Set some diagnostics
	local ns = vim.api.nvim_create_namespace("test_diag")
	vim.diagnostic.set(ns, bufnr, {
		{
			lnum = 0,
			col = 6,
			end_lnum = 0,
			end_col = 7,
			message = "Unused variable 'x'",
			severity = vim.diagnostic.severity.WARN,
			source = "test",
		},
		{
			lnum = 1,
			col = 6,
			end_lnum = 1,
			end_col = 7,
			message = "Undefined variable 'y'",
			severity = vim.diagnostic.severity.ERROR,
			source = "test",
		},
	})

	local ms = {}
	local collector = require("smart-motion.collectors.diagnostics")
	local co = collector.run()
	local results = {}

	local ok, val = coroutine.resume(co, ctx, cfg, ms)
	if ok and val then
		table.insert(results, val)
		while coroutine.status(co) ~= "dead" do
			ok, val = coroutine.resume(co)
			if ok and val then
				table.insert(results, val)
			else
				break
			end
		end
	end

	expect.equality(#results, 2)
	expect.equality(results[1].type, "diagnostic")
	expect.no_equality(results[1].metadata.severity, nil)
	expect.no_equality(results[1].metadata.message, nil)

	-- Cleanup
	vim.diagnostic.reset(ns, bufnr)
end

T["diagnostics"]["filters by severity"] = function()
	local bufnr = helpers.create_buf({ "line one", "line two" })
	helpers.set_cursor(1, 0)
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ns = vim.api.nvim_create_namespace("test_diag_sev")
	vim.diagnostic.set(ns, bufnr, {
		{
			lnum = 0, col = 0, end_lnum = 0, end_col = 4,
			message = "Warning",
			severity = vim.diagnostic.severity.WARN,
		},
		{
			lnum = 1, col = 0, end_lnum = 1, end_col = 4,
			message = "Error",
			severity = vim.diagnostic.severity.ERROR,
		},
	})

	-- Filter to only errors
	local ms = { diagnostic_severity = vim.diagnostic.severity.ERROR }
	local collector = require("smart-motion.collectors.diagnostics")
	local co = collector.run()
	local results = {}

	local ok, val = coroutine.resume(co, ctx, cfg, ms)
	if ok and val then
		table.insert(results, val)
		while coroutine.status(co) ~= "dead" do
			ok, val = coroutine.resume(co)
			if ok and val then
				table.insert(results, val)
			else
				break
			end
		end
	end

	expect.equality(#results, 1)
	expect.equality(results[1].metadata.severity, vim.diagnostic.severity.ERROR)

	vim.diagnostic.reset(ns, bufnr)
end

T["diagnostics"]["filters by multiple severities"] = function()
	local bufnr = helpers.create_buf({ "a", "b", "c" })
	helpers.set_cursor(1, 0)
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated

	local ns = vim.api.nvim_create_namespace("test_diag_multi")
	vim.diagnostic.set(ns, bufnr, {
		{ lnum = 0, col = 0, message = "Warn", severity = vim.diagnostic.severity.WARN },
		{ lnum = 1, col = 0, message = "Error", severity = vim.diagnostic.severity.ERROR },
		{ lnum = 2, col = 0, message = "Info", severity = vim.diagnostic.severity.INFO },
	})

	-- Filter to warn + error
	local ms = {
		diagnostic_severity = {
			vim.diagnostic.severity.WARN,
			vim.diagnostic.severity.ERROR,
		},
	}

	local collector = require("smart-motion.collectors.diagnostics")
	local co = collector.run()
	local results = {}

	local ok, val = coroutine.resume(co, ctx, cfg, ms)
	if ok and val then
		table.insert(results, val)
		while coroutine.status(co) ~= "dead" do
			ok, val = coroutine.resume(co)
			if ok and val then
				table.insert(results, val)
			else
				break
			end
		end
	end

	expect.equality(#results, 2)
	vim.diagnostic.reset(ns, bufnr)
end

T["diagnostics"]["has metadata"] = function()
	local collector = require("smart-motion.collectors.diagnostics")
	expect.no_equality(collector.metadata, nil)
	expect.no_equality(collector.metadata.label, nil)
end

return T
