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
-- Marks collector
-- =============================================================================

T["marks"] = MiniTest.new_set()

T["marks"]["yields nothing when no marks set"] = function()
	local bufnr = helpers.create_buf({ "line one", "line two", "line three" })
	helpers.set_cursor(1, 0)

	-- Delete all marks in buffer
	vim.cmd("delmarks!")

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local ms = {}

	local collector = require("smart-motion.collectors.marks")
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

	expect.equality(#results, 0)
end

T["marks"]["yields local marks"] = function()
	local bufnr = helpers.create_buf({ "line one", "line two", "line three" })
	helpers.set_cursor(1, 0)

	-- Set some marks
	helpers.set_cursor(1, 0)
	vim.cmd("mark a")
	helpers.set_cursor(3, 0)
	vim.cmd("mark b")

	helpers.set_cursor(1, 0) -- reset cursor
	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local ms = {}

	local collector = require("smart-motion.collectors.marks")
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

	expect.equality(#results >= 2, true)
	expect.equality(results[1].type, "mark")
	expect.no_equality(results[1].metadata.mark_name, nil)

	-- Cleanup
	vim.cmd("delmarks!")
end

T["marks"]["filters local only when marks_local_only set"] = function()
	local bufnr = helpers.create_buf({ "line one", "line two" })
	helpers.set_cursor(1, 0)

	vim.cmd("mark a")

	local ctx = helpers.build_ctx()
	local cfg = require("smart-motion.config").validated
	local ms = { marks_local_only = true }

	local collector = require("smart-motion.collectors.marks")
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

	-- All results should be local (not global)
	for _, r in ipairs(results) do
		expect.equality(r.metadata.is_global, false)
	end

	vim.cmd("delmarks!")
end

T["marks"]["has metadata"] = function()
	local collector = require("smart-motion.collectors.marks")
	expect.no_equality(collector.metadata, nil)
	expect.no_equality(collector.metadata.label, nil)
	expect.no_equality(collector.metadata.description, nil)
end

return T
