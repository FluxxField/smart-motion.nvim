local log = require("smart-motion.core.log")

---@type SmartMotionCollectorModuleEntry
local M = {}

--- Collects quickfix or location list entries as targets.
--- Supports filtering via motion_state:
---   use_loclist: boolean - use location list instead of quickfix (default false)
--- @return thread A coroutine generator yielding target-like objects
function M.run()
	return coroutine.create(function(ctx, cfg, motion_state)
		local entries
		local list_type = "quickfix"

		if motion_state.use_loclist then
			list_type = "loclist"
			entries = vim.fn.getloclist(ctx.winid)
		else
			entries = vim.fn.getqflist()
		end

		if not entries or #entries == 0 then
			log.debug("Quickfix collector: no entries in " .. list_type)
			return
		end

		for idx, entry in ipairs(entries) do
			-- Skip invalid entries (bufnr = 0 means no file)
			if entry.bufnr and entry.bufnr > 0 and entry.lnum and entry.lnum > 0 then
				-- Get the line text for display
				local line_text = ""
				local ok, lines = pcall(vim.api.nvim_buf_get_lines, entry.bufnr, entry.lnum - 1, entry.lnum, false)
				if ok and lines and #lines > 0 then
					line_text = lines[1]
				end

				-- Determine first non-blank column if col is 0
				local col = entry.col
				if col == 0 or col == nil then
					local first_char = line_text:find("%S")
					col = first_char or 1
				end

				-- Get entry type (E=error, W=warning, I=info, N=note, H=hint)
				local entry_type = entry.type or ""
				if entry_type == "" and entry.text then
					-- Try to infer from text
					if entry.text:match("[Ee]rror") then
						entry_type = "E"
					elseif entry.text:match("[Ww]arning") then
						entry_type = "W"
					end
				end

				coroutine.yield({
					text = entry.text or line_text,
					start_pos = { row = entry.lnum - 1, col = col - 1 }, -- 0-indexed
					end_pos = { row = entry.lnum - 1, col = col }, -- minimal range
					type = "quickfix",
					metadata = {
						bufnr = entry.bufnr,
						lnum = entry.lnum,
						col = col,
						entry_type = entry_type,
						entry_text = entry.text,
						qf_idx = idx,
						list_type = list_type,
						filename = vim.fn.bufname(entry.bufnr),
					},
				})
			end
		end
	end)
end

M.metadata = {
	label = "Quickfix Collector",
	description = "Collects quickfix or location list entries as jump targets",
}

return M
