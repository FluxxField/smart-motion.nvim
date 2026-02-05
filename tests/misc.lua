-- SmartMotion Playground: Misc Motions
-- Presets: . (repeat), gmd (multi-cursor delete), gmy (multi-cursor yank)
--
-- INSTRUCTIONS:
--   .   → repeat the last SmartMotion action
--   gmd → multi-cursor delete: toggle words with labels, Enter to delete all
--   gmy → multi-cursor yank: toggle words with labels, Enter to yank all
--
-- FLOW STATE:
--   After any SmartMotion jump, quickly pressing another motion
--   chains without showing labels (direct jump to next match).

-- ── Section 1: Dot repeat ─────────────────────────────────────

-- REPEAT TEST:
-- 1. Press w, select a word target to jump
-- 2. Press . — should repeat the same motion from new position
-- 3. Press . again — repeats again
--
-- Works with any motion: try with f, s, j, etc.

local apple = "red"
local banana = "yellow"
local cherry = "red"
local date = "brown"
local elderberry = "purple"
local fig = "green"
local grape = "purple"
local honeydew = "green"
local kiwi = "brown"
local lemon = "yellow"
local mango = "orange"
local nectarine = "orange"
local orange = "orange"
local papaya = "yellow"
local quince = "yellow"

-- ── Section 2: Multi-cursor delete (gmd) ─────────────────────

-- MULTI-DELETE TEST:
-- 1. Press gmd — labels appear on all words
-- 2. Press label keys to TOGGLE words (selected words highlight green)
-- 3. Press Enter — all toggled words are deleted
-- 4. Press ESC instead — cancel, nothing changes
--
-- Try deleting several color values below:

local colors = {
	primary = "blue",
	secondary = "green",
	accent = "orange",
	warning = "red",
	info = "cyan",
	success = "green",
	danger = "red",
	muted = "gray",
	highlight = "yellow",
	background = "white",
	foreground = "black",
	border = "silver",
}

local function get_color_by_category(category)
	return colors[category] or "unknown"
end

-- Another good target for gmd — delete some of these status strings:

local statuses = {
	"pending",
	"active",
	"suspended",
	"cancelled",
	"completed",
	"archived",
	"draft",
	"review",
	"approved",
	"rejected",
}

-- ── Section 3: Multi-cursor yank (gmy) ───────────────────────

-- MULTI-YANK TEST:
-- 1. Press gmy — labels appear on all words
-- 2. Press label keys to TOGGLE words (selected words highlight green)
-- 3. Press Enter — all toggled words are yanked into " register
-- 4. Check with :reg " — should show newline-separated words
-- 5. Paste with p to see the result
--
-- Try yanking several names below:

local team = {
	{ name = "Alice", role = "lead", skills = { "lua", "python", "rust" } },
	{ name = "Bob", role = "senior", skills = { "go", "typescript", "lua" } },
	{ name = "Charlie", role = "mid", skills = { "python", "java", "sql" } },
	{ name = "Diana", role = "senior", skills = { "rust", "c", "zig" } },
	{ name = "Eve", role = "junior", skills = { "javascript", "html", "css" } },
	{ name = "Frank", role = "mid", skills = { "kotlin", "swift", "dart" } },
	{ name = "Grace", role = "lead", skills = { "haskell", "ocaml", "elixir" } },
}

local function list_team_skills(members)
	local all_skills = {}
	for _, member in ipairs(members) do
		for _, skill in ipairs(member.skills) do
			if not all_skills[skill] then
				all_skills[skill] = {}
			end
			all_skills[skill][#all_skills[skill] + 1] = member.name
		end
	end
	return all_skills
end

-- Try: gmy, toggle "Alice", "Charlie", "Eve" → Enter
-- Then :reg " should show those three names

-- ── Section 4: Flow state chaining ────────────────────────────

-- FLOW STATE TEST:
-- SmartMotion has a "flow state" — after a motion completes, if you
-- press another motion quickly, it chains without showing labels.
--
-- Test sequence:
-- 1. Press w — labels appear, pick a word
-- 2. Immediately press w again — should jump to next word WITHOUT labels
-- 3. Press w a third time — if still within flow timeout, chains again
-- 4. Wait a moment, then press w — labels appear again (flow state expired)
--
-- Also try:
-- - j then j then j (quick line jumps)
-- - f then ; then ; (char find then repeat chain)
-- - s (search), select, then w (word jump chain)

local function generate_sequence(start, count, step)
	step = step or 1
	local seq = {}
	for i = 0, count - 1 do
		seq[#seq + 1] = start + (i * step)
	end
	return seq
end

local function interleave(a, b)
	local result = {}
	local max = math.max(#a, #b)
	for i = 1, max do
		if a[i] then
			result[#result + 1] = a[i]
		end
		if b[i] then
			result[#result + 1] = b[i]
		end
	end
	return result
end

local function chunk(tbl, size)
	local chunks = {}
	for i = 1, #tbl, size do
		local c = {}
		for j = i, math.min(i + size - 1, #tbl) do
			c[#c + 1] = tbl[j]
		end
		chunks[#chunks + 1] = c
	end
	return chunks
end

local function rotate(tbl, n)
	n = n % #tbl
	local result = {}
	for i = n + 1, #tbl do
		result[#result + 1] = tbl[i]
	end
	for i = 1, n do
		result[#result + 1] = tbl[i]
	end
	return result
end

-- ── Section 5: Combined workflow ──────────────────────────────

-- Full workflow test:
-- 1. Open :vsplit tests/search.lua
-- 2. Press s, type "fun" — labels in both windows
-- 3. Jump to a function in the other window
-- 4. Press gmy, toggle some words, Enter to yank
-- 5. Jump back: press s, type something in this window
-- 6. Press p to paste the yanked words

local evens = generate_sequence(0, 10, 2)
local odds = generate_sequence(1, 10, 2)
local merged = interleave(evens, odds)
local groups = chunk(merged, 4)
local rotated = rotate(merged, 3)

print("Evens: " .. table.concat(evens, ", "))
print("Odds: " .. table.concat(odds, ", "))
print("Merged: " .. table.concat(merged, ", "))
print("Rotated: " .. table.concat(rotated, ", "))
print("Groups:")
for i, group in ipairs(groups) do
	print("  " .. i .. ": " .. table.concat(group, ", "))
end
