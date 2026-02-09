-- SmartMotion Playground: Operator Motions
-- Presets: d, dt, dT, rdw, rdl, y, yt, yT, ryw, ryl, c, ct, cT, p, P
--          operator-pending: >w, gUw, =j, gqj, etc.
--
-- INSTRUCTIONS:
--   d   → composable delete: press d, then a second motion (w/e/j/k/]]/etc.)
--   y   → composable yank: press y, then a second motion
--   c   → composable change: press c, then a second motion
--   dt  → delete until: type a char, delete from cursor to just before match
--   dT  → delete until backward
--   yt  → yank until: type a char, yank from cursor to just before match
--   yT  → yank until backward
--   ct  → change until: type a char, change from cursor to just before match
--   cT  → change until backward
--   rdw → remote delete word: pick a word label anywhere, delete that word
--   rdl → remote delete line: pick a line label, delete that entire line
--   ryw → remote yank word: pick a word label, yank it
--   ryl → remote yank line: pick a line label, yank it
--   p   → paste after: pick a label, paste register contents after that position
--   P   → paste before: pick a label, paste register contents before that position
--
-- OPERATOR-PENDING:
--   >w  → indent to word target
--   gUw → uppercase to word target
--   =j  → auto-indent to line target
--   gqj → format to line target

-- ── Section 1: Words to delete ────────────────────────────────

-- Try: d then w — delete forward to a word
-- Try: d then e — delete to end of word
-- Try: d then b — delete backward to a word

local temporary_variable = "delete me"
local another_temporary = "also delete me"
local keep_this_one = "this should stay"
local expendable_data = "not needed"
local important_value = "do not remove"
local surplus_text = "extra content here"

-- Try: rdw — labels appear on all words, pick one to delete just that word
-- Try: rdl — labels appear on all lines, pick one to delete the entire line

-- ── Section 2: Lines to delete / yank ─────────────────────────

-- Try: d then j — delete from cursor line down to a target line
-- Try: y then k — yank from a target line up to cursor line
-- Try: rdl — remote delete a specific line without moving cursor

local line_one = "first line of content"
local line_two = "second line of content"
local line_three = "third line of content"
local line_four = "fourth line of content"
local line_five = "fifth line of content"
local line_six = "sixth line of content"
local line_seven = "seventh line of content"
local line_eight = "eighth line of content"

-- ── Section 3: Until motions ──────────────────────────────────

-- Try: dt then type a character — delete from cursor to just before that char
-- Try: yt then type a character — yank from cursor to just before that char
-- Try: ct then type a character — change from cursor to just before that char

local function process_pipeline(input, stages)
	local result = input
	for _, stage in ipairs(stages) do
		result = stage.transform(result)
		if stage.validate then
			local ok, err = stage.validate(result)
			if not ok then
				return nil, "Stage '" .. stage.name .. "' failed: " .. err
			end
		end
	end
	return result
end

-- Place cursor on "local" and try dt( — deletes "local function process_pipeline"
-- Place cursor on "result" and try yt, — yanks "result = input"
-- Place cursor on "for" and try ct. — changes "for _, stage in ipairs(stages) do"

-- ── Section 4: Remote operations ──────────────────────────────

-- Try: rdw — cursor stays put, a remote word is deleted
-- Try: ryw — cursor stays put, a remote word is yanked (check :reg ")
-- Try: rdl — cursor stays put, a remote line is deleted
-- Try: ryl — cursor stays put, a remote line is yanked

local inventory = {
	{ name = "Widget Alpha", quantity = 42, price = 9.99 },
	{ name = "Widget Beta", quantity = 17, price = 14.50 },
	{ name = "Widget Gamma", quantity = 83, price = 7.25 },
	{ name = "Widget Delta", quantity = 5, price = 29.99 },
	{ name = "Widget Epsilon", quantity = 61, price = 3.75 },
	{ name = "Widget Zeta", quantity = 28, price = 19.00 },
}

local function calculate_total(items)
	local total = 0
	for _, item in ipairs(items) do
		total = total + (item.quantity * item.price)
	end
	return total
end

local function find_expensive(items, threshold)
	local expensive = {}
	for _, item in ipairs(items) do
		if item.price > threshold then
			expensive[#expensive + 1] = item
		end
	end
	return expensive
end

-- ── Section 5: Paste operations ───────────────────────────────

-- First: yank something (yy to yank a line, or yw to yank a word)
-- Then: p — labels appear, pick where to paste AFTER
-- Or:   P — labels appear, pick where to paste BEFORE

local paste_target_one = "paste something here →  ← or here"
local paste_target_two = "another paste location →  ← fill this in"
local paste_target_three = "one more spot →  ← for pasting"

-- Workflow:
-- 1. Move to "Widget Alpha" line, press yy
-- 2. Press p, pick a label on one of the paste_target lines
-- 3. The yanked line appears after the target

-- ── Section 6: Composable d/y/c with treesitter ──────────────

-- Try: d then ]] — delete to a function boundary
-- Try: y then [[ — yank to previous function
-- Try: c then w — change to a word target

local function format_item(item)
	return string.format("%-20s qty:%-4d $%.2f", item.name, item.quantity, item.price)
end

local function print_report(items)
	print("=== Inventory Report ===")
	for _, item in ipairs(items) do
		print(format_item(item))
	end
	print("========================")
	print(string.format("Total value: $%.2f", calculate_total(items)))
end

local function sort_by_price(items)
	local sorted = {}
	for _, item in ipairs(items) do
		sorted[#sorted + 1] = item
	end
	table.sort(sorted, function(a, b)
		return a.price < b.price
	end)
	return sorted
end

local function sort_by_quantity(items)
	local sorted = {}
	for _, item in ipairs(items) do
		sorted[#sorted + 1] = item
	end
	table.sort(sorted, function(a, b)
		return a.quantity > b.quantity
	end)
	return sorted
end

-- ── Section 7: Operator-pending mode ──────────────────────────

-- These use Vim's native operators with SmartMotion targets:
--   >w  → press >, then pick a word target — indents from cursor to target
--   gUw → press gU, then pick a word target — uppercases to target
--   =j  → press =, then pick a line target — auto-indents to target line
--   gqj → press gq, then pick a line target — formats to target line

local poorly_indented = "this line needs fixing"
local also_bad = "indentation is wrong here"
local very_wrong = "way off on indentation"
local terrible = "really bad indent"
local flush_left = "no indent at all"

local lowercase_words = "these words should be uppercased"
local more_lowercase = "another line to uppercase"
local mixed_case = "SoMe MiXeD cAsE tExT"

-- Try: position cursor on "local poorly_indented", press =j, pick a line below
-- Try: position cursor on "local lowercase_words", press gUw, pick a word target
