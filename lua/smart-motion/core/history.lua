local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local HISTORY_MAX_SIZE = consts.HISTORY_MAX_SIZE
local HISTORY_VERSION = 1

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

--- Saves all history entries to disk as JSON.
function M._save()
	local filepath = M._get_history_filepath()
	local dir = M._get_history_dir()

	-- Ensure directory exists
	vim.fn.mkdir(dir, "p")

	local serialized = {}
	for _, entry in ipairs(M.entries) do
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

	local loaded = {}
	for _, raw in ipairs(data.entries) do
		local entry = M._deserialize_entry(raw)
		if entry then
			table.insert(loaded, entry)
		end
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
