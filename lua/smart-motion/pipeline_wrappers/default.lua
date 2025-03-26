local M = {}

function M.run(run_pipeline, ctx, cfg, motion_state)
	local opts = {}

	return run_pipeline(ctx, cfg, motion_state, opts)
end

return M
