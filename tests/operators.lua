-- SmartMotion Playground: Operator Motions
-- Presets: d, dt, dT, rdw, rdl, y, yt, yT, ryw, ryl, c, ct, cT, p, P
--          operator-pending: >w, gUw, =j, gqj, etc.
--
-- COMPOSABLE OPERATORS (Motion-Based Inference):
--   d   → composable delete: press d, then a motion key (w/b/e/j/k/s/S/f/F/t/T)
--         The infer system looks up the motion, inherits its pipeline (extractor,
--         filter, visualizer), shows labels, then JUMPS to target and deletes.
--   y   → composable yank: same — jumps to target and yanks
--   c   → composable change: same — jumps to target, deletes, enters insert mode
--   p/P → composable paste: same — jumps to target and pastes after/before
--
--   Key concept: operators compose with ANY registered composable motion.
--   11 composable motions × 5 operators = 55+ auto-inferred compositions.
--   No explicit mappings needed — enable a motion preset and every operator can use it.
--
--   Double-tap: dd/yy/cc act on the current line (like native vim).
--   Repeat motion key: dww = delete word under cursor, yww = yank word under cursor.
--   Unknown keys fall through to native vim: d$/d0/dG work as expected.
--
-- UNTIL MOTIONS:
--   dt  → delete until: type a char, delete from cursor to just before match
--   dT  → delete until backward
--   yt  → yank until: type a char, yank from cursor to just before match
--   yT  → yank until backward
--   ct  → change until: type a char, change from cursor to just before match
--   cT  → change until backward
--
-- REMOTE OPERATIONS (cursor stays in place):
--   rdw → remote delete word: pick a word label anywhere, delete that word
--   rdl → remote delete line: pick a line label, delete that entire line
--   ryw → remote yank word: pick a word label, yank it
--   ryl → remote yank line: pick a line label, yank it
--
-- PASTE:
--   p   → paste after: pick a label, jump there, paste register contents after
--   P   → paste before: pick a label, jump there, paste register contents before
--
-- OPERATOR-PENDING (native vim operators with SmartMotion targets):
--   >w  → indent to word target
--   gUw → uppercase to word target
--   =j  → auto-indent to line target
--   gqj → format to line target

-- ── Section 1: Composable delete with words ─────────────────────

-- Try: dw — labels appear on words after cursor → pick one → cursor jumps there and word is deleted
-- Try: de — labels appear at word ends → pick one → jumps and deletes
-- Try: db — labels appear on words before cursor → pick one → jumps and deletes
-- Try: dww — delete the word under cursor (repeat motion key = quick action)
-- Try: dd — delete the current line (double-tap = line action)

local temporary_variable = "delete me"
local another_temporary = "also delete me"
local keep_this_one = "this should stay"
local expendable_data = "not needed"
local important_value = "do not remove"
local surplus_text = "extra content here"

-- Try: rdw — labels appear on all words, pick one to delete just that word
-- Try: rdl — labels appear on all lines, pick one to delete the entire line

-- ── Section 2: Composable delete/yank with lines ────────────────

-- Try: dj — labels appear on lines below → pick one → jumps and deletes that line
-- Try: dk — labels appear on lines above → pick one → jumps and deletes
-- Try: yj — labels appear on lines below → pick one → jumps and yanks
-- Try: yk — labels appear on lines above → pick one → jumps and yanks
-- Try: djj — delete to current line (repeat motion key)
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

-- First: yank something (yy to yank a line, or yww to yank word under cursor)
-- Then: pw — labels appear on words, pick where to paste AFTER (jumps there)
-- Or:   Pw — labels appear on words, pick where to paste BEFORE (jumps there)
-- Or:   pj — labels appear on lines, pick where to paste AFTER that line

local paste_target_one = "paste something here →  ← or here"
local paste_target_two = "another paste location →  ← fill this in"
local paste_target_three = "one more spot →  ← for pasting"

-- Workflow:
-- 1. Move to "Widget Alpha" line, press yy
-- 2. Press p, pick a label on one of the paste_target lines
-- 3. The yanked line appears after the target

-- ── Section 6: Composable d/y/c with search and treesitter ───

-- Try: ds — live search: type text, labels appear, pick one → jumps and deletes
-- Try: dS — fuzzy search: type partial text, labels on fuzzy matches → deletes
-- Try: df — 2-char find forward: type 2 chars, labels appear → jumps and deletes
-- Try: dF — 2-char find backward
-- Try: ys — yank via live search
-- Try: cs — change via live search
-- Try: d then ]] — delete to a function boundary (treesitter)
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
  table.sort(sorted, function(a, b) return a.price < b.price end)
  return sorted
end

local function sort_by_quantity(items)
  local sorted = {}
  for _, item in ipairs(items) do
    sorted[#sorted + 1] = item
  end
  table.sort(sorted, function(a, b) return a.quantity > b.quantity end)
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
