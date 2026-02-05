local consts = require("smart-motion.consts")

local HISTORY_MAX_SIZE = consts.HISTORY_MAX_SIZE

local M = {
	entries = {},
	max_size = HISTORY_MAX_SIZE,
}

function M.add(entry)
	-- Store filepath so we can reopen closed buffers later
	if entry.target and entry.target.metadata and entry.target.metadata.bufnr then
		local ok, name = pcall(vim.api.nvim_buf_get_name, entry.target.metadata.bufnr)
		if ok and name ~= "" then
			entry.filepath = name
		end
	end

	table.insert(M.entries, 1, entry)

	if #M.entries > M.max_size then
		table.remove(M.entries)
	end
end

function M.last()
	return M.entries[1]
end

function M.clear()
	M.entries = {}
end

return M
