local log = require("smart-motion.core.log")

---@type SmartMotionCollectorModuleEntry
local M = {}

--- Try to get hunks from gitsigns.nvim (most common git integration)
--- @param bufnr number
--- @return table[]|nil hunks List of hunks or nil if gitsigns not available
local function get_gitsigns_hunks(bufnr)
	local ok, gitsigns = pcall(require, "gitsigns")
	if not ok then
		return nil
	end

	-- gitsigns.get_hunks() returns hunks for current buffer
	-- Each hunk has: added, removed, head, lines, start, vend
	local hunks = gitsigns.get_hunks(bufnr)
	if not hunks or #hunks == 0 then
		return nil
	end

	return hunks
end

--- Fallback: get hunks by parsing git diff output
--- @param bufnr number
--- @return table[]|nil hunks List of hunks or nil if not a git repo
local function get_git_diff_hunks(bufnr)
	local filepath = vim.api.nvim_buf_get_name(bufnr)
	if filepath == "" then
		return nil
	end

	-- Get the directory of the file for git command
	local dir = vim.fn.fnamemodify(filepath, ":h")

	-- Run git diff to get changed lines
	-- Using -U0 for minimal context, parsing @@ hunk headers
	local cmd = string.format(
		"cd %s && git diff --no-color -U0 -- %s 2>/dev/null",
		vim.fn.shellescape(dir),
		vim.fn.shellescape(vim.fn.fnamemodify(filepath, ":t"))
	)

	local output = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 or output == "" then
		-- Try git diff HEAD for staged changes
		cmd = string.format(
			"cd %s && git diff HEAD --no-color -U0 -- %s 2>/dev/null",
			vim.fn.shellescape(dir),
			vim.fn.shellescape(vim.fn.fnamemodify(filepath, ":t"))
		)
		output = vim.fn.system(cmd)
		if vim.v.shell_error ~= 0 or output == "" then
			return nil
		end
	end

	local hunks = {}
	-- Parse @@ -old_start,old_count +new_start,new_count @@ headers
	for line in output:gmatch("[^\n]+") do
		local new_start, new_count = line:match("^@@ %-%d+,?%d* %+(%d+),?(%d*) @@")
		if new_start then
			new_start = tonumber(new_start)
			new_count = tonumber(new_count) or 1
			if new_count == 0 then
				new_count = 1 -- Deletion shows as 0 lines, treat as 1 for jumping
			end
			table.insert(hunks, {
				start = new_start,
				vend = new_start + new_count - 1,
				type = "change",
			})
		end
	end

	return #hunks > 0 and hunks or nil
end

--- Determine hunk type from gitsigns hunk data
--- @param hunk table
--- @return string "add"|"delete"|"change"
local function get_hunk_type(hunk)
	if hunk.type then
		return hunk.type
	end
	-- Gitsigns format
	if hunk.added and hunk.removed then
		if hunk.added.count > 0 and hunk.removed.count > 0 then
			return "change"
		elseif hunk.added.count > 0 then
			return "add"
		else
			return "delete"
		end
	end
	return "change"
end

--- Collects git hunks (changed regions) as targets.
--- Supports gitsigns.nvim if available, falls back to git diff parsing.
--- @return thread A coroutine generator yielding target-like objects
function M.run()
	return coroutine.create(function(ctx, cfg, motion_state)
		local bufnr = ctx.bufnr

		-- Try gitsigns first (most common and accurate)
		local hunks = get_gitsigns_hunks(bufnr)

		-- Fallback to git diff parsing
		if not hunks then
			hunks = get_git_diff_hunks(bufnr)
		end

		if not hunks or #hunks == 0 then
			log.debug("Git hunks collector: no hunks in buffer " .. tostring(bufnr))
			return
		end

		for _, hunk in ipairs(hunks) do
			local start_line = hunk.start or (hunk.added and hunk.added.start) or 1
			local end_line = hunk.vend or hunk["end"] or start_line

			-- Get first non-blank column on the start line for better positioning
			local line_text = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, start_line, false)[1] or ""
			local first_col = line_text:find("%S") or 1
			first_col = first_col - 1 -- Convert to 0-indexed

			local hunk_type = get_hunk_type(hunk)

			coroutine.yield({
				text = line_text,
				start_pos = { row = start_line - 1, col = first_col }, -- 0-indexed
				end_pos = { row = end_line - 1, col = #line_text },
				type = "git_hunk",
				metadata = {
					hunk_type = hunk_type,
					start_line = start_line,
					end_line = end_line,
				},
			})
		end
	end)
end

M.metadata = {
	label = "Git Hunks Collector",
	description = "Collects git changed regions (hunks) as jump targets. Supports gitsigns.nvim or falls back to git diff.",
}

return M
