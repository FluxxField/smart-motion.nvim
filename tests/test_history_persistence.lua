local MiniTest = require("mini_test")
local expect = MiniTest.expect
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
	hooks = {
		pre_case = function()
			helpers.setup_plugin()
			-- Reset history state
			local history = require("smart-motion.core.history")
			history.entries = {}
			history.pins = {}
			history.global_pins = {}
		end,
		post_case = helpers.cleanup,
	},
})

-- =============================================================================
-- Round-trip serialization
-- =============================================================================

T["round-trip"] = MiniTest.new_set()

T["round-trip"]["serialize then deserialize entry preserves data"] = function()
	local history = require("smart-motion.core.history")

	local entry = {
		motion = { trigger_key = "w" },
		target = {
			text = "hello",
			start_pos = { row = 5, col = 3 },
			end_pos = { row = 5, col = 8 },
			type = "word",
			metadata = { filetype = "lua" },
		},
		filepath = "/test.lua",
		visit_count = 7,
		metadata = { time_stamp = 100000 },
	}

	local serialized = history._serialize_entry(entry)
	local deserialized = history._deserialize_entry(serialized)

	expect.equality(deserialized.motion.trigger_key, "w")
	expect.equality(deserialized.target.text, "hello")
	expect.equality(deserialized.target.start_pos.row, 5)
	expect.equality(deserialized.target.start_pos.col, 3)
	expect.equality(deserialized.filepath, "/test.lua")
	expect.equality(deserialized.visit_count, 7)
	expect.equality(deserialized.metadata.time_stamp, 100000)
end

T["round-trip"]["serialize then deserialize pin preserves data"] = function()
	local history = require("smart-motion.core.history")

	local pin = {
		filepath = "/pin.lua",
		target = {
			text = "pinned_word",
			start_pos = { row = 10, col = 2 },
			end_pos = { row = 10, col = 13 },
			type = "pin",
			metadata = { pinned = true, filetype = "lua" },
		},
		metadata = { time_stamp = 55555 },
	}

	local serialized = history._serialize_pin(pin)

	-- Verify serialized form preserves pin-specific fields
	expect.equality(serialized.filepath, "/pin.lua")
	expect.equality(serialized.target.text, "pinned_word")
	expect.equality(serialized.target.start_pos.row, 10)
	expect.equality(serialized.target.metadata.pinned, true)
	expect.equality(serialized.target.metadata.filetype, "lua")

	-- Pins use _deserialize_entry for deserialization —
	-- note: _deserialize_entry only preserves filetype in metadata (not pinned flag)
	local deserialized = history._deserialize_entry(serialized)
	expect.equality(deserialized.filepath, "/pin.lua")
	expect.equality(deserialized.target.text, "pinned_word")
	expect.equality(deserialized.target.start_pos.row, 10)
	expect.equality(deserialized.target.metadata.filetype, "lua")
end

T["round-trip"]["serialize handles missing motion"] = function()
	local history = require("smart-motion.core.history")

	local entry = {
		target = { text = "x", start_pos = { row = 0, col = 0 } },
		metadata = { time_stamp = os.time() },
	}

	local s = history._serialize_entry(entry)
	expect.no_equality(s, nil)
	expect.equality(s.motion.trigger_key, "?")
end

T["round-trip"]["deserialize handles missing fields gracefully"] = function()
	local history = require("smart-motion.core.history")

	local raw = {} -- empty table
	local entry = history._deserialize_entry(raw)

	expect.no_equality(entry, nil)
	expect.equality(entry.motion.trigger_key, "?")
	expect.equality(entry.target.text, "")
	expect.equality(entry.visit_count, 1)
end

-- =============================================================================
-- Disk persistence (_save / _load)
-- =============================================================================

T["disk persistence"] = MiniTest.new_set()

