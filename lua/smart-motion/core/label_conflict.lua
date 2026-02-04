--- Label conflict avoidance: filters out labels that could be valid search continuations.
--- If searching "fo" and matches include "foo", "for", "fox", then "o", "r", "x" are excluded
--- because pressing those keys could mean continuing the search rather than selecting a label.
local log = require("smart-motion.core.log")

local M = {}

--- Gets the character immediately following each target's match position.
--- These characters are potential conflicts because typing them could extend the search.
---@param targets table[] List of targets with start_pos, end_pos
---@param bufnr integer Buffer number
---@return table<string, boolean> Set of conflicting characters (lowercase)
function M.get_conflicting_chars(targets, bufnr)
	local conflicts = {}

	for _, target in ipairs(targets) do
		local target_bufnr = target.metadata and target.metadata.bufnr or bufnr
		local end_row = target.end_pos.row
		local end_col = target.end_pos.col

		-- Get the line containing the end of the match
		local lines = vim.api.nvim_buf_get_lines(target_bufnr, end_row, end_row + 1, false)
		if lines and lines[1] then
			local line = lines[1]
			-- Get the character at end_col (which is the first char after the match)
			if end_col < #line then
				local next_char = line:sub(end_col + 1, end_col + 1)
				-- Only consider alphanumeric characters as potential conflicts
				if next_char:match("[%w]") then
					-- Store lowercase version for case-insensitive comparison
					conflicts[next_char:lower()] = true
				end
			end
		end
	end

	return conflicts
end

--- Filters a list of label keys to remove conflicting characters.
---@param keys string[] Original list of label keys
---@param conflicts table<string, boolean> Set of conflicting characters
---@return string[] Filtered list of keys
function M.filter_keys(keys, conflicts)
	if not conflicts or not next(conflicts) then
		return keys
	end

	local filtered = {}
	for _, key in ipairs(keys) do
		-- Check if this key (or its lowercase version) conflicts
		if not conflicts[key:lower()] then
			table.insert(filtered, key)
		end
	end

	log.debug(string.format(
		"Label conflict filter: %d keys -> %d keys (excluded %d)",
		#keys,
		#filtered,
		#keys - #filtered
	))

	return filtered
end

--- Main entry point: filters keys based on targets.
--- Call this before generating labels when in search mode.
---@param keys string[] Original list of label keys from config
---@param targets table[] List of targets with positions
---@param bufnr integer Buffer number
---@return string[] Filtered list of keys
function M.filter_conflicting_labels(keys, targets, bufnr)
	if not targets or #targets == 0 then
		return keys
	end

	local conflicts = M.get_conflicting_chars(targets, bufnr)
	return M.filter_keys(keys, conflicts)
end

return M
