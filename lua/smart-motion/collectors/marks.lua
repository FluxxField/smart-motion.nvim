local log = require("smart-motion.core.log")

---@type SmartMotionCollectorModuleEntry
local M = {}

--- Collects vim marks as targets.
--- Supports filtering via motion_state:
---   marks_local_only: boolean - only show buffer-local marks (a-z)
---   marks_global_only: boolean - only show global marks (A-Z)
--- @return thread A coroutine generator yielding target-like objects
function M.run()
	return coroutine.create(function(ctx, cfg, motion_state)
		local bufnr = ctx.bufnr
		local marks_found = {}

		-- Collect buffer-local marks (a-z) unless global_only
		if not motion_state.marks_global_only then
			local local_marks = vim.fn.getmarklist(bufnr)
			for _, mark in ipairs(local_marks) do
				-- mark.mark is like "'a", extract just the letter
				local mark_name = mark.mark:sub(2)
				-- Only include a-z marks
				if mark_name:match("^[a-z]$") then
					local pos = mark.pos
					if pos and pos[2] and pos[2] > 0 then
						table.insert(marks_found, {
							name = mark_name,
							lnum = pos[2],
							col = pos[3] or 0,
							bufnr = bufnr,
							is_global = false,
						})
					end
				end
			end
		end

		-- Collect global marks (A-Z) unless local_only
		if not motion_state.marks_local_only then
			local global_marks = vim.fn.getmarklist()
			for _, mark in ipairs(global_marks) do
				local mark_name = mark.mark:sub(2)
				-- Only include A-Z marks (skip 0-9 and special marks)
				if mark_name:match("^[A-Z]$") then
					local pos = mark.pos
					local mark_bufnr = pos[1]
					-- Include if it's in current buffer or we want cross-buffer marks
					if mark_bufnr and mark_bufnr > 0 and pos[2] and pos[2] > 0 then
						-- For multi-window, we might want marks from other buffers too
						-- But for now, filter to visible buffers
						local include = false
						if motion_state.multi_window then
							-- Check if this buffer is visible in any window
							for _, win in ipairs(ctx.windows or { ctx.winid }) do
								if vim.api.nvim_win_get_buf(win) == mark_bufnr then
									include = true
									break
								end
							end
						else
							include = (mark_bufnr == bufnr)
						end

						if include then
							table.insert(marks_found, {
								name = mark_name,
								lnum = pos[2],
								col = pos[3] or 0,
								bufnr = mark_bufnr,
								is_global = true,
								file = mark.file,
							})
						end
					end
				end
			end
		end

		if #marks_found == 0 then
			log.debug("Marks collector: no marks found")
			return
		end

		-- Sort by line number for consistent ordering
		table.sort(marks_found, function(a, b)
			if a.bufnr ~= b.bufnr then
				return a.bufnr < b.bufnr
			end
			if a.lnum ~= b.lnum then
				return a.lnum < b.lnum
			end
			return a.col < b.col
		end)

		for _, mark in ipairs(marks_found) do
			-- Get line text for display
			local line_text = ""
			local ok, lines = pcall(vim.api.nvim_buf_get_lines, mark.bufnr, mark.lnum - 1, mark.lnum, false)
			if ok and lines and #lines > 0 then
				line_text = lines[1]
			end

			-- Adjust col to first non-blank if it's 0
			local col = mark.col
			if col == 0 then
				local first_char = line_text:find("%S")
				col = first_char or 1
			end

			coroutine.yield({
				text = line_text,
				start_pos = { row = mark.lnum - 1, col = col - 1 }, -- 0-indexed
				end_pos = { row = mark.lnum - 1, col = col },
				type = "mark",
				metadata = {
					bufnr = mark.bufnr,
					mark_name = mark.name,
					is_global = mark.is_global,
					lnum = mark.lnum,
					col = col,
					file = mark.file,
				},
			})
		end
	end)
end

M.metadata = {
	label = "Marks Collector",
	description = "Collects vim marks (a-z local, A-Z global) as jump targets",
}

return M
