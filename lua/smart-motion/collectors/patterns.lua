local exit = require("smart-motion.core.events.exit")
local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local EXIT_TYPE = consts.EXIT_TYPE

---@type SmartMotionCollectorModuleEntry
local M = {}

--- Collects targets by matching vim regex patterns against buffer lines.
--- @return thread A coroutine generator yielding pattern match targets
function M.run()
	return coroutine.create(function(ctx, cfg, motion_state)
		exit.throw_if(not vim.api.nvim_buf_is_valid(ctx.bufnr), EXIT_TYPE.EARLY_EXIT)

		local patterns = motion_state.patterns
		exit.throw_if(not patterns or #patterns == 0, EXIT_TYPE.EARLY_EXIT)

		local total_lines = vim.api.nvim_buf_line_count(ctx.bufnr)
		local window_size = motion_state.max_lines or 100
		local cursor_line = ctx.cursor_line

		local start_line = math.max(0, cursor_line - window_size)
		local end_line = math.min(total_lines - 1, cursor_line + window_size)

		for line_number = start_line, end_line do
			local line = vim.api.nvim_buf_get_lines(ctx.bufnr, line_number, line_number + 1, false)[1]

			if line and #line > 0 then
				for pattern_index, pattern in ipairs(patterns) do
					local search_start = 0

					while search_start < #line do
						local ok, match_data = pcall(vim.fn.matchstrpos, line, pattern, search_start)

						if not ok or match_data[2] == -1 then
							break
						end

						local match, match_start, match_end = match_data[1], match_data[2], match_data[3]

						if match == "" then
							break
						end

						if motion_state.patterns_whole_line then
							coroutine.yield({
								text = line,
								line_number = line_number,
								start_pos = { row = line_number, col = 0 },
								end_pos = { row = line_number, col = #line },
								type = "pattern",
								metadata = {
									pattern_index = pattern_index,
								},
							})
							break
						else
							coroutine.yield({
								text = match,
								line_number = line_number,
								start_pos = { row = line_number, col = match_start },
								end_pos = { row = line_number, col = match_end },
								type = "pattern",
								metadata = {
									pattern_index = pattern_index,
								},
							})
						end

						search_start = match_end
					end
				end
			end
		end
	end)
end

M.metadata = {
	label = "Pattern Collector",
	description = "Collects targets by matching vim regex patterns against buffer lines",
}

return M
