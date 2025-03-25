local M = {}

--- Formats a jump target to ensure consistent structure.
---@param ctx table The motion context.
---@param cfg table The motion config.
---@param motion_state table The current motion state.
---@param raw_data table The raw extracted data.
---@return table A formatted jump target.
function M.format_jump_target(ctx, cfg, motion_state, raw_data)
	return {
		bufnr = ctx.bufnr,
		winid = ctx.winid,
		row = raw_data.row,
		col = raw_data.col,
		text = raw_data.text,
		start_pos = raw_data.start_pos,
		end_pos = raw_data.end_pos,
		type = raw_data.type or "unknown",
		metadata = raw_data.metadata or {},
	}
end

--- Extracts and formats jump targets using the provided extractor.
---@param ctx table The motion context.
---@param cfg table The motion config.
---@param motion_state table The current motion state.
---@param extractor thread The coroutine-based extractor function.
---@return table[] jump_targets A list of formatted jump targets
---@return table|nil first_jump_target The first valid jump target, or nil.
function M.get_jump_targets(ctx, cfg, motion_state, extractor)
	local jump_targets = {}
	local first_jump_target = nil

	-- Ensure extractor is a coroutine
	if type(extractor) ~= "thread" then
		error("Extractor must be a coroutine")
	end

	while true do
		local ok, data = coroutine.resume(extractor, ctx, cfg, motion_state)

		if not ok or not data then
			break
		end

		local formatted_jump_target = M.format_jump_target(ctx, cfg, motion_state, data)

		table.insert(jump_targets, formatted_jump_target)

		-- Capture the first valid target
		if not first_jump_target then
			first_jump_target = formatted_jump_target
		end
	end

	motion_state.jump_targets = jump_targets
	motion_state.selected_jump_target = first_jump_target
end

return M
