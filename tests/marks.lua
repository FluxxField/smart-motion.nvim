-- SmartMotion Playground: Marks Motions
-- Presets: g', gm
--
-- INSTRUCTIONS:
--   g'  → show labels on all marks, jump to selected one
--   gm  → show labels on targets, pick one, type mark name to set mark there
--
-- SETUP:
--   First set some marks to test jumping:
--     ma  — set mark 'a' at current line
--     mb  — set mark 'b' somewhere else
--     mA  — set global mark 'A' (works across files)
--
-- MULTI-WINDOW:
--   :vsplit tests/search.lua
--   Set marks in both files (use A-Z for global marks)
--   Press g' — labels appear on marks in BOTH windows

-- ── Section 1: Set marks here for testing ────────────────────────

local function first_function()
	-- Try: ma here to set mark 'a'
	return "first"
end

local function second_function()
	-- Try: mb here to set mark 'b'
	return "second"
end

local function third_function()
	-- Try: mc here to set mark 'c'
	return "third"
end

-- ── Section 2: Jump to marks with labels ─────────────────────────

-- JUMP TEST:
-- 1. Set marks at the functions above (ma, mb, mc)
-- 2. Go to the bottom of the file
-- 3. Press g' — labels appear on all marks
-- 4. Press a label key to jump to that mark
--
-- Much faster than 'a, 'b, 'c when you have many marks!

local function test_section()
	local x = 1
	local y = 2
	return x + y
end

-- ── Section 3: Set marks remotely with gm ────────────────────────

-- REMOTE MARK TEST:
-- 1. Press gm — labels appear on all words/targets
-- 2. Pick a target by pressing its label
-- 3. Type a mark name (a-z for local, A-Z for global)
-- 4. Mark is set at that location WITHOUT moving your cursor!
--
-- This is great for marking a location you want to return to
-- while keeping your current position.

local function remote_mark_demo()
	-- Try: gm, pick a target below, type 'x' to set mark there
	local alpha = "one"
	local bravo = "two"
	local charlie = "three"
	return alpha .. bravo .. charlie
end

-- ── Section 4: Global marks across files ─────────────────────────

-- GLOBAL MARKS TEST:
-- 1. Open another file: :vsplit tests/search.lua
-- 2. Set global mark A in this file (mA)
-- 3. Set global mark B in the other file (mB)
-- 4. Press g' — labels appear on both A and B
-- 5. Jump between files instantly!
--
-- Global marks (A-Z) work across files.
-- Local marks (a-z) are per-buffer.

local function global_marks_demo()
	-- Set mA here, then set mB in another file
	-- Use g' to see both and jump between them
	return "global marks rock"
end

-- ── Section 5: Operator-pending mode ─────────────────────────────

-- OPERATOR TEST:
-- 1. Set some marks (ma, mb)
-- 2. Place cursor before mark 'a'
-- 3. Press dg' then select mark 'a' — delete from cursor to mark
-- 4. Press yg' then select mark 'b' — yank from cursor to mark
--
-- Works with any vim operator: >, <, gU, gu, =, gq, etc.

local function operator_demo()
	local before_mark = "delete this"
	-- set ma here
	local after_mark = "keep this"
	return before_mark .. after_mark
end
