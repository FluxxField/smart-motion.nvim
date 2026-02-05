local consts = require("smart-motion.consts")
local log = require("smart-motion.core.log")

local HISTORY_MAX_SIZE = consts.HISTORY_MAX_SIZE
local HISTORY_VERSION = 2
local HISTORY_MAX_AGE_SECS = 30 * 24 * 3600 -- 30 days

local M = {
	entries = {},
	pins = {},
	max_size = HISTORY_MAX_SIZE,
	max_pins = consts.PINS_MAX_SIZE,
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

	-- Deduplicate: remove existing entry at same location, carry forward visit_count
	local key = M._entry_key(entry)
	local carried_visit_count = 0
	for i = #M.entries, 1, -1 do
		if M._entry_key(M.entries[i]) == key then
			carried_visit_count = M.entries[i].visit_count or 1
			table.remove(M.entries, i)
			break
		end
	end

	entry.visit_count = carried_visit_count + 1

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

--- Computes a frecency score for an entry (higher = more relevant).
---@param entry table
---@return number
function M._frecency_score(entry)
	local visit_count = entry.visit_count or 1
	local elapsed = os.time() - (entry.metadata and entry.metadata.time_stamp or 0)
	local decay
	if elapsed < 3600 then
		decay = 1.0 -- < 1 hour
	elseif elapsed < 86400 then
		decay = 0.8 -- < 1 day
	elseif elapsed < 604800 then
		decay = 0.5 -- < 1 week
	else
		decay = 0.3 -- older
	end
	return visit_count * decay
end

--- Toggles a pin at the current cursor position.
function M.toggle_pin()
	local filepath = vim.api.nvim_buf_get_name(0)
	if filepath == "" then
		vim.notify("Cannot pin: buffer has no file", vim.log.levels.WARN)
		return
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1] - 1 -- 0-indexed
	local col = cursor[2]
	local cword = vim.fn.expand("<cword>")

	-- Build a pin entry
	local pin_entry = {
		filepath = filepath,
		target = {
			text = cword,
			type = "pin",
			start_pos = { row = row, col = col },
			end_pos = { row = row, col = col + #cword },
			metadata = {
				pinned = true,
				filetype = vim.bo.filetype,
			},
		},
		metadata = { time_stamp = os.time() },
	}

	local key = M._entry_key(pin_entry)

	-- Check if already pinned at this location
	for i, pin in ipairs(M.pins) do
		if M._entry_key(pin) == key then
			table.remove(M.pins, i)
			vim.notify("Unpinned", vim.log.levels.INFO)
			return
		end
	end

	-- Check max pins
	if #M.pins >= M.max_pins then
		vim.notify("Max pins reached (" .. M.max_pins .. "). Unpin one first.", vim.log.levels.WARN)
		return
	end

	table.insert(M.pins, pin_entry)
	vim.notify("Pinned (" .. #M.pins .. "/" .. M.max_pins .. ")", vim.log.levels.INFO)
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
			visit_count = entry.visit_count or 1,
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
			visit_count = data.visit_count or 1,
			metadata = data.metadata or { time_stamp = os.time() },
		}
	end)
	if ok then
		return result
	end
	return nil
end

--- Serializes a pin entry for persistence.
---@param pin table
---@return table|nil
function M._serialize_pin(pin)
	local ok, result = pcall(function()
		local target = pin.target or {}
		return {
			target = {
				text = target.text,
				start_pos = target.start_pos,
				end_pos = target.end_pos,
				type = target.type,
				metadata = {
					pinned = true,
					filetype = target.metadata and target.metadata.filetype or nil,
				},
			},
			filepath = pin.filepath,
			metadata = { time_stamp = pin.metadata and pin.metadata.time_stamp or os.time() },
		}
	end)
	if ok then
		return result
	end
	return nil
end

