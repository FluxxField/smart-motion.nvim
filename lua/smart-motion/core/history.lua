local consts = require("smart-motion.consts")

local HISTORY_MAX_SIZE = consts.HISTORY_MAX_SIZE

local M = {
	entries = {},
	max_size = HISTORY_MAX_SIZE,
}

function M.add(entry)
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
