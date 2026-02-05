# Advanced Features

Deep dive into SmartMotion's advanced capabilities.

---

## Flow State

Flow state makes rapid motion chaining feel native.

### How It Works

1. Trigger a motion (`w`)
2. Select a target
3. Within 300ms, press another motion key (`w`, `b`, `j`, etc.)
4. Labels appear instantly — no animation delay

### Why It Matters

Without flow state, every motion trigger has a small delay while the pipeline runs. In flow state, that delay is eliminated because the system anticipates your next action.

**Result:** Jumping word-to-word-to-word feels as fast as native vim motions.

### Configuration

```lua
flow_state_timeout_ms = 300  -- default
flow_state_timeout_ms = 500  -- more forgiving
flow_state_timeout_ms = 150  -- for speed demons
flow_state_timeout_ms = 0    -- disable
```

### Supported Motions

Flow state works between any registered motions. Common flows:

- `w` → `w` → `w` (hop forward through words)
- `w` → `b` (forward then back)
- `j` → `w` (down to line, then to word)
- `]]` → `]]` (function to function)

---

## Repeat Motion Key (Quick Action)

When using composable operators (`d`, `y`, `c`), pressing the motion key shows labels on all targets. But what if you just want to act on the target under your cursor?

**Repeat the motion key.** The third keystroke being the same as the second means "act here":

```
dww   — delete the word under cursor
yww   — yank the word under cursor
cww   — change the word under cursor
djj   — delete to current line target
```

### Why Not Just Act Instantly?

A naive approach would be to immediately act on the cursor target when you type `dw`. But then you'd never see labels — you couldn't pick a *different* word to delete. By always showing labels first, you get both options:

- **`dw` + label** — delete a specific word anywhere on screen
- **`dww`** — delete the word right here

### How It Works

1. Type `dw` — the pipeline runs, labels appear on all word targets
2. The motion key (`w`) is **excluded from the label pool** — it's reserved for quick action
3. Press `w` again — the target under your cursor is selected and the action runs
4. Or press any label key — that target is selected instead

There's no timeout. You can take as long as you want to read the labels before deciding.

### Works With All Motions

Any single-character motion key works with the repeat pattern:

```
dw + w = delete word here       dw + label = delete word there
dj + j = delete to line here    dj + label = delete to line there
yw + w = yank word here         yw + label = yank word there
cw + w = change word here       cw + label = change word there
```

---

## Operator-Pending Mode

SmartMotion motions work with **any vim operator**.

### Examples

```
>w    — indent from cursor to labeled word
<j    — dedent from cursor to labeled line
gUw   — uppercase from cursor to labeled word
guw   — lowercase from cursor to labeled word
=j    — auto-indent from cursor to labeled line
gqj   — format paragraph from cursor to labeled line
!w    — filter through external command
zf]]  — create fold from cursor to labeled function
```

### How It Works

1. You type an operator (`>`, `gU`, `=`, etc.)
2. Vim enters operator-pending mode
3. You press a SmartMotion key (`w`, `j`, `]]`)
4. Labels appear
5. You select a target
6. Cursor moves to target
7. Operator applies from original cursor to new position

### Which Motions Support It

All **jump-only** motions register in `"o"` mode:

- `w`, `b`, `e`, `ge` (words)
- `j`, `k` (lines)
- `s`, `S`, `f`, `F`, `t`, `T` (search)
- `]]`, `[[`, `]c`, `[c`, `]b`, `[b` (treesitter navigation)
- `]d`, `[d`, `]e`, `[e` (diagnostics)
- `]g`, `[g` (git)
- `]q`, `[q`, `]l`, `[l` (quickfix)
- `g'` (marks)

### Which Motions Don't

SmartMotion's **own operators** and **standalone actions** are not in `"o"` mode:

- `d`, `y`, `c`, `p`, `P` (composable operators)
- `dt`, `yt`, `ct` (until operations)
- `rdw`, `rdl`, `ryw`, `ryl` (remote operations)
- `daa`, `caa`, `yaa`, `dfn`, `cfn`, `yfn` (treesitter editing)
- `saa` (swap)
- `gs` (visual select)
- `gmd`, `gmy` (multi-cursor)
- `gm` (set mark)

These handle their operations internally.

### Special Behaviors

In operator-pending mode:
- **No centering** — `jump_centered` becomes plain `jump`
- **Multi-window disabled** — operators expect same-buffer movement
- **Till motions work** — `dt)` deletes to just before `)`, as expected

---

## Multi-Window

Search, navigation, and diagnostic motions show labels across **all visible windows**.

### How It Works

1. Motion triggers with `multi_window = true`
2. Collector runs for each visible (non-floating) window
3. Each target gets `metadata.winid` and `metadata.bufnr`
4. Current window's targets get label priority (closer = shorter labels)
5. Selecting a target in another window:
   - Switches to that window
   - Moves cursor to target position

### Which Motions Use It

**Enabled by default:**
- `s`, `S`, `f`, `F`, `t`, `T`, `;`, `,`, `gs` (search)
- `]]`, `[[`, `]c`, `[c`, `]b`, `[b` (treesitter navigation)
- `]d`, `[d`, `]e`, `[e` (diagnostics)
- `]g`, `[g` (git)
- `]q`, `[q`, `]l`, `[l` (quickfix)
- `g'`, `gm` (marks)

**Single-window only:**
- `w`, `b`, `e`, `ge` (words) — directional within one buffer
- `j`, `k` (lines) — directional within one buffer

### Directional Filters

Directional filters (`filter_words_after_cursor`, etc.) apply only to the current window. Targets from other windows pass through — they're shown regardless of "direction" since direction is relative to your cursor.

