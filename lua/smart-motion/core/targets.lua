local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local TARGET_TYPES = consts.TARGET_TYPES
local DIRECTION = consts.DIRECTION

local M = {}

--- @class Target
--- @field bufnr integer
--- @field winid integer
--- @field row integer
--- @field col integer
--- @field text? string
--- @field start_pos { row: integer, col: integer }
--- @field end_pos { row: integer, col: integer }
--- @field type string
--- @field filetype string
--- @field metadata? table

--- Formats a target to ensure consistent structure.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@param raw_data table
---@return Target
function M.format_target(ctx, cfg, motion_state, raw_data)
	return {
		text = raw_data.text,
		start_pos = raw_data.start_pos,
		end_pos = raw_data.end_pos,
		type = raw_data.type or "unknown",
		metadata = vim.tbl_deep_extend("force", raw_data.metadata or {}, {
			bufnr = ctx.bufnr,
			winid = ctx.winid,
			filetype = vim.bo[ctx.bufnr].filetype,
		}),
	}
end

--- Extracts and formats jump targets using the provided extractor.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@param extractor thread
function M.get_targets(ctx, cfg, motion_state, filter_gen)
	local targets = {}

	if type(filter_gen) ~= "thread" then
		error("Then filter generator must be a coroutine")
	end

	if motion_state.exit_type then
		return
	end

	while true do
		local ok, data_or_error = coroutine.resume(filter_gen, ctx, cfg, motion_state)

		if not ok then
			log.error("Filter Coroutine Error: " .. tostring(data_or_error))
			break
		end

		if not data_or_error then
			break
		end

		table.insert(targets, M.format_target(ctx, cfg, motion_state, data_or_error))
	end

	if motion_state.direction == DIRECTION.BEFORE_CURSOR then
		targets = vim.fn.reverse(targets)
	end

	motion_state.jump_targets = targets
	motion_state.selected_jump_target = targets[1]
end

--- Gets a synthetic jump target directly under the cursor.
---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@return Target|nil
function M.get_target_under_cursor(ctx, cfg, motion_state)
	local bufnr = ctx.bufnr
	local cursor_line, cursor_col = ctx.cursor_line, ctx.cursor_col
	local line_content = vim.api.nvim_buf_get_lines(bufnr, cursor_line, cursor_line + 1, false)[1]

	if not line_content then
		return nil
	end

	if motion_state.target_type == TARGET_TYPES.LINES then
		return M.format_target(ctx, cfg, motion_state, {
			start_pos = { row = cursor_line, col = 0 },
			end_pos = { row = cursor_line, col = #line_content },
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
				return M.format_target(ctx, cfg, motion_state, {
					start_pos = { row = cursor_line, col = match_start },
					end_pos = { row = cursor_line, col = match_end },
					text = matched_text,
					type = motion_state.target_type,
				})
			end

			search_start = match_end
		end
	end

	return nil
end

return M