--- Merges in-memory entries with existing disk entries for concurrent session support.
--- Returns { entries = ..., pins = ... }
---@return table
function M._merge_with_disk()
	local filepath = M._get_history_filepath()

	local f = io.open(filepath, "r")
	if not f then
		return { entries = M.entries, pins = M.pins }
	end

	local read_ok, content = pcall(function()
		local c = f:read("*a")
		f:close()
		return c
	end)

	if not read_ok or not content or content == "" then
		pcall(function() f:close() end)
		return { entries = M.entries, pins = M.pins }
	end

	local decode_ok, data = pcall(vim.fn.json_decode, content)
	if not decode_ok or type(data) ~= "table" then
		return { entries = M.entries, pins = M.pins }
	end

	-- Accept version 1 or 2
	if data.version ~= 1 and data.version ~= 2 then
		return { entries = M.entries, pins = M.pins }
	end

	-- Merge entries
	local seen = {}
	local merged = {}

	for _, entry in ipairs(M.entries) do
		local key = M._entry_key(entry)
		if not seen[key] then
			seen[key] = true
			table.insert(merged, entry)
		end
	end

	local now = os.time()
	for _, raw in ipairs(data.entries or {}) do
		local entry = M._deserialize_entry(raw)
		if entry then
			local key = M._entry_key(entry)
			if not seen[key] then
				local ts = entry.metadata and entry.metadata.time_stamp or 0
				if (now - ts) <= HISTORY_MAX_AGE_SECS then
					seen[key] = true
					table.insert(merged, entry)
				end
			else
				-- Disk duplicate: take max visit_count
				for _, mem_entry in ipairs(merged) do
					if M._entry_key(mem_entry) == key then
						local disk_vc = entry.visit_count or 1
						local mem_vc = mem_entry.visit_count or 1
						mem_entry.visit_count = math.max(disk_vc, mem_vc)
						break
					end
				end
			end
		end
	end

	table.sort(merged, function(a, b)
		local ta = a.metadata and a.metadata.time_stamp or 0
		local tb = b.metadata and b.metadata.time_stamp or 0
		return ta > tb
	end)

	while #merged > M.max_size do
		table.remove(merged)
	end

	-- Merge pins
	local pin_seen = {}
	local merged_pins = {}

	-- In-memory pins take priority
	for _, pin in ipairs(M.pins) do
		local key = M._entry_key(pin)
		if not pin_seen[key] then
			pin_seen[key] = true
			table.insert(merged_pins, pin)
		end
	end

	-- Append disk-only pins
	if data.version == 2 and type(data.pins) == "table" then
		for _, raw in ipairs(data.pins) do
			local pin = M._deserialize_entry(raw)
			if pin then
				local key = M._entry_key(pin)
				if not pin_seen[key] then
					pin_seen[key] = true
					table.insert(merged_pins, pin)
				end
			end
		end
	end

	-- Trim pins to max
	while #merged_pins > M.max_pins do
		table.remove(merged_pins)
	end

	return { entries = merged, pins = merged_pins }
end

--- Saves all history entries to disk as JSON.
--- Merges with existing disk entries to preserve other sessions' history.
function M._save()
	local filepath = M._get_history_filepath()
	local dir = M._get_history_dir()

	-- Ensure directory exists
	vim.fn.mkdir(dir, "p")

	-- Merge with disk for concurrent session support
	local merged = M._merge_with_disk()

	local serialized_entries = {}
	for _, entry in ipairs(merged.entries) do
		local s = M._serialize_entry(entry)
		if s then
			table.insert(serialized_entries, s)
		end
	end

	local serialized_pins = {}
	for _, pin in ipairs(merged.pins) do
		local s = M._serialize_pin(pin)
		if s then
			table.insert(serialized_pins, s)
		end
	end

	local data = {
		version = HISTORY_VERSION,
		project_root = M._get_project_root(),
		entries = serialized_entries,
		pins = serialized_pins,
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

	-- Accept version 1 or 2 (backward compat)
	if data.version ~= 1 and data.version ~= 2 then
		log.warn("History file version mismatch (expected " .. HISTORY_VERSION .. "), starting fresh")
		return
	end

	if type(data.entries) ~= "table" then
		return
	end

	local now = os.time()

	-- Load entries
	local loaded = {}
	for _, raw in ipairs(data.entries) do
		local entry = M._deserialize_entry(raw)
		if entry then
			-- Expiry: skip entries older than 30 days
			local ts = entry.metadata and entry.metadata.time_stamp or 0
			if (now - ts) > HISTORY_MAX_AGE_SECS then
				goto continue_entry
			end

			-- Stale pruning: skip entries for files that no longer exist
			if entry.filepath and entry.filepath ~= "" and vim.fn.filereadable(entry.filepath) == 0 then
				goto continue_entry
			end

			table.insert(loaded, entry)
		end
		::continue_entry::
	end

	while #loaded > M.max_size do
		table.remove(loaded)
	end

	M.entries = loaded

	-- Load pins (version 2 only)
	if data.version == 2 and type(data.pins) == "table" then
		local loaded_pins = {}
		for _, raw in ipairs(data.pins) do
			local pin = M._deserialize_entry(raw)
			if pin then
				-- Stale pruning: skip pins for files that no longer exist
				if pin.filepath and pin.filepath ~= "" and vim.fn.filereadable(pin.filepath) == 0 then
					goto continue_pin
				end

				table.insert(loaded_pins, pin)
			end
			::continue_pin::
		end

		while #loaded_pins > M.max_pins do
			table.remove(loaded_pins)
		end

		M.pins = loaded_pins
	end
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
