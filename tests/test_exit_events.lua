local MiniTest = require("mini_test")
local expect = MiniTest.expect
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
	hooks = {
		post_case = helpers.cleanup,
	},
})

local function get_exit()
	package.loaded["smart-motion.core.events.exit"] = nil
	return require("smart-motion.core.events.exit")
end

-- =============================================================================
-- throw
-- =============================================================================

T["throw"] = MiniTest.new_set()

T["throw"]["raises structured error with exit_type"] = function()
	local exit = get_exit()
	local ok, err = pcall(exit.throw, "early_exit")

	expect.equality(ok, false)
	expect.equality(type(err), "table")
	expect.equality(err.exit_type, "early_exit")
end

T["throw"]["works with different exit types"] = function()
	local exit = get_exit()

	for _, exit_type in ipairs({ "early_exit", "auto_select", "continue_to_selection", "pipeline_exit" }) do
		local ok, err = pcall(exit.throw, exit_type)
		expect.equality(ok, false)
		expect.equality(err.exit_type, exit_type)
	end
end

-- =============================================================================
-- throw_if
-- =============================================================================

T["throw_if"] = MiniTest.new_set()

T["throw_if"]["raises when condition is truthy"] = function()
	local exit = get_exit()
	local ok, err = pcall(exit.throw_if, true, "early_exit")

	expect.equality(ok, false)
	expect.equality(err.exit_type, "early_exit")
end

T["throw_if"]["does nothing when condition is false"] = function()
	local exit = get_exit()
	-- Should not raise
	exit.throw_if(false, "early_exit")
end

T["throw_if"]["does nothing when condition is nil"] = function()
	local exit = get_exit()
	exit.throw_if(nil, "early_exit")
end

-- =============================================================================
-- wrap
-- =============================================================================

T["wrap"] = MiniTest.new_set()

T["wrap"]["catches exit events and returns exit_type"] = function()
	local exit = get_exit()
	local result = exit.wrap(function()
		exit.throw("auto_select")
	end)

	expect.equality(result, "auto_select")
end

T["wrap"]["returns nil on normal completion"] = function()
	local exit = get_exit()
	local result = exit.wrap(function()
		-- do nothing
	end)

	expect.equality(result, nil)
end

T["wrap"]["re-raises non-exit errors"] = function()
	local exit = get_exit()
	expect.error(function()
		exit.wrap(function()
			error("real error")
		end)
	end, "real error")
end

-- =============================================================================
-- protect
-- =============================================================================

T["protect"] = MiniTest.new_set()

T["protect"]["re-throws exit events"] = function()
	local exit = get_exit()
	local exit_err = { ["__smart_motion_exit__"] = true, exit_type = "early_exit" }

	local ok, err = pcall(exit.protect, false, exit_err)
	expect.equality(ok, false)
	expect.equality(type(err), "table")
	expect.equality(err.exit_type, "early_exit")
end

T["protect"]["re-raises real errors"] = function()
	local exit = get_exit()

	expect.error(function()
		exit.protect(false, "some error")
	end, "some error")
end

T["protect"]["returns result on success"] = function()
	local exit = get_exit()
	local result = exit.protect(true, "value")
	expect.equality(result, "value")
end

-- =============================================================================
-- safe
-- =============================================================================

T["safe"] = MiniTest.new_set()

T["safe"]["re-throws exit events"] = function()
	local exit = get_exit()
	local exit_err = { ["__smart_motion_exit__"] = true, exit_type = "early_exit" }

	local ok, err = pcall(exit.safe, false, exit_err)
	expect.equality(ok, false)
	expect.equality(type(err), "table")
end

T["safe"]["returns ok=false for non-exit errors without throwing"] = function()
	local exit = get_exit()
	local ok, result = exit.safe(false, "some error")
	expect.equality(ok, false)
	expect.equality(result, "some error")
end

T["safe"]["passes through successful results"] = function()
	local exit = get_exit()
	local ok, result = exit.safe(true, "value")
	expect.equality(ok, true)
	expect.equality(result, "value")
end

return T
