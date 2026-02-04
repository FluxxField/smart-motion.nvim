-- SmartMotion Playground: Git Motions
-- Presets: ]g, [g
--
-- INSTRUCTIONS:
--   ]g → jump to next git hunk (changed region) after cursor
--   [g → jump to previous git hunk before cursor
--
-- SETUP:
--   This file needs to be in a git repository with uncommitted changes
--   to see hunks. Make some edits and don't commit them.
--
-- MULTI-WINDOW:
--   :vsplit another_file.lua
--   Press ]g — labels should appear on hunks in BOTH windows
--
-- GITSIGNS INTEGRATION:
--   If you have gitsigns.nvim installed, SmartMotion uses its API
--   for accurate hunk detection. Otherwise falls back to git diff.

-- ── Section 1: Make changes here to create hunks ─────────────────

local function example_function()
	-- Edit this line or add new lines to create a git hunk
	-- Then press ]g or [g to jump between hunks
	return "original content"
end

local config = {
	enabled = true,
	timeout = 5000,
	-- Add or remove fields to create hunks
}

-- ── Section 2: Another section for more hunks ────────────────────

local function another_function(param)
	-- Modify this function to create another hunk
	local result = param * 2
	return result
end

-- Add new functions here to create insertion hunks

-- ── Section 3: Testing workflow ──────────────────────────────────

-- WORKFLOW TEST:
-- 1. Make a change somewhere in this file (add a line, modify text)
-- 2. Press ]g from the top — labels appear on all hunks below cursor
-- 3. Press a label key to jump to that hunk
-- 4. Press [g to go back to previous hunks
--
-- TIP: Works great with gitsigns.nvim preview_hunk and reset_hunk

local function test_workflow()
	-- Change this
	local x = 1
	local y = 2
	return x + y
end

-- ── Section 4: Hunk types ────────────────────────────────────────

-- Git tracks three types of changes:
-- 1. Added lines (new content)
-- 2. Removed lines (deleted content, shown at deletion point)
-- 3. Changed lines (modified content)
--
-- SmartMotion shows labels on all hunk types.
-- The metadata includes hunk_type: "add", "delete", or "change"

-- Try:
-- 1. Add a new function below this comment → creates "add" hunk
-- 2. Delete the comment above → creates "delete" hunk
-- 3. Modify existing code → creates "change" hunk

local function final_example()
	return "test"
end
