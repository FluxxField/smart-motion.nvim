--- @type SmartMotionPipelineWrapperModule
local M = {}

--- Default pipeline wrapper: executes the pipeline once without interaction.
--- @param run_pipeline fun(ctx: SmartMotionContext, cfg: SmartMotionConfig, state: SmartMotionMotionState, opts: table): nil
--- @param ctx SmartMotionContext
--- @param cfg SmartMotionConfig
--- @param motion_state SmartMotionMotionState
--- @return boolean? Return value to signal early exit (optional)
function M.run(run_pipeline, ctx, cfg, motion_state)
	local opts = {}

	return run_pipeline(ctx, cfg, motion_state, opts)
end

return M