### Custom Motions with Multi-Window

```lua
require("smart-motion").register_motion("<leader>s", {
  collector = "lines",
  extractor = "live_search",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n" },
  metadata = {
    motion_state = {
      multi_window = true,
    },
  },
})
```

---

## Till Motions and Repeat

### Till (`t`/`T`)

Till motions place the cursor **before** the match, not on it.

```
t) — jump to just BEFORE the next )
T( — jump to just AFTER the previous (
```

This is perfect for operations like `dt)` (delete to, but not including, the closing paren).

### Repeat (`;`/`,`)

After any `f`, `F`, `t`, or `T`:

- `;` — repeat same direction, show labels
- `,` — repeat reversed direction, show labels

Unlike native vim, these show **labels** for selection rather than jumping to the next match. You choose which match to go to.

Works across windows when multi-window is enabled.

---

## Native Search Labels

SmartMotion enhances vim's built-in `/` and `?` search.

### How It Works

1. Press `/` and start typing
2. Matches highlight incrementally
3. Labels appear on matches as you type
4. Press Enter — cmdline closes, labels remain
5. Press a label to jump

### Toggle

Press `<C-s>` during search to toggle labels on/off.

### Configuration

```lua
native_search = true   -- enabled (default)
native_search = false  -- disabled
```

### Not Available In

- Operator-pending mode (operators need native search behavior)

---

## Label Conflict Avoidance

In search modes, labels are chosen to avoid ambiguity.

### The Problem

You're searching for "fu". There's a match "fun" in the buffer. If the label is "n", you can't tell if pressing "n" means:
- Select this target (the label)
- Continue typing "fun" (extending search)

### The Solution

SmartMotion excludes characters that could be valid search continuations from the label pool. If the next character after a match is "n", "n" won't be used as a label.

### Where It Applies

- `s` / `S` (live search / fuzzy search)
- `/` / `?` (native search)
- `R` (treesitter search)

---

## Visual Range Selection

`gs` lets you pick two targets and enters visual mode spanning them.

### How It Works

1. Press `gs`
2. Labels appear on all words (across windows)
3. Pick the first target — it highlights
4. Labels re-render for second pick
5. Pick the second target
6. Visual mode activates from first to second

### Ordering

Targets are automatically sorted. If you pick end-before-start, they're swapped.

### Cross-Window

If the first target is in another window, cursor switches to that window before visual mode.

---

## Argument Swap

`saa` swaps two treesitter arguments.

### How It Works

1. Press `saa`
2. Labels appear on all arguments in the buffer
3. Pick the first argument — it highlights
4. Labels re-render for second pick
5. Pick the second argument
6. Text swaps between them

### Implementation Detail

The later position is replaced first to avoid offset corruption.

---

## Multi-Cursor Selection

`gmd` (delete) and `gmy` (yank) provide toggle-based multi-selection.

### How It Works

1. Press `gmd` or `gmy`
2. Labels appear on all words
3. Press labels to **toggle** selection (green highlight)
4. Press more labels to select more
5. Press Enter to confirm, ESC to cancel
6. Action applies to all selected

### For Delete (`gmd`)

Targets are processed bottom-to-top to maintain position stability.

### For Yank (`gmy`)

Selected text is joined with newlines and placed in the `"` register.

### Two-Character Labels

Double-char labels work — press first char, then second to toggle.

---

## Treesitter Incremental Select

`gS` provides node-based expanding/shrinking selection.

### How It Works

1. Press `gS`
2. Smallest named node at cursor is selected (visual mode)
3. Press `;` to expand to parent node
4. Press `,` to shrink to child node
5. Node type shows in echo area: `[3/7] function_declaration`
6. Press Enter to confirm, ESC to cancel

### Use Case

Quickly select increasingly larger code structures without counting or guessing boundaries.

---

## Treesitter Search

`R` searches for text and selects the surrounding syntax node.

### In Normal/Visual Mode

1. Press `R`
2. Type search text
3. Labels appear on nodes containing matches (deduplicated by range)
4. Select a label
5. Node enters visual selection

### In Operator-Pending Mode

Works with any operator:

```
dR → type "error" → select → entire node containing "error" is deleted
yR → type "func" → select → entire node containing "func" is yanked
cR → type "name" → select → node changed, insert mode
```

---

## Scope Motions

`]b` and `[b` jump to control flow and loop boundaries.

### Supported Structures

- **Control flow:** if, switch, match, case, else, elif
- **Loops:** for, while, do, repeat, loop
- **Exception handling:** try, catch, except, finally
- **Blocks/closures:** block, lambda, closure, with, do_block

### Works Across Languages

Uses broad node type lists that match across Lua, Python, JavaScript, TypeScript, Rust, Go, C, C++, Java, Ruby.

### Works in Operator-Pending

```
>]b  — indent to next block
d[b  — delete to previous block
```

---

## Action Composition

Combine actions with `merge`:

```lua
local merge = require("smart-motion.core.utils").action_utils.merge

-- Jump and yank
action = merge({ "jump", "yank" })

-- Jump, delete, center
action = merge({ "jump", "delete", "center" })

-- Yank without moving (yank then restore cursor)
action = merge({ "yank", "restore" })
```

Actions execute in order. This is how SmartMotion builds compound operations without defining every combination.

---

## Next Steps

→ **[Building Custom Motions](Building-Custom-Motions.md)** — Create your own

→ **[Pipeline Architecture](Pipeline-Architecture.md)** — How it works internally

→ **[Configuration](Configuration.md)** — All settings explained
