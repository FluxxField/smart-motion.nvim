local M = {}

function M.run(run_pipeline, ctx, cfg, motion_state)
	return run_pipeline(ctx, cfg, motion_state)
end

return M
