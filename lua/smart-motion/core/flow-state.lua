local config = require("smart-motion.config")
local log = require("smart-motion.core.log")

local FLOW_STATE_TIMEOUT_MS = require("smart-motion.consts").FLOW_STATE_TIMEOUT_MS

--- @class FlowState
--- @field is_active boolean
--- @field is_paused boolean
--- @field pause_started_at number?  -- in milliseconds
--- @field last_motion_timestamp number?  -- in milliseconds

--- @type FlowState & {
---   evaluate_flow_at_motion_start: fun(): boolean,
---   evaluate_flow_at_selection: fun(): boolean,
---   should_cancel_on_keypress: fun(key: string): boolean,
---   is_flow_active: fun(): boolean,
---   is_expired: fun(): boolean,
---   refresh_timestamp: fun(),
---   start_flow: fun(),
---   pause_flow: fun(),
---   resume_flow: fun(),
---   exit_flow: fun(),
---   reset: fun(),
---   get_timestamp: fun(): number,
--- }
local M = {}

M.is_active = false
M.is_paused = false
M.pause_started_at = nil
M.last_motion_timestamp = nil

--
-- Helpers
--

function M.should_cancel_on_keypress(key)
	local cancel_keys = {
		"\27", -- ESC
		"\3", -- <C-c>
		"\26", -- <C-z>,
		":",
		"/",
		"?",
	}

	return vim.tbl_contains(cancel_keys, key)
end

function M.get_timestamp()
	return vim.loop.hrtime() / 1e6 -- milliseconds
end

function M.start_flow()
	log.debug("Starting flow")

	M.is_active = true
	M.is_paused = false
	M.pause_started_at = nil
	M.last_motion_timestamp = M.get_timestamp()
end

function M.exit_flow()
	log.debug("Exiting flow")

	M.is_active = false
	M.is_paused = false
	M.pause_started_at = nil
end

function M.pause_flow()
	if not M.is_active or M.is_paused then
		return
	end

	M.is_paused = true
	M.pause_started_at = M.get_timestamp()
end

function M.resume_flow()
	if not M.is_active or not M.is_paused or not M.last_motion_timestamp then
		log.debug("resume_flow: Nothing to resume - skipping")
		return
	end

	local now = M.get_timestamp()
	local paused_duration = now - M.pause_started_at

	M.last_motion_timestamp = M.last_motion_timestamp + paused_duration
	M.is_paused = false
	M.is_pause_started_at = nil

	log.debug("Resumed flow - adjusted timestamp by " .. paused_duration .. "ms")
end

function M.is_flow_active()
	if M.is_paused then
		return true -- We are technically "in flow" even if paused
	end

	return M.is_active
end

function M.refresh_timestamp()
	if M.is_paused then
		log.debug("refresh_flow: Flow is paused - refresh skipped")
		return
	end

	M.last_motion_timestamp = M.get_timestamp()
end

function M.is_expired()
	if M.is_paused then
		log.debug("Flow is paused - it cannot expire")
		return false
	end

	local now = M.get_timestamp()
	local elapsed = now - M.last_motion_timestamp
	local flow_state_timeout_ms = config.validated.flow_state_timeout_ms or FLOW_STATE_TIMEOUT_MS

	if elapsed > flow_state_timeout_ms then
		log.debug(string.format("Flow expired after %dms (timeout: %dms)", elapsed, flow_state_timeout_ms))
		return true
	end

	return false
end

function M.reset()
	log.debug("Flow reset")

	M.is_active = false
	M.is_paused = false
	M.pause_started_at = nil
	M.last_motion_timestamp = nil
end

--
-- Entry Points
--

--- Called at the start of every smart motion
--- Determines if we should jump directly (chained flow) or not.
function M.evaluate_flow_at_motion_start()
	if not M.last_motion_timestamp then
		-- First smart motion ever, just set the timestamp for the future smart motions.
		M.refresh_timestamp()
		log.debug("First SmartMotion - set initial timestamp")
		return false
	end

	if M.is_expired() then
		M.exit_flow()
		M.refresh_timestamp()
		log.debug("Flow expired - reset timestamp for next SmartMotion")
		return false
	end

	-- Within threshold, allow flow.
	M.refresh_timestamp()
	return true
end

--- Called after label selection (then only time flow can *start*)
--- Determines if we should entr flow or not.
function M.evaluate_flow_at_selection()
	if M.is_expired() then
		M.exit_flow()
		M.refresh_timestamp()
		log.debug("Flow expired at selection - reset timestamp")
		return false
	end

	-- This is where flow *starts* if it's allowed (first link in chain).
	M.start_flow()
	log.debug("Flow started at selection")
	return true
end

return M
