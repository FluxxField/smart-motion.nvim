local consts = require("smart-motion.consts")
local TARGET_TYPES = consts.TARGET_TYPES

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

function M.get_target_under_cursor(ctx, cfg, motion_state)
	local bufid = ctx.bufid
	local cursor_line, cursor_col = ctx.cursor_line, ctx.cursor_col
	local line_content = vim.api.nvim_buf_get_lines(bufid, cursor_line, cursor_line + 1, false)[1]

	if not line_content then
		return nil
	end

	if motion_state.target_type == TARGET_TYPES.LINES then
		return M.format_jump_target(ctx, cfg, motion_state, {
			row = cursor_line,
			col = 0,
			start_pos = { row = cursor_line, col = 0 },
			end_pos = { row = cursor_line, #line_content },
			text = line_content,
			type = motion_state.target_type,
		})
	elseif motion_state.target_type == TARGET_TYPES.WORDS then
		local search_start = 0

		while true do
			local match_data = vim.fn.matchstrpos(line_content, consts.WORD_PATTERN, search_start)
			local matched_text, match_start, match_end = match_data[1], match_data[2], match_data[3]

			if match_start == -1 then
				break
			end

			if cursor_col >= match_start and cursor_col < match_end then
				return {
					row = cursor_line,
					col = match_start,
					start_pos = { row = cursor_line, col = match_start },
					end_pos = { row = cursor_line, col = match_end - 1 },
					text = matched_text,
					type = motion_state.target_type,
				}
			end

			search_start = match_end
		end
	end

	return nil
end

return M
