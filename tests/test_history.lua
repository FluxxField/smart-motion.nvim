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
-- _entry_key
-- =============================================================================

T["_entry_key"] = MiniTest.new_set()

T["_entry_key"]["generates key from filepath and position"] = function()
	local history = require("smart-motion.core.history")

	local key = history._entry_key({
		filepath = "/test/file.lua",
		target = { start_pos = { row = 5, col = 10 } },
	})

	expect.equality(key, "/test/file.lua:5:10")
end

T["_entry_key"]["handles missing filepath"] = function()
	local history = require("smart-motion.core.history")

	local key = history._entry_key({
		target = { start_pos = { row = 0, col = 0 } },
	})

	expect.equality(key, ":0:0")
end

T["_entry_key"]["handles missing target"] = function()
	local history = require("smart-motion.core.history")

	local key = history._entry_key({ filepath = "/test.lua" })
	expect.equality(key, "/test.lua:0:0")
end

-- =============================================================================
-- add / last / clear
-- =============================================================================

T["add"] = MiniTest.new_set()

T["add"]["adds entry to front"] = function()
	local history = require("smart-motion.core.history")

	history.add({
		target = { start_pos = { row = 1, col = 0 }, text = "first" },
		metadata = { time_stamp = os.time() },
	})

	local last = history.last()
	expect.no_equality(last, nil)
	expect.equality(last.target.text, "first")
end

