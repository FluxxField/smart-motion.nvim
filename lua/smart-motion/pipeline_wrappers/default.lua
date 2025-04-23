local consts = require("smart-motion.consts")
local SEARCH_EXIT_TYPE = consts.SEARCH_EXIT_TYPE

local M = {}

--- Default pipeline wrapper: executes the pipeline once without interaction.
--- @param run_pipeline fun(ctx: SmartMotionContext, cfg: SmartMotionConfig, state: SmartMotionMotionState, opts: table): nil
--- @param ctx SmartMotionContext
--- @param cfg SmartMotionConfig
--- @param motion_state SmartMotionMotionState
--- @return SearchExitType
function M.run(run_pipeline, ctx, cfg, motion_state)
	local opts = {}

	run_pipeline(ctx, cfg, motion_state, opts)

	return SEARCH_EXIT_TYPE.CONTINUE_TO_SELECTION
end

return M
