local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local HISTORY_MAX_SIZE = consts.HISTORY_MAX_SIZE
local HISTORY_VERSION = 1
local HISTORY_MAX_AGE_SECS = 30 * 24 * 3600 -- 30 days

local M = {
	entries = {},
	max_size = HISTORY_MAX_SIZE,
}

--- Returns a dedup key for an entry based on filepath and position.
---@param entry table
---@return string
function M._entry_key(entry)
	local fp = entry.filepath or ""
	local row = entry.target and entry.target.start_pos and entry.target.start_pos.row or 0
	local col = entry.target and entry.target.start_pos and entry.target.start_pos.col or 0
	return fp .. ":" .. row .. ":" .. col
end

function M.add(entry)
	-- Store filepath so we can reopen closed buffers later
	if entry.target and entry.target.metadata and entry.target.metadata.bufnr then
		local ok, name = pcall(vim.api.nvim_buf_get_name, entry.target.metadata.bufnr)
		if ok and name ~= "" then
			entry.filepath = name
		end
	end

	-- Deduplicate: remove existing entry at same location
	local key = M._entry_key(entry)
	for i = #M.entries, 1, -1 do
		if M._entry_key(M.entries[i]) == key then
			table.remove(M.entries, i)
			break
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

--- Gets the project root via git, falling back to cwd.
---@return string
function M._get_project_root()
	local result = vim.fn.system("git rev-parse --show-toplevel 2>/dev/null")
	if vim.v.shell_error == 0 and result and result ~= "" then
		return vim.trim(result)
	end
	return vim.fn.getcwd()
end

--- Gets the directory for storing history files.
---@return string
function M._get_history_dir()
	return vim.fn.stdpath("data") .. "/smart-motion/history"
end

--- Gets the filepath for the current project's history file.
---@return string
function M._get_history_filepath()
	local root = M._get_project_root()
	local hash = vim.fn.sha256(root)
	return M._get_history_dir() .. "/" .. hash .. ".json"
end

--- Serializes a history entry for persistence, stripping session-specific fields.
---@param entry table
---@return table|nil
function M._serialize_entry(entry)
	local ok, result = pcall(function()
		local target = entry.target or {}
		return {
			motion = { trigger_key = entry.motion and entry.motion.trigger_key or "?" },
			target = {
				text = target.text,
				start_pos = target.start_pos,
				end_pos = target.end_pos,
				type = target.type,
				metadata = {
					filetype = target.metadata and target.metadata.filetype or nil,
				},
			},
			filepath = entry.filepath,
			metadata = { time_stamp = entry.metadata and entry.metadata.time_stamp or os.time() },
		}
	end)
	if ok then
		return result
	end
	return nil
end

--- Deserializes a persisted entry back into a format compatible with history_browse.
---@param data table
---@return table|nil
function M._deserialize_entry(data)
	local ok, result = pcall(function()
		return {
			motion = data.motion or { trigger_key = "?" },
			target = {
				text = data.target and data.target.text or "",
				start_pos = data.target and data.target.start_pos or nil,
				end_pos = data.target and data.target.end_pos or nil,
				type = data.target and data.target.type or nil,
				metadata = {
					filetype = data.target and data.target.metadata and data.target.metadata.filetype or nil,
				},
			},
			filepath = data.filepath,
			metadata = data.metadata or { time_stamp = os.time() },
		}
	end)
	if ok then
		return result
	end
	return nil
end