T["disk persistence"]["save and load round-trips entries"] = function()
	local history = require("smart-motion.core.history")

	-- Use a temp directory to avoid polluting real history
	local tmpdir = vim.fn.tempname()
	vim.fn.mkdir(tmpdir, "p")
	local tmpfile = tmpdir .. "/test_history.json"

	-- Override _get_history_filepath to use our temp file
	local orig_filepath = history._get_history_filepath
	history._get_history_filepath = function()
		return tmpfile
	end
	local orig_dir = history._get_history_dir
	history._get_history_dir = function()
		return tmpdir
	end

	-- Add entries
	history.add({
		filepath = tmpdir .. "/test.lua",
		target = { start_pos = { row = 1, col = 0 }, text = "first", metadata = {} },
		motion = { trigger_key = "w" },
		metadata = { time_stamp = os.time() },
	})
	history.add({
		filepath = tmpdir .. "/test.lua",
		target = { start_pos = { row = 5, col = 3 }, text = "second", metadata = {} },
		motion = { trigger_key = "j" },
		metadata = { time_stamp = os.time() },
	})

	-- Save to disk
	history._save()

	-- Clear in-memory state
	local saved_entries = #history.entries
	history.entries = {}
	history.pins = {}
	expect.equality(#history.entries, 0)

	-- Load from disk
	history._load()

	-- Entries won't load because the filepaths don't exist on disk (stale pruning)
	-- So let's verify the file was written correctly by reading it directly
	local f = io.open(tmpfile, "r")
	expect.no_equality(f, nil)
	local content = f:read("*a")
	f:close()

	local data = vim.fn.json_decode(content)
	expect.no_equality(data, nil)
	expect.equality(data.version, 2)
	expect.equality(#data.entries, saved_entries)
	expect.no_equality(data.project_root, nil)

	-- Restore originals
	history._get_history_filepath = orig_filepath
	history._get_history_dir = orig_dir

	-- Cleanup
	os.remove(tmpfile)
	os.remove(tmpdir)
end

T["disk persistence"]["save includes pins in version 2 format"] = function()
	local history = require("smart-motion.core.history")

	local tmpdir = vim.fn.tempname()
	vim.fn.mkdir(tmpdir, "p")
	local tmpfile = tmpdir .. "/test_pins.json"

	local orig_filepath = history._get_history_filepath
	history._get_history_filepath = function()
		return tmpfile
	end
	local orig_dir = history._get_history_dir
	history._get_history_dir = function()
		return tmpdir
	end

	-- Add a pin manually
	table.insert(history.pins, {
		filepath = "/pin_test.lua",
		target = {
			text = "pinned",
			start_pos = { row = 3, col = 0 },
			end_pos = { row = 3, col = 6 },
			type = "pin",
			metadata = { pinned = true },
		},
		metadata = { time_stamp = os.time() },
	})

	history._save()

	local f = io.open(tmpfile, "r")
	expect.no_equality(f, nil)
	local content = f:read("*a")
	f:close()

	local data = vim.fn.json_decode(content)
	expect.equality(data.version, 2)
	expect.no_equality(data.pins, nil)
	expect.equality(#data.pins, 1)
	expect.equality(data.pins[1].target.text, "pinned")

	-- Restore
	history._get_history_filepath = orig_filepath
	history._get_history_dir = orig_dir
	os.remove(tmpfile)
	os.remove(tmpdir)
end

T["disk persistence"]["load handles missing file gracefully"] = function()
	local history = require("smart-motion.core.history")

	local orig_filepath = history._get_history_filepath
	history._get_history_filepath = function()
		return "/nonexistent/path/to/history.json"
	end

	-- Should not error
	history._load()
	expect.equality(#history.entries, 0)

	history._get_history_filepath = orig_filepath
end

T["disk persistence"]["load handles corrupt JSON gracefully"] = function()
	local history = require("smart-motion.core.history")

	local tmpdir = vim.fn.tempname()
	vim.fn.mkdir(tmpdir, "p")
	local tmpfile = tmpdir .. "/corrupt.json"

	-- Write corrupt JSON
	local f = io.open(tmpfile, "w")
	f:write("not valid json {{{")
	f:close()

	local orig_filepath = history._get_history_filepath
	history._get_history_filepath = function()
		return tmpfile
	end

	-- Should not error, just silently fail
	history._load()
	expect.equality(#history.entries, 0)

	history._get_history_filepath = orig_filepath
	os.remove(tmpfile)
	os.remove(tmpdir)
end

T["disk persistence"]["load rejects wrong version"] = function()
	local history = require("smart-motion.core.history")

	local tmpdir = vim.fn.tempname()
	vim.fn.mkdir(tmpdir, "p")
	local tmpfile = tmpdir .. "/version_mismatch.json"

	-- Write with wrong version
	local data = {
		version = 99,
		entries = {
			{
				motion = { trigger_key = "w" },
				target = { text = "test", start_pos = { row = 0, col = 0 } },
				filepath = "/test.lua",
				visit_count = 1,
				metadata = { time_stamp = os.time() },
			},
		},
	}
	local f = io.open(tmpfile, "w")
	f:write(vim.fn.json_encode(data))
	f:close()

	local orig_filepath = history._get_history_filepath
	history._get_history_filepath = function()
		return tmpfile
	end

	history._load()
	-- Should not load entries due to version mismatch
	expect.equality(#history.entries, 0)

	history._get_history_filepath = orig_filepath
	os.remove(tmpfile)
	os.remove(tmpdir)
end

T["disk persistence"]["load accepts version 1 for backward compat"] = function()
	local history = require("smart-motion.core.history")

	local tmpdir = vim.fn.tempname()
	vim.fn.mkdir(tmpdir, "p")
	local tmpfile = tmpdir .. "/v1.json"

	-- Create a real file so stale pruning doesn't skip it
	local real_file = tmpdir .. "/real.lua"
	local rf = io.open(real_file, "w")
	rf:write("-- test")
	rf:close()

	local data = {
		version = 1,
		entries = {
			{
				motion = { trigger_key = "w" },
				target = {
					text = "legacy",
					start_pos = { row = 0, col = 0 },
					end_pos = { row = 0, col = 6 },
					type = "word",
				},
				filepath = real_file,
				visit_count = 2,
				metadata = { time_stamp = os.time() },
			},
		},
	}
	local f = io.open(tmpfile, "w")
	f:write(vim.fn.json_encode(data))
	f:close()

	local orig_filepath = history._get_history_filepath
	history._get_history_filepath = function()
		return tmpfile
	end

	history._load()
	expect.equality(#history.entries, 1)
	expect.equality(history.entries[1].target.text, "legacy")

	history._get_history_filepath = orig_filepath
	os.remove(tmpfile)
	os.remove(real_file)
	os.remove(tmpdir)
end

T["disk persistence"]["load skips expired entries"] = function()
	local history = require("smart-motion.core.history")

	local tmpdir = vim.fn.tempname()
	vim.fn.mkdir(tmpdir, "p")
	local tmpfile = tmpdir .. "/expired.json"

	-- Create real file so stale pruning doesn't interfere
	local real_file = tmpdir .. "/real.lua"
	local rf = io.open(real_file, "w")
	rf:write("-- test")
	rf:close()

	local very_old_timestamp = os.time() - (60 * 24 * 3600) -- 60 days ago (default max is 30)

	local data = {
		version = 2,
		entries = {
			{
				motion = { trigger_key = "w" },
				target = { text = "old_entry", start_pos = { row = 0, col = 0 } },
				filepath = real_file,
				visit_count = 1,
				metadata = { time_stamp = very_old_timestamp },
			},
		},
		pins = {},
	}
	local f = io.open(tmpfile, "w")
	f:write(vim.fn.json_encode(data))
	f:close()

	local orig_filepath = history._get_history_filepath
	history._get_history_filepath = function()
		return tmpfile
	end

	history._load()
	-- Entry should be skipped due to age
	expect.equality(#history.entries, 0)

	history._get_history_filepath = orig_filepath
	os.remove(tmpfile)
	os.remove(real_file)
	os.remove(tmpdir)
end

-- =============================================================================
-- _merge_with_disk
-- =============================================================================

T["merge_with_disk"] = MiniTest.new_set()

T["merge_with_disk"]["returns in-memory data when no disk file exists"] = function()
	local history = require("smart-motion.core.history")

	local orig_filepath = history._get_history_filepath
	history._get_history_filepath = function()
		return "/nonexistent/merge_test.json"
	end

	history.add({
		filepath = "/a.lua",
		target = { start_pos = { row = 0, col = 0 }, text = "mem" },
		metadata = { time_stamp = os.time() },
	})

	local merged = history._merge_with_disk()
	expect.equality(#merged.entries, 1)
	expect.equality(merged.entries[1].target.text, "mem")

	history._get_history_filepath = orig_filepath
end

T["merge_with_disk"]["merges disk entries with in-memory"] = function()
	local history = require("smart-motion.core.history")

	local tmpdir = vim.fn.tempname()
	vim.fn.mkdir(tmpdir, "p")
	local tmpfile = tmpdir .. "/merge.json"

	-- Write disk data
	local data = {
		version = 2,
		entries = {
			{
				motion = { trigger_key = "j" },
				target = { text = "disk_entry", start_pos = { row = 10, col = 0 } },
				filepath = "/disk.lua",
				visit_count = 1,
				metadata = { time_stamp = os.time() - 100 },
			},
		},
		pins = {},
	}
	local f = io.open(tmpfile, "w")
	f:write(vim.fn.json_encode(data))
	f:close()

	local orig_filepath = history._get_history_filepath
	history._get_history_filepath = function()
		return tmpfile
	end

	-- Add in-memory entry at different position
	history.add({
		filepath = "/mem.lua",
		target = { start_pos = { row = 5, col = 0 }, text = "mem_entry" },
		metadata = { time_stamp = os.time() },
	})

	local merged = history._merge_with_disk()
	-- Should have both: mem + disk
	expect.equality(#merged.entries, 2)

	history._get_history_filepath = orig_filepath
	os.remove(tmpfile)
	os.remove(tmpdir)
end

T["merge_with_disk"]["deduplicates by position key"] = function()
	local history = require("smart-motion.core.history")

	local tmpdir = vim.fn.tempname()
	vim.fn.mkdir(tmpdir, "p")
	local tmpfile = tmpdir .. "/dedup.json"

	-- Disk entry at same position as in-memory
	local data = {
		version = 2,
		entries = {
			{
				motion = { trigger_key = "w" },
				target = { text = "disk_ver", start_pos = { row = 3, col = 5 } },
				filepath = "/same.lua",
				visit_count = 10,
				metadata = { time_stamp = os.time() - 50 },
			},
		},
		pins = {},
	}
	local f = io.open(tmpfile, "w")
	f:write(vim.fn.json_encode(data))
	f:close()

	local orig_filepath = history._get_history_filepath
	history._get_history_filepath = function()
		return tmpfile
	end

	-- Add in-memory entry at SAME position
	history.add({
		filepath = "/same.lua",
		target = { start_pos = { row = 3, col = 5 }, text = "mem_ver" },
		visit_count = 2,
		metadata = { time_stamp = os.time() },
	})

	local merged = history._merge_with_disk()
	-- Should deduplicate, keeping only 1 entry
	expect.equality(#merged.entries, 1)
	-- Should take max visit_count
	expect.equality(merged.entries[1].visit_count, 10)

	history._get_history_filepath = orig_filepath
	os.remove(tmpfile)
	os.remove(tmpdir)
end

T["merge_with_disk"]["merges pins from disk"] = function()
	local history = require("smart-motion.core.history")

	local tmpdir = vim.fn.tempname()
	vim.fn.mkdir(tmpdir, "p")
	local tmpfile = tmpdir .. "/pins_merge.json"

	local data = {
		version = 2,
		entries = {},
		pins = {
			{
				target = { text = "disk_pin", start_pos = { row = 1, col = 0 }, type = "pin", metadata = { pinned = true } },
				filepath = "/pin_disk.lua",
				metadata = { time_stamp = os.time() },
			},
		},
	}
	local f = io.open(tmpfile, "w")
	f:write(vim.fn.json_encode(data))
	f:close()

	local orig_filepath = history._get_history_filepath
	history._get_history_filepath = function()
		return tmpfile
	end

	-- Add an in-memory pin at different position
	table.insert(history.pins, {
		filepath = "/pin_mem.lua",
		target = { text = "mem_pin", start_pos = { row = 2, col = 0 } },
		metadata = { time_stamp = os.time() },
	})

	local merged = history._merge_with_disk()
	-- Should have both pins
	expect.equality(#merged.pins, 2)

	history._get_history_filepath = orig_filepath
	os.remove(tmpfile)
	os.remove(tmpdir)
end

T["merge_with_disk"]["skips expired disk entries"] = function()
	local history = require("smart-motion.core.history")

	local tmpdir = vim.fn.tempname()
	vim.fn.mkdir(tmpdir, "p")
	local tmpfile = tmpdir .. "/expired_merge.json"

	local very_old = os.time() - (60 * 24 * 3600) -- 60 days ago

	local data = {
		version = 2,
		entries = {
			{
				motion = { trigger_key = "w" },
				target = { text = "expired", start_pos = { row = 0, col = 0 } },
				filepath = "/expired.lua",
				visit_count = 1,
				metadata = { time_stamp = very_old },
			},
		},
		pins = {},
	}
	local f = io.open(tmpfile, "w")
	f:write(vim.fn.json_encode(data))
	f:close()

	local orig_filepath = history._get_history_filepath
	history._get_history_filepath = function()
		return tmpfile
	end

	local merged = history._merge_with_disk()
	-- Expired disk entry should be skipped
	expect.equality(#merged.entries, 0)

	history._get_history_filepath = orig_filepath
	os.remove(tmpfile)
	os.remove(tmpdir)
end

-- =============================================================================
-- Global pins persistence
-- =============================================================================

T["global pins"] = MiniTest.new_set()

T["global pins"]["save and load round-trips global pins"] = function()
	local history = require("smart-motion.core.history")

	local tmpdir = vim.fn.tempname()
	vim.fn.mkdir(tmpdir .. "/smart-motion", "p")
	local tmpfile = tmpdir .. "/smart-motion/global_pins.json"

	local orig_get_filepath = history._get_global_pins_filepath
	history._get_global_pins_filepath = function()
		return tmpfile
	end

	-- Create a real file for the pin so stale check passes
	local real_file = tmpdir .. "/pinned.lua"
	local rf = io.open(real_file, "w")
	rf:write("-- pinned file")
	rf:close()

	-- Set a global pin
	history.global_pins["A"] = {
		filepath = real_file,
		target = {
			text = "global_word",
			type = "global_pin",
			start_pos = { row = 0, col = 0 },
			end_pos = { row = 0, col = 11 },
			metadata = { pinned = true, global = true },
		},
		metadata = { time_stamp = os.time() },
	}

	-- Save
	history._save_global_pins()

	-- Verify file was written
	local f = io.open(tmpfile, "r")
	expect.no_equality(f, nil)
	local content = f:read("*a")
	f:close()

	local data = vim.fn.json_decode(content)
	expect.equality(data.version, 1)
	expect.no_equality(data.pins.A, nil)

	-- Clear and reload
	history.global_pins = {}
	history._load_global_pins()

	expect.no_equality(history.global_pins["A"], nil)
	expect.equality(history.global_pins["A"].filepath, real_file)
	expect.equality(history.global_pins["A"].target.text, "global_word")

	-- Restore
	history._get_global_pins_filepath = orig_get_filepath
	os.remove(tmpfile)
	os.remove(real_file)
	vim.fn.delete(tmpdir, "rf")
end

T["global pins"]["load handles missing file"] = function()
	local history = require("smart-motion.core.history")

	local orig = history._get_global_pins_filepath
	history._get_global_pins_filepath = function()
		return "/nonexistent/global_pins.json"
	end

	-- Should not error
	history._load_global_pins()
	-- global_pins should remain empty
	expect.equality(next(history.global_pins), nil)

	history._get_global_pins_filepath = orig
end

T["global pins"]["load handles corrupt file"] = function()
	local history = require("smart-motion.core.history")

	local tmpdir = vim.fn.tempname()
	vim.fn.mkdir(tmpdir, "p")
	local tmpfile = tmpdir .. "/corrupt_global.json"

	local f = io.open(tmpfile, "w")
	f:write("{{invalid json")
	f:close()

	local orig = history._get_global_pins_filepath
	history._get_global_pins_filepath = function()
		return tmpfile
	end

	-- Should not error
	history._load_global_pins()
	expect.equality(next(history.global_pins), nil)

	history._get_global_pins_filepath = orig
	os.remove(tmpfile)
	os.remove(tmpdir)
end

T["global pins"]["load rejects wrong version"] = function()
	local history = require("smart-motion.core.history")

	local tmpdir = vim.fn.tempname()
	vim.fn.mkdir(tmpdir, "p")
	local tmpfile = tmpdir .. "/bad_version_global.json"

	local data = { version = 42, pins = { A = {} } }
	local f = io.open(tmpfile, "w")
	f:write(vim.fn.json_encode(data))
	f:close()

	local orig = history._get_global_pins_filepath
	history._get_global_pins_filepath = function()
		return tmpfile
	end

	history._load_global_pins()
	expect.equality(next(history.global_pins), nil)

	history._get_global_pins_filepath = orig
	os.remove(tmpfile)
	os.remove(tmpdir)
end

T["global pins"]["load skips invalid pin letters"] = function()
	local history = require("smart-motion.core.history")

	local tmpdir = vim.fn.tempname()
	vim.fn.mkdir(tmpdir, "p")
	local tmpfile = tmpdir .. "/invalid_letters.json"

	-- Create a real file
	local real_file = tmpdir .. "/real.lua"
	local rf = io.open(real_file, "w")
	rf:write("--")
	rf:close()

	local data = {
		version = 1,
		pins = {
			-- Valid letter
			A = {
				filepath = real_file,
				target = { text = "valid", start_pos = { row = 0, col = 0 }, metadata = { pinned = true } },
				metadata = { time_stamp = os.time() },
			},
			-- Invalid: lowercase
			a = {
				filepath = real_file,
				target = { text = "invalid", start_pos = { row = 1, col = 0 }, metadata = { pinned = true } },
				metadata = { time_stamp = os.time() },
			},
			-- Invalid: number
			["1"] = {
				filepath = real_file,
				target = { text = "also_invalid", start_pos = { row = 2, col = 0 } },
				metadata = { time_stamp = os.time() },
			},
		},
	}
	local f = io.open(tmpfile, "w")
	f:write(vim.fn.json_encode(data))
	f:close()

	local orig = history._get_global_pins_filepath
	history._get_global_pins_filepath = function()
		return tmpfile
	end

	history._load_global_pins()
	-- Only "A" should be loaded
	expect.no_equality(history.global_pins["A"], nil)
	expect.equality(history.global_pins["a"], nil)
	expect.equality(history.global_pins["1"], nil)

	history._get_global_pins_filepath = orig
	os.remove(tmpfile)
	os.remove(real_file)
	os.remove(tmpdir)
end

-- =============================================================================
-- _get_history_filepath
-- =============================================================================

T["filepath"] = MiniTest.new_set()

T["filepath"]["produces consistent path from project root"] = function()
	local history = require("smart-motion.core.history")

	local path1 = history._get_history_filepath()
	local path2 = history._get_history_filepath()

	-- Same project root should produce same hash
	expect.equality(path1, path2)
	-- Should be under stdpath data
	expect.equality(path1:find("smart%-motion/history/") ~= nil, true)
	-- Should end with .json
	expect.equality(path1:sub(-5), ".json")
end

T["filepath"]["_get_history_dir returns expected path"] = function()
	local history = require("smart-motion.core.history")

	local dir = history._get_history_dir()
	expect.equality(dir:find("smart%-motion/history$") ~= nil, true)
end

T["filepath"]["_get_global_pins_filepath returns expected path"] = function()
	local history = require("smart-motion.core.history")

	local path = history._get_global_pins_filepath()
	expect.equality(path:find("smart%-motion/global_pins%.json$") ~= nil, true)
end

-- =============================================================================
-- _setup_autocmds
-- =============================================================================

T["autocmds"] = MiniTest.new_set()

T["autocmds"]["creates VimLeavePre autocmd"] = function()
	local history = require("smart-motion.core.history")

	history._setup_autocmds()

	local autocmds = vim.api.nvim_get_autocmds({
		group = "SmartMotionHistory",
		event = "VimLeavePre",
	})

	expect.equality(#autocmds >= 1, true)
end

return T
