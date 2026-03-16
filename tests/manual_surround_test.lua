-- Manual testing file for textobjects, surround, & target expansion
-- Open this file in Neovim with smart-motion loaded:
--   require("smart-motion").setup({ presets = { treesitter = true, surround = true } })
--
-- NOTE: This file intentionally contains invalid Lua (angle brackets, backticks)
-- to verify that the pattern-based fallback works when treesitter can't parse.

-- =============================================================================
-- 1. PAIR TEXT OBJECTS (i/a + delimiter)
--    Works in operator-pending (d/y/c) and visual (v) modes
-- =============================================================================

-- Test: di( → delete inside parens | da( → delete around parens
-- Test: di) → same as di( (closing char alias)
local basic = foo(bar) + baz(qux)
local nested = foo(bar(baz))
local empty = foo() + bar()

-- Test: di[ → delete inside brackets | da[ → delete around brackets
-- Test: di{ → delete inside braces | da{ → delete around braces
-- Test: di< → delete inside angles | da< → delete around angles
local tbl = { key = "value", other = "data" }
local arr = list[1] + list[2]
local ang = Vec<i32>

-- Test: di" → delete inside quotes | da" → delete around quotes
-- Test: di' → delete inside single quotes
-- Test: di` → delete inside backticks
local str = "hello world"
local char = 'single quotes'
local tmpl = `backtick string`

-- Test: vi( → visually select inside parens
-- Test: va{ → visually select around braces
local multi = fn(
  arg1,
  arg2,
  arg3
)

-- =============================================================================
-- 2. TREESITTER TEXT OBJECTS (i/a + f/c/a)
--    Requires treesitter parser for the buffer's language
-- =============================================================================

-- Test: daf → delete around function (entire function including signature)
-- Test: dif → delete inside function (body only)
-- Test: vaf → visually select around function
-- Test: yif → yank inside function
-- Test: cif → change inside function
local function sample_function(x, y)
  local result = x + y
  return result
end

-- Test: dac → delete around class (n/a in Lua, test in TS/Python/etc)
-- Test: dic → delete inside class

-- Test: dia → delete inside argument (just the argument text)
-- Test: daa → delete around argument (includes trailing comma/separator)
-- Test: via → visually select inside argument
local function with_args(first, second, third)
  return first + second + third
end

-- =============================================================================
-- 3. SURROUND DELETE: ds + delimiter
--    Pre-sets textobject_key="surround", reads next char as pair type
-- =============================================================================

-- Test: ds( → delete surrounding parens (leaves content)
-- Test: ds) → same as ds(
local del1 = (delete_these_parens)
local del2 = {delete_these_braces}
local del3 = [delete_these_brackets]
local del4 = "delete_these_quotes"
local del5 = 'delete_single_quotes'
local del6 = <delete_angles>

-- =============================================================================
-- 4. SURROUND CHANGE: cs + delimiter
--    Pre-sets textobject_key="surround", reads next char, prompts for replacement
--    Selected delimiters highlight in blue while waiting for input
-- =============================================================================

-- Test: cs( → change surrounding parens (prompts for new delimiter)
-- Test: cs" → change surrounding quotes
-- Test: cs( then type [ → changes () to []
-- Test: cs( then type { → changes () to { } (opening = padded)
-- Test: cs( then type } → changes () to {} (closing = tight)
local change1 = (change_to_brackets)
local change2 = [change_to_parens]
local change3 = "change_to_single_quotes"

-- =============================================================================
-- 5. SURROUND ADD: ys + i/a + motion + delimiter
--    Reads i/a prefix from user input, then motion target, then delimiter
--    Selected target highlights in blue while waiting for delimiter
-- =============================================================================

-- Test: ysaw( → ys + around + word + ( → wrap word with ( word )
-- Test: ysaw) → ys + around + word + ) → wrap word with (word) (no padding)
-- Test: ysiw" → ys + inside + word + " → wrap word with "word"
-- Test: ysaf( → ys + around + function + ( → wrap function with parens
local add1 = wrap_this_word in parens
local add2 = another_target here too

-- =============================================================================
-- 6. TARGET EXPANSION (+ / -)
--    After picking a target with ys or gza, expand before typing delimiter
-- =============================================================================

-- Test: ysaw → pick "one" → + → + → ( → wraps "( one two three )"
-- Test: ysaw → pick "two" → - → + → ( → wraps "( one two three )"
-- Test: ysaw → pick "one" → + → BS → ( → wraps "( one )" (BS undoes last +)
-- Test: gza → pick "one" → + → + → " → wraps '"one two three"'
-- Test: ysaw → pick "one" → ( → wraps "( one )" (no expansion, just type delimiter)
local one = "target"
local two = "target"
local three = "target"
local four = "target"
local five = "target"

-- Verify dim + appears on next word, dim - on previous word after selection
-- Verify highlights update as you expand
-- Verify ESC cancels the operation
-- Verify BS shrinks the last expansion

-- =============================================================================
-- 7. STANDALONE OPERATIONS
-- =============================================================================

-- Test: gza → show word hints, pick target, type delimiter to wrap
-- Test: gza → pick target → + → + → type delimiter (expansion works here too)
local standalone1 = wrap_this_word
local standalone2 = another_target here

-- Test: gzp → paste surround (yank a pair first with ds, then gzp wraps with stored pair)
local paste1 = paste_surround_here
local paste2 = and_here_too

-- Test: Visual S → select text in visual mode, press S, type delimiter
local vis1 = select this text
local vis2 = wrap multiple words

-- =============================================================================
-- 8. QUOTE ALIAS (q)
--    Matches any quote type: ", ', `
-- =============================================================================

-- Test: dsq → labels on ALL quote pairs (double, single, backtick) → pick one → removed
-- Test: csq → labels on all quotes → pick one → type replacement char
-- Test: diq → delete inside nearest quote (any type)
-- Test: daq → delete around nearest quote (any type)
-- Test: viq → visually select inside nearest quote
-- Test: vaq → visually select around nearest quote
local q1 = "double quoted string"
local q2 = 'single quoted string'
local q3 = `backtick quoted string`
local q_mixed = "double" .. 'single' .. `backtick`

-- =============================================================================
-- 9. HTML/XML TAGS (t)
--    Uses treesitter for HTML/JSX/TSX, pattern fallback for others
-- =============================================================================

-- Test: dst → labels on all tag pairs → pick one → tags removed, content kept
-- Test: cst → labels on tags → pick one → tag name deleted from BOTH opening/closing
--       → cursor enters insert mode in opening tag after < → type new name
--       → closing tag mirrors input in real-time (blue highlight) → ESC when done
--       Example: cst on <div>foo</div> → <|>foo</> → type "span" → <span>foo</span>
-- Test: dit → delete inside tag
-- Test: dat → delete around tag (including tag delimiters)
-- Test: vit → visually select inside tag
-- Test: vat → visually select around tag
-- Test: ysiw t → word labels → pick → prompts "Tag:" → type tag name → wraps
-- Test: Visual S then type t → prompts "Tag:" → wraps selection with tag
local tag1 = "<div>hello world</div>"
local tag2 = "<span>inner text</span>"
local tag3 = "<p>paragraph content</p>"
local tag_nested = "<div><span>nested</span></div>"
local tag_attrs = '<div class="foo">with attributes</div>'
local tag_self = "<br/>"

-- =============================================================================
-- 10. FUNCTION CALLS (f surround)
--     dsf/csf target function CALLS, not definitions
--     dif/daf still work as treesitter function body text objects
-- =============================================================================

-- Test: dsf → labels on function calls → pick one → unwrapped
--       print(foo, bar) → foo, bar
-- Test: csf → labels on calls → pick one → function name deleted
--       → cursor enters insert mode at name position → type new name → ESC
--       Example: csf on console.log(x) → |(x) in insert mode → type "warn" → warn(x)
-- Test: dif → still deletes inside function BODY (treesitter, unchanged)
-- Test: daf → still deletes around function BODY (treesitter, unchanged)
local fc1 = print(foo, bar)
local fc2 = string.format("%s %s", a, b)
local fc3 = math.max(1, 2, 3)
local fc_nested = outer(inner(x))
local fc_method = obj:method(arg)
local fc_chain = foo(bar(baz(1)))

-- =============================================================================
-- 11. COMPOSABLE MOTIONS STILL WORK (no regression)
--     These should NOT be affected by the textobject system
-- =============================================================================

-- Test: f → 2-char find (composable, not a textobject in this context)
-- Test: s → live search
-- Test: w → word jump after cursor
-- Test: b → word jump before cursor
-- Test: e → word end jump
-- Test: dd → delete line (infer: d + d = quick action)
-- Test: yy → yank line
-- Test: dw → delete to word start
-- Test: cw → change to word start

-- =============================================================================
-- 12. TREESITTER NAVIGATION MOTIONS (composable, not textobjects)
-- =============================================================================

-- Test: ]] → jump to next function
-- Test: [[ → jump to previous function
-- Test: ]c → jump to next class
-- Test: [c → jump to previous class
-- Test: ]b → jump to next block/scope
-- Test: [b → jump to previous block/scope
-- Test: fn → select function name (composable, operator-pending only)

local function nav_target_one()
  return 1
end

local function nav_target_two()
  if true then
    for i = 1, 10 do
      print(i)
    end
  end
  return 2
end

local function nav_target_three(a, b, c)
  return a + b + c
end

-- =============================================================================
-- 13. NATIVE VIM FALLBACK
--     Unregistered textobject keys should fall back to native Vim
-- =============================================================================

-- Test: diw → native Vim delete inside word (w not in textobject registry)
-- Test: daw → native Vim delete around word
-- Test: dip → native Vim delete inside paragraph
-- Test: dis → native Vim delete inside sentence
local fallback_word = test_native_fallback
