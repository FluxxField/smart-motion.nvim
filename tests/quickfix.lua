-- SmartMotion Playground: Quickfix Motions
-- Presets: ]q, [q, ]l, [l
--
-- INSTRUCTIONS:
--   ]q → jump to next quickfix entry after cursor
--   [q → jump to previous quickfix entry before cursor
--   ]l → jump to next location list entry after cursor
--   [l → jump to previous location list entry before cursor
--
-- SETUP:
--   Quickfix list needs to be populated first. Try one of these:
--     :vimgrep /function/ %     — search for "function" in current file
--     :make                      — run make and populate with errors
--     :grep pattern **/*.lua     — search across files
--     :cexpr system('...')       — populate from command output
--
-- LOCATION LIST:
--   Location list is window-local (each window can have its own).
--   Populate it with:
--     :lvimgrep /pattern/ %
--     :lmake
--     :lgrep pattern files

-- ── Section 1: Functions to create quickfix entries ──────────────

local function example_function_one()
	-- This function will match vimgrep /function/
	return "one"
end

local function example_function_two()
	-- Another function to match
	return "two"
end

local function example_function_three()
	-- And another
	return "three"
end

-- ── Section 2: Try it out ────────────────────────────────────────

-- WORKFLOW TEST:
-- 1. Run :vimgrep /function/ % to populate quickfix
-- 2. Press ]q — labels appear on all quickfix entries below cursor
-- 3. Select a label to jump to that entry
-- 4. Press [q to see entries above cursor
--
-- The quickfix window (:copen) shows all entries, but you don't
-- need it open — SmartMotion labels work directly in the buffer.

local function test_quickfix_workflow()
	local x = 1
	local y = 2
	return x + y
end

-- ── Section 3: Location list test ────────────────────────────────

-- LOCATION LIST TEST:
-- 1. Run :lvimgrep /local/ % to populate location list
-- 2. Press ]l — labels appear on location list entries
-- 3. Press [l to go backward
--
-- Note: Location list is per-window, so different windows can have
-- different location lists.

local function location_list_demo()
	local alpha = "a"
	local bravo = "b"
	local charlie = "c"
	return alpha .. bravo .. charlie
end

-- ── Section 4: Multi-window ──────────────────────────────────────

-- MULTI-WINDOW TEST:
-- 1. :vsplit tests/search.lua
-- 2. Run :vimgrep /function/ tests/*.lua (searches multiple files)
-- 3. Press ]q — labels appear on entries in BOTH windows
-- 4. Select a label in the other window to jump there

local function another_function()
	return "test"
end

local function final_function()
	return "done"
end

-- ── Section 5: Operator-pending mode ─────────────────────────────

-- OPERATOR TEST:
-- 1. Populate quickfix with :vimgrep /function/ %
-- 2. Place cursor at top
-- 3. Press d]q — delete from cursor to next quickfix entry
-- 4. Press y]q — yank from cursor to next quickfix entry

-- Works with any vim operator: >, <, gU, gu, =, gq, etc.