--- Merges in-memory entries with existing disk entries for concurrent session support.
--- In-memory entries take priority; disk-only entries are appended.
--- Result is sorted by timestamp (most recent first) and trimmed to max_size.
---@return table[] merged entries
function M._merge_with_disk()
	local filepath = M._get_history_filepath()

	local f = io.open(filepath, "r")
	if not f then
		return M.entries
	end

	local read_ok, content = pcall(function()
		local c = f:read("*a")
		f:close()
		return c
	end)

	if not read_ok or not content or content == "" then
		pcall(function() f:close() end)
		return M.entries
	end

	local decode_ok, data = pcall(vim.fn.json_decode, content)
	if not decode_ok or type(data) ~= "table" or data.version ~= HISTORY_VERSION then
		return M.entries
	end

	-- Start with in-memory entries (current session takes priority)
	local seen = {}
	local merged = {}

	for _, entry in ipairs(M.entries) do
		local key = M._entry_key(entry)
		if not seen[key] then
			seen[key] = true
			table.insert(merged, entry)
		end
	end

	-- Add disk entries not already present from current session
	local now = os.time()
	for _, raw in ipairs(data.entries or {}) do
		local entry = M._deserialize_entry(raw)
		if entry then
			local key = M._entry_key(entry)
			if not seen[key] then
				-- Skip expired
				local ts = entry.metadata and entry.metadata.time_stamp or 0
				if (now - ts) <= HISTORY_MAX_AGE_SECS then
					seen[key] = true
					table.insert(merged, entry)
				end
			end
		end
	end

	-- Sort by timestamp descending (most recent first)
	table.sort(merged, function(a, b)
		local ta = a.metadata and a.metadata.time_stamp or 0
		local tb = b.metadata and b.metadata.time_stamp or 0
		return ta > tb
	end)

	-- Trim to max_size
	while #merged > M.max_size do
		table.remove(merged)
	end

	return merged
end

--- Saves all history entries to disk as JSON.
--- Merges with existing disk entries to preserve other sessions' history.
function M._save()
	local filepath = M._get_history_filepath()
	local dir = M._get_history_dir()

	-- Ensure directory exists
	vim.fn.mkdir(dir, "p")

	-- Merge with disk for concurrent session support
	local entries_to_save = M._merge_with_disk()

	local serialized = {}
	for _, entry in ipairs(entries_to_save) do
		local s = M._serialize_entry(entry)
		if s then
			table.insert(serialized, s)
		end
	end

	local data = {
		version = HISTORY_VERSION,
		project_root = M._get_project_root(),
		entries = serialized,
	}

	local ok, json = pcall(vim.fn.json_encode, data)
	if not ok then
		log.warn("Failed to encode history: " .. tostring(json))
		return
	end

	local write_ok, err = pcall(function()
		local f = io.open(filepath, "w")
		if not f then
			error("Cannot open file for writing: " .. filepath)
		end
		f:write(json)
		f:close()
	end)

	if not write_ok then
		log.warn("Failed to save history: " .. tostring(err))
	end
end

--- Loads history entries from disk.
function M._load()
	local filepath = M._get_history_filepath()

	local f = io.open(filepath, "r")
	if not f then
		return -- First run or no history file, silent no-op
	end

	local ok, content = pcall(function()
		local c = f:read("*a")
		f:close()
		return c
	end)

	if not ok or not content or content == "" then
		pcall(function() f:close() end)
		return
	end

	local decode_ok, data = pcall(vim.fn.json_decode, content)
	if not decode_ok or type(data) ~= "table" then
		log.warn("Corrupt history file, starting fresh")
		return
	end

	if data.version ~= HISTORY_VERSION then
		log.warn("History file version mismatch (expected " .. HISTORY_VERSION .. "), starting fresh")
		return
	end

	if type(data.entries) ~= "table" then
		return
	end

	local now = os.time()
	local loaded = {}
	for _, raw in ipairs(data.entries) do
		local entry = M._deserialize_entry(raw)
		if entry then
			-- Expiry: skip entries older than 30 days
			local ts = entry.metadata and entry.metadata.time_stamp or 0
			if (now - ts) > HISTORY_MAX_AGE_SECS then
				goto continue
			end

			-- Stale pruning: skip entries for files that no longer exist
			if entry.filepath and entry.filepath ~= "" and vim.fn.filereadable(entry.filepath) == 0 then
				goto continue
			end

			table.insert(loaded, entry)
		end
		::continue::
	end

	-- Trim to current max_size
	while #loaded > M.max_size do
		table.remove(loaded)
	end

	M.entries = loaded
end

--- Sets up VimLeavePre autocmd to save history on exit.
function M._setup_autocmds()
	local group = vim.api.nvim_create_augroup("SmartMotionHistory", { clear = true })
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			M._save()
		end,
	})
end

--- Initialize history persistence: apply config, load from disk, set up autocmds.
---@param cfg SmartMotionConfig
function M.setup(cfg)
	if cfg.history_max_size and type(cfg.history_max_size) == "number" then
		M.max_size = cfg.history_max_size
	end

	M._load()
	M._setup_autocmds()
end

return M
