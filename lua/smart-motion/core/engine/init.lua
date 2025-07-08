local exit_event = require("smart-motion.core.events.exit")
local setup = require("smart-motion.core.engine.setup")
local handle_exit = require("smart-motion.core.engine.exit")
local flow_state = require("smart-motion.core.flow_state")
local pipeline = require("smart-motion.core.engine.pipeline")

local M = {}

--- @param trigger_key string
function M.run(trigger_key)
	local ctx, cfg, motion_state

	local exit_type = exit_event.wrap(function()
		ctx, cfg, motion_state = setup.run(trigger_key)

		if flow_state.evaluate_flow_at_motion_state() then
			pipeline.run(ctx, cfg, motion_state)
		end
	end)

	handle_exit(ctx, cfg, motion_state, exit_type)
end

return M
