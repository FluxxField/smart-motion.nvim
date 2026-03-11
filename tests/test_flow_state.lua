local MiniTest = require("mini_test")
local expect = MiniTest.expect
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
	hooks = {
		pre_case = function()
			helpers.setup_plugin()
		end,
		post_case = function()
			helpers.cleanup()
		end,
	},
})

-- =============================================================================
-- should_cancel_on_keypress
-- =============================================================================

T["cancel keys"] = MiniTest.new_set()

T["cancel keys"]["ESC cancels"] = function()
	local flow = require("smart-motion.core.flow_state")
	expect.equality(flow.should_cancel_on_keypress("\27"), true)
end

T["cancel keys"]["Ctrl-C cancels"] = function()
	local flow = require("smart-motion.core.flow_state")
	expect.equality(flow.should_cancel_on_keypress("\3"), true)
end

T["cancel keys"]["colon cancels"] = function()
	local flow = require("smart-motion.core.flow_state")
	expect.equality(flow.should_cancel_on_keypress(":"), true)
end

T["cancel keys"]["slash cancels"] = function()
	local flow = require("smart-motion.core.flow_state")
	expect.equality(flow.should_cancel_on_keypress("/"), true)
end

T["cancel keys"]["question mark cancels"] = function()
	local flow = require("smart-motion.core.flow_state")
	expect.equality(flow.should_cancel_on_keypress("?"), true)
end

T["cancel keys"]["normal char does not cancel"] = function()
	local flow = require("smart-motion.core.flow_state")
	expect.equality(flow.should_cancel_on_keypress("f"), false)
end

T["cancel keys"]["space does not cancel"] = function()
	local flow = require("smart-motion.core.flow_state")
	expect.equality(flow.should_cancel_on_keypress(" "), false)
end

-- =============================================================================
-- Flow lifecycle
-- =============================================================================

T["lifecycle"] = MiniTest.new_set()

T["lifecycle"]["starts inactive"] = function()
	local flow = require("smart-motion.core.flow_state")
	flow.reset()

	expect.equality(flow.is_active, false)
	expect.equality(flow.is_paused, false)
	expect.equality(flow.last_motion_timestamp, nil)
end

T["lifecycle"]["start_flow activates and sets timestamp"] = function()
	local flow = require("smart-motion.core.flow_state")
	flow.reset()
	flow.start_flow()

	expect.equality(flow.is_active, true)
	expect.equality(flow.is_paused, false)
	expect.no_equality(flow.last_motion_timestamp, nil)
end

T["lifecycle"]["exit_flow deactivates"] = function()
	local flow = require("smart-motion.core.flow_state")
	flow.reset()
	flow.start_flow()
	flow.exit_flow()

	expect.equality(flow.is_active, false)
	expect.equality(flow.is_paused, false)
end

T["lifecycle"]["pause_flow pauses active flow"] = function()
	local flow = require("smart-motion.core.flow_state")
	flow.reset()
	flow.start_flow()
	flow.pause_flow()

	expect.equality(flow.is_paused, true)
	expect.no_equality(flow.pause_started_at, nil)
end

T["lifecycle"]["pause_flow does nothing when not active"] = function()
	local flow = require("smart-motion.core.flow_state")
	flow.reset()
	flow.pause_flow()

	expect.equality(flow.is_paused, false)
	expect.equality(flow.pause_started_at, nil)
end

T["lifecycle"]["is_flow_active returns true when paused"] = function()
	local flow = require("smart-motion.core.flow_state")
	flow.reset()
	flow.start_flow()
	flow.pause_flow()

	expect.equality(flow.is_flow_active(), true)
end

T["lifecycle"]["is_flow_active returns false when reset"] = function()
	local flow = require("smart-motion.core.flow_state")
	flow.reset()

	expect.equality(flow.is_flow_active(), false)
end

T["lifecycle"]["reset clears everything"] = function()
	local flow = require("smart-motion.core.flow_state")
	flow.start_flow()
	flow.pause_flow()
	flow.reset()

	expect.equality(flow.is_active, false)
	expect.equality(flow.is_paused, false)
	expect.equality(flow.pause_started_at, nil)
	expect.equality(flow.last_motion_timestamp, nil)
end

-- =============================================================================
-- Expiration
-- =============================================================================

T["expiration"] = MiniTest.new_set()

T["expiration"]["expired when no timestamp"] = function()
	local flow = require("smart-motion.core.flow_state")
	flow.reset()

	expect.equality(flow.is_expired(), true)
end

T["expiration"]["not expired immediately after start with nonzero timeout"] = function()
	helpers.cleanup()
	helpers.setup_plugin({ flow_state_timeout_ms = 5000 })

	local flow = require("smart-motion.core.flow_state")
	flow.reset()
	flow.start_flow()

	expect.equality(flow.is_expired(), false)
end

T["expiration"]["expires immediately with zero timeout"] = function()
	-- Default test config has flow_state_timeout_ms = 0
	local flow = require("smart-motion.core.flow_state")
	flow.reset()
	flow.start_flow()

	expect.equality(flow.is_expired(), true)
end

T["expiration"]["not expired when paused"] = function()
	local flow = require("smart-motion.core.flow_state")
	flow.reset()
	flow.start_flow()
	flow.pause_flow()

	-- Paused flow never expires
	expect.equality(flow.is_expired(), false)
end

T["expiration"]["refresh does not work when paused"] = function()
	local flow = require("smart-motion.core.flow_state")
	flow.reset()
	flow.start_flow()
	local ts = flow.last_motion_timestamp
	flow.pause_flow()
	flow.refresh_timestamp()

	-- Timestamp should NOT have changed
	expect.equality(flow.last_motion_timestamp, ts)
end

-- =============================================================================
-- evaluate_flow_at_motion_start
-- =============================================================================

T["evaluate at motion start"] = MiniTest.new_set()

T["evaluate at motion start"]["returns false on first motion"] = function()
	local flow = require("smart-motion.core.flow_state")
	flow.reset()

	local result = flow.evaluate_flow_at_motion_start()
	expect.equality(result, false)
	-- But timestamp should be set now
	expect.no_equality(flow.last_motion_timestamp, nil)
end

T["evaluate at motion start"]["returns true when within threshold"] = function()
	helpers.cleanup()
	helpers.setup_plugin({ flow_state_timeout_ms = 5000 })

	local flow = require("smart-motion.core.flow_state")
	flow.reset()

	-- Set timestamp to now (simulating a recent motion)
	flow.last_motion_timestamp = flow.get_timestamp()

	local result = flow.evaluate_flow_at_motion_start()
	expect.equality(result, true)
end

return T