T["add"]["deduplicates by position"] = function()
	local history = require("smart-motion.core.history")

	history.add({
		filepath = "/a.lua",
		target = { start_pos = { row = 1, col = 0 }, text = "first" },
		metadata = { time_stamp = os.time() },
	})

	history.add({
		filepath = "/b.lua",
		target = { start_pos = { row = 2, col = 0 }, text = "second" },
		metadata = { time_stamp = os.time() },
	})

	-- Add at same position as first
	history.add({
		filepath = "/a.lua",
		target = { start_pos = { row = 1, col = 0 }, text = "updated first" },
		metadata = { time_stamp = os.time() },
	})

	-- Should have 2 entries (deduped), with updated at front
	expect.equality(#history.entries, 2)
	expect.equality(history.last().target.text, "updated first")
end

T["add"]["consecutive dedup replaces same motion key"] = function()
	local history = require("smart-motion.core.history")

	history.add({
		filepath = "/a.lua",
		target = { start_pos = { row = 1, col = 0 }, text = "first" },
		motion = { trigger_key = "j" },
		metadata = { time_stamp = os.time() },
	})

	history.add({
		filepath = "/a.lua",
		target = { start_pos = { row = 2, col = 0 }, text = "second" },
		motion = { trigger_key = "j" },
		metadata = { time_stamp = os.time() },
	})

	-- Same trigger key consecutively, should replace
	expect.equality(history.last().target.text, "second")
end

T["add"]["increments visit_count on dedup"] = function()
	local history = require("smart-motion.core.history")

	history.add({
		filepath = "/c.lua",
		target = { start_pos = { row = 5, col = 0 }, text = "visit" },
		metadata = { time_stamp = os.time() },
	})

	-- First add: visit_count should be 1
	expect.equality(history.last().visit_count, 1)

	-- Add at same position again
	history.add({
		filepath = "/c.lua",
		target = { start_pos = { row = 5, col = 0 }, text = "visit again" },
		metadata = { time_stamp = os.time() },
	})

	expect.equality(history.last().visit_count, 2)
end

T["add"]["respects max_size"] = function()
	local history = require("smart-motion.core.history")
	local original_max = history.max_size
	history.max_size = 3

	for i = 1, 5 do
		history.add({
			filepath = "/f" .. i .. ".lua",
			target = { start_pos = { row = i, col = 0 }, text = "entry" .. i },
			metadata = { time_stamp = os.time() },
		})
	end

	expect.equality(#history.entries, 3)
	history.max_size = original_max
end

T["clear"] = MiniTest.new_set()

T["clear"]["removes all entries"] = function()
	local history = require("smart-motion.core.history")

	history.add({
		target = { start_pos = { row = 0, col = 0 }, text = "test" },
		metadata = { time_stamp = os.time() },
	})

	history.clear()
	expect.equality(#history.entries, 0)
	expect.equality(history.last(), nil)
end

-- =============================================================================
-- _frecency_score
-- =============================================================================

T["_frecency_score"] = MiniTest.new_set()

T["_frecency_score"]["recent entry scores high"] = function()
	local history = require("smart-motion.core.history")

	local score = history._frecency_score({
		visit_count = 5,
		metadata = { time_stamp = os.time() }, -- just now
	})

	-- decay = 1.0, visit_count * 1.0 = 5
	expect.equality(score, 5.0)
end

T["_frecency_score"]["old entry scores lower"] = function()
	local history = require("smart-motion.core.history")

	local score = history._frecency_score({
		visit_count = 5,
		metadata = { time_stamp = os.time() - 700000 }, -- > 1 week
	})

	-- decay = 0.3, visit_count * 0.3 = 1.5
	expect.equality(score, 1.5)
end

T["_frecency_score"]["defaults visit_count to 1"] = function()
	local history = require("smart-motion.core.history")

	local score = history._frecency_score({
		metadata = { time_stamp = os.time() },
	})

	expect.equality(score, 1.0)
end

-- =============================================================================
-- Serialization
-- =============================================================================

T["serialization"] = MiniTest.new_set()

T["serialization"]["serialize_entry preserves key fields"] = function()
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
		visit_count = 3,
		metadata = { time_stamp = 12345 },
	}

	local s = history._serialize_entry(entry)
	expect.no_equality(s, nil)
	expect.equality(s.motion.trigger_key, "w")
	expect.equality(s.target.text, "hello")
	expect.equality(s.filepath, "/test.lua")
	expect.equality(s.visit_count, 3)
end

T["serialization"]["deserialize_entry reconstructs entry"] = function()
	local history = require("smart-motion.core.history")

	local raw = {
		motion = { trigger_key = "j" },
		target = {
			text = "line",
			start_pos = { row = 2, col = 0 },
			end_pos = { row = 2, col = 4 },
			type = "line",
			metadata = { filetype = "python" },
		},
		filepath = "/test.py",
		visit_count = 2,
		metadata = { time_stamp = 99999 },
	}

	local entry = history._deserialize_entry(raw)
	expect.no_equality(entry, nil)
	expect.equality(entry.motion.trigger_key, "j")
	expect.equality(entry.target.text, "line")
	expect.equality(entry.filepath, "/test.py")
	expect.equality(entry.visit_count, 2)
end

T["serialization"]["serialize_pin preserves pin fields"] = function()
	local history = require("smart-motion.core.history")

	local pin = {
		filepath = "/pin.lua",
		target = {
			text = "pinned",
			start_pos = { row = 10, col = 2 },
			end_pos = { row = 10, col = 8 },
			type = "pin",
			metadata = { pinned = true, filetype = "lua" },
		},
		metadata = { time_stamp = 55555 },
	}

	local s = history._serialize_pin(pin)
	expect.no_equality(s, nil)
	expect.equality(s.filepath, "/pin.lua")
	expect.equality(s.target.text, "pinned")
	expect.equality(s.target.metadata.pinned, true)
end

-- =============================================================================
-- get_pin
-- =============================================================================

T["get_pin"] = MiniTest.new_set()

T["get_pin"]["returns nil for invalid index"] = function()
	local history = require("smart-motion.core.history")

	expect.equality(history.get_pin(0), nil)
	expect.equality(history.get_pin(1), nil) -- no pins
	expect.equality(history.get_pin(-1), nil)
end

T["get_pin"]["returns pin at valid index"] = function()
	local history = require("smart-motion.core.history")

	table.insert(history.pins, {
		filepath = "/test.lua",
		target = { text = "pin1", start_pos = { row = 0, col = 0 } },
	})

	local pin = history.get_pin(1)
	expect.no_equality(pin, nil)
	expect.equality(pin.target.text, "pin1")
end

-- =============================================================================
-- setup
-- =============================================================================

T["setup"] = MiniTest.new_set()

T["setup"]["applies config overrides"] = function()
	local history = require("smart-motion.core.history")
	local original_max = history.max_size
	local original_pins = history.max_pins

	history.setup({ history_max_size = 50, max_pins = 5 })

	expect.equality(history.max_size, 50)
	expect.equality(history.max_pins, 5)

	history.max_size = original_max
	history.max_pins = original_pins
end

return T
