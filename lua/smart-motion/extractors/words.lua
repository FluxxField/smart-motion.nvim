local M

function M.extract(ctx, cfg, motion_state, collector)
	local jump_targets = {}

	-- selected_jump_target is nil unless the collector returns
	-- a first_jump_target
	if motion_state.selected_jump_target then
		table.insert(jump_targets, motion_state.selected_jump_target)
	end

	while true do
		local ok, jump_target = coroutine.resume(collector, ctx, cfg, motion_state)

		if not ok or not jump_target then
			break
		end

		table.insert(jump_targets, jump_target)
	end

	motion_state.jump_targets = jump_targets
end

return M
