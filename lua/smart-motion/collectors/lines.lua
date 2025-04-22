local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@param include_cursor_line boolean
local function collect_lines_after_cursor(ctx, cfg, motion_state, include_cursor_line)
	local bufnr = ctx.bufnr
	local cursor_line = ctx.cursor_line
	local last_line = vim.api.nvim_buf_line_count(bufnr)
	local results = {}

	if include_cursor_line then
		local line = vim.api.nvim_buf_get_lines(bufnr, cursor_line, cursor_line + 1, false)[1]
		if line then
			table.insert(results, { line_number = cursor_line, text = line })
		end
	end

	local count = math.min(motion_state.max_lines, last_line - (cursor_line + 1))
	for line_number = cursor_line + 1, cursor_line + count do
		local line = vim.api.nvim_buf_get_lines(bufnr, line_number, line_number + 1, false)[1]
		if line then
			table.insert(results, { line_number = line_number, text = line })
		end
	end

	return results
end

---@param ctx SmartMotionContext
---@param cfg SmartMotionConfig
---@param motion_state SmartMotionMotionState
---@param include_cursor_line boolean
local function collect_lines_before_cursor(ctx, cfg, motion_state, include_cursor_line)
	local bufnr = ctx.bufnr
	local cursor_line = ctx.cursor_line
	local start_line = math.max(cursor_line - motion_state.max_lines, 0)
	local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, cursor_line, false)

	local results = {}
	for i, text in ipairs(lines) do
		local line_number = start_line + (i - 1)
		table.insert(results, { line_number = line_number, text = text })
	end

	if include_cursor_line then
		local line = vim.api.nvim_buf_get_lines(bufnr, cursor_line, cursor_line + 1, false)[1]
		if line then
			table.insert(results, { line_number = cursor_line, text = line })
		end
	end

	return vim.fn.reverse(results) -- still yield top-down for BEFORE mode
end

---@class SmartMotionLineData
---@field line_number integer
---@field text string

---@type SmartMotionCollectorModuleEntry
local M = {}

--- Collects lines from buffer based on motion direction.
--- @param opts table Passed down the pipeline (can be empty or contain custom data)
--- @return thread A coroutine generator yielding SmartMotionLineData objects
function M.run(opts)
	return coroutine.create(function(ctx, cfg, motion_state)
		---@type SmartMotionContext
		ctx = ctx
		---@type SmartMotionConfig
		cfg = cfg
		---@type SmartMotionMotionState
		motion_state = motion_state

		if not vim.api.nvim_buf_is_valid(ctx.bufnr) then
			log.error("lines_collector received an invalid buffer: " .. tostring(ctx.bufnr))

			return
		end

		local last_line = vim.api.nvim_buf_line_count(ctx.bufnr)

		if motion_state.direction == consts.DIRECTION.AFTER_CURSOR then
			for _, data in ipairs(collect_lines_after_cursor(ctx, cfg, motion_state, true)) do
				coroutine.yield(data)
			end
		elseif motion_state.direction == consts.DIRECTION.BEFORE_CURSOR then
			for _, data in ipairs(collect_lines_before_cursor(ctx, cfg, motion_state, true)) do
				coroutine.yield(data)
			end
		elseif motion_state.direction == consts.DIRECTION.BOTH then
			local before = collect_lines_before_cursor(ctx, cfg, motion_state)
			local after = collect_lines_after_cursor(ctx, cfg, motion_state)

			local combined = vim.list_extend(before, after, 1)

			table.sort(combined, function(a, b)
				return math.abs(a.line_number - ctx.cursor_line) < math.abs(b.line_number - ctx.cursor_line)
			end)

			for _, data in ipairs(combined) do
				coroutine.yield(data)
			end
		end
	end)
end

return M
