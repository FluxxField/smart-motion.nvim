# Advanced Features

Deep dive into SmartMotion's advanced capabilities.

---

## Flow State

Flow state makes rapid motion chaining feel native.

### How It Works

1. Trigger a motion (`w`)
2. Select a target
3. Within 300ms, press another motion key (`w`, `b`, `j`, etc.)
4. Labels appear instantly, no animation delay

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

When using composable operators (`d`, `y`, `c`), pressing the motion key shows labels on all targets. The operator **jumps to the selected target** and then performs its action. But what if you just want to act on the target under your cursor?

**Repeat the motion key.** The third keystroke being the same as the second means "act here":

```
dww    jump to and delete the word under cursor
yww    jump to and yank the word under cursor
cww    jump to and change the word under cursor
djj    jump to and delete the current line target
```

### Why Not Just Act Instantly?

A naive approach would be to immediately act on the cursor target when you type `dw`. But then you'd never see labels, and you couldn't pick a *different* word to delete. By always showing labels first, you get both options:

- **`dw` + label**: jump to and delete a specific word anywhere on screen
- **`dww`**: jump to and delete the word right here

### How It Works

1. Type `dw`. The infer system reads `w`, looks up the composable `w` motion, inherits its extractor/filter/visualizer, runs the pipeline, and labels appear on all word targets
2. The motion key (`w`) is **excluded from the label pool**. It's reserved for quick action
3. Press `w` again. The target under your cursor is selected, cursor jumps there, and the action runs
4. Or press any label key. That target is selected instead

There's no timeout. You can take as long as you want to read the labels before deciding.

### Works With All Motions

Any single-character composable motion key works with the repeat pattern:

```
dw + w = delete word here       dw + label = delete word there
dj + j = delete to line here    dj + label = delete to line there
yw + w = yank word here         yw + label = yank word there
cw + w = change word here       cw + label = change word there
ds + ... = delete via search    df + .. = delete via 2-char find
```

---

## Operator-Pending Mode

SmartMotion motions work with **any vim operator**.

### Examples

```
>w     indent from cursor to labeled word
<j     dedent from cursor to labeled line
gUw    uppercase from cursor to labeled word
guw    lowercase from cursor to labeled word
=j     auto-indent from cursor to labeled line
gqj    format paragraph from cursor to labeled line
!w     filter through external command
zf]]   create fold from cursor to labeled function
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
- `saa` (swap)
- `gs` (visual select)
- `gmd`, `gmy` (multi-cursor)
- `gm` (set mark)

**Note:** Treesitter text objects (`af`, `if`, `ac`, `ic`, `aa`, `ia`, `fn`) **are** registered in `"o"` mode. They work with any operator via operator-pending composition.

These handle their operations internally.

### Special Behaviors

In operator-pending mode:
- **No centering**: `jump_centered` becomes plain `jump`
- **Multi-window disabled**: operators expect same-buffer movement
- **Till motions work**: `dt)` deletes to just before `)`, as expected
- **`w` is exclusive**: `dw` stops before the first character of the target word, matching native vim. `b`, `e`, and `ge` also match their native equivalents.

### Per-Mode motion_state Overrides

Motions can specify different `motion_state` values for specific modes by using string keys in the `modes` table:

```lua
modes = { "n", "v", o = { exclude_target = true } }
```

Array entries (`"n"`, `"v"`) register the motion normally. String-keyed entries (like `o = { ... }`) register the motion for that mode **and** apply the given fields as a `motion_state` override when that mode is active. This is how the built-in `w` preset achieves native-matching `dw` behavior without affecting normal or visual mode.

You can use any `motion_state` field as an override. Common use cases:

```lua
-- w-style: exclusive in op-pending (don't eat the target's first char)
modes = { "n", "v", o = { exclude_target = true } }

-- disable multi-window in a specific mode
modes = { "n", v = { multi_window = false } }
```

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
- `w`, `b`, `e`, `ge` (words): directional within one buffer
- `j`, `k` (lines): directional within one buffer

### Directional Filters

Directional filters (`filter_words_after_cursor`, etc.) apply only to the current window. Targets from other windows pass through. They're shown regardless of "direction" since direction is relative to your cursor.

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
t)  jump to just BEFORE the next )
T(  jump to just AFTER the previous (
```

This is perfect for operations like `dt)` (delete to, but not including, the closing paren).

### Repeat (`;`/`,`)

After any `f`, `F`, `t`, or `T`:

- `;` - repeat same direction, show labels
- `,` - repeat reversed direction, show labels

Unlike native vim, these show **labels** for selection rather than jumping to the next match. You choose which match to go to.

Works across windows when multi-window is enabled.

---

## Native Search Labels

SmartMotion enhances vim's built-in `/` and `?` search.

### How It Works

1. Press `/` and start typing
2. Matches highlight incrementally
3. Labels appear on matches as you type
4. Press Enter. Cmdline closes, labels remain
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
3. Pick the first target. It highlights
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
3. Pick the first argument. It highlights
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

Double-char labels work. Press first char, then second to toggle.

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

`R` searches for text and lets you select the surrounding syntax node at any level of the tree.

### Two-Phase Selection

Unlike Flash's single-step approach (which labels all ancestor nodes of all matches at once), SmartMotion uses a deliberate two-phase flow:

**Phase 1 - Pick the match:**
1. Press `R` (or `dR`, `yR`, `cR`)
2. Type search text
3. Labels appear on the smallest named node at each match
4. Select a label to choose which match you care about

**Phase 2 - Pick the scope:**
1. Labels appear on all ancestor nodes (identifier → statement → block → function → class, etc.)
2. Select which level of the tree to operate on
3. If there are no ancestors above (already at root), the match target is used directly

### Why Two Phases?

With many matches, Flash's single-step can flood the screen with labels, since every match generates labels for itself AND all its ancestors simultaneously. SmartMotion's approach narrows down first (which match?), then shows a clean set of ancestors (how much to select?).

The end result is identical: the operator applies to the full treesitter node range you select. The path to get there is just more deliberate.

### In Normal/Visual Mode

```
Press R → type "config" → labels on matches → pick one → labels on ancestors → pick scope → visual selection
```

### With Operators (`dR`, `yR`, `cR`)

```
dR → type "error" → pick match → pick ancestor → entire node deleted
yR → type "func" → pick match → pick ancestor → entire node yanked (with highlight flash)
cR → type "name" → pick match → pick ancestor → node deleted, insert mode
```

Cursor moves to the target start, and for yank operations, the full multiline range flashes to confirm what was copied.

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
>]b   indent to next block
d[b   delete to previous block
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

## Motion History

`g.` opens a floating window showing your motion history. But this isn't just a list of recent jumps. It's a full-featured history browser with **pins**, **frecency ranking**, **remote actions**, **navigation**, **preview**, and **search**.

### The Browser

```
 1  *  "authenticate"          auth.lua:42
 2  *  "render"                app.tsx:15
────────────────────────────────────────────────
 f  s   "config"        ████   config.lua:8     just now
 a  dw  "handle_error"  ███    server.lua:30    5m ago
 s  w   "validate"      ██     utils.lua:12     2h ago
────────────────────────────────────────────────
 j/k navigate  /search  d/y/c action  Enter select  Esc cancel
```

Two sections plus a help bar:
- **Pins** (top): your bookmarked locations, numbered `1`-`9`, marked with `*`
- **Entries** (middle): all history, sorted by frecency, with letter labels
- **Help bar** (bottom): contextual hints for available actions

**Note:** `j`, `k`, `d`, `y`, and `c` are reserved keys and won't appear as labels.

### Navigation (`j`/`k`)

Navigate the list with `j` (down) and `k` (up):

- Cursor highlights the current entry
- **Preview window** appears to the side showing ~7 lines of context around the target
- Preview updates as you navigate
- Press `Enter` to jump to the highlighted entry
- Or press a label to jump directly

This gives you two modes:
- **Quick mode**: press a label and you're there instantly
- **Browse mode**: `j`/`k` to explore with preview, `Enter` to confirm

### Search (`/`)

Press `/` to enter search mode:

```
 j/k navigate  /search  d/y/c action  Enter select  Esc cancel
```

becomes:

```
 /config█  Backspace clear  Enter done  Esc cancel
```

- Type to fuzzy-filter entries by target text, filename, or motion key
- List updates live as you type
- Backspace to delete characters
- `Enter` to confirm filter and return to normal mode
- `ESC` to clear filter and cancel

### Pins (`gp`)

Pin any cursor position as a persistent bookmark:

```
gp    toggle pin at cursor location
```

- Press `gp` on a location → "Pinned (1/9)"
- Press `gp` on the same location → "Unpinned"
- Up to 9 pins, persisted across sessions
- Pins show at the top of the history browser with number labels

Pins are your anchors, the places you keep coming back to. Pin your main function, your test file entry point, your config section.

### Frecency Ranking

History entries are ranked by **frecency**, a combination of visit frequency and recency:

```
score = visit_count * decay
```

| Time since last visit | Decay |
|----------------------|-------|
| < 1 hour             | 1.0   |
| < 1 day              | 0.8   |
| < 1 week             | 0.5   |
| Older                | 0.3   |

The more you visit a location, the higher it climbs. The frecency bar (`█` to `████`) shows relative ranking at a glance. Locations you visit repeatedly rise to the top; rarely-visited entries sink.

### Action Mode (`d`/`y`/`c`)

Inside the history browser, press `d`, `y`, or `c` to enter action mode:

1. Press `d`. Title changes to `[D]`
2. Press a label. That entry's text is deleted remotely (without navigating there)
3. The deleted text goes into the `"` register

All three actions:

| Key | Action | What happens |
|-----|--------|--------------|
| `d` | Delete | Text deleted at target, saved to register |
| `y` | Yank   | Text yanked from target into register |
| `c` | Change | Navigates to target, deletes text, enters insert mode |

Actions work **remotely**: `d` and `y` operate on the target's buffer without leaving your current position. The buffer is loaded silently if needed. If the text at the target has changed since it was recorded, you'll see a warning but the action proceeds.

### What Each Entry Shows

- **Label**: number for pins, letter for entries
- **Pin marker**: `*` for pinned locations
- **Motion key**: which motion triggered it (`w`, `dw`, `s`, etc.)
- **Target text**: the text at the target location
- **Frecency bar**: relative ranking indicator (`█` to `████`)
- **File:line**: where the target is
- **Time elapsed**: how long ago (just now, 5m ago, 2h ago, 3d ago)

### Persistent History

History and pins are saved to disk automatically and restored when you reopen Neovim.

- **Storage location:** `~/.local/share/nvim/smart-motion/history/`
- **Per-project:** Each git repo (or working directory) gets its own history file
- **Saved on exit:** `VimLeavePre` autocmd writes history to disk
- **Loaded on startup:** `setup()` loads previous session's history
- **Visit counts persist**: frecency scoring works across sessions

### Deduplication

Jumping to the same location multiple times doesn't fill history with duplicates. When a new entry matches an existing one (same file and position), the old entry is replaced, its `visit_count` is carried forward (and incremented), and the new entry goes to the top.

### Session Merging

Multiple Neovim sessions in the same project merge their history and pins on save. If session A saved entries and session B exits later, B's save merges both. No entries are lost.

- **Entries:** current session takes priority at the same location; `visit_count` takes the max from both
- **Pins:** in-memory pins take priority; disk-only pins are appended; deduped by location

The merged result is trimmed to `history_max_size` for entries and 9 for pins.

### Stale Entry Pruning

Entries and pins pointing to files that no longer exist on disk are automatically removed when history is loaded at startup.

### Entry Expiry

Entries older than 30 days are automatically discarded during load.

### Configuration

```lua
history_max_size = 100  -- default, controls both in-memory and on-disk size
history_max_size = 200  -- keep more history
history_max_size = 0    -- effectively disables persistence (nothing to save)
```

### Navigating to Entries

The history browser handles three cases:
1. **Buffer in a visible window**: switches to that window
2. **Buffer loaded but hidden**: opens it in the current window
3. **Buffer closed**: reopens the file from disk

Jumplist integration: `m'` is saved before navigating, so `<C-o>` takes you back.

### Version Migration

History files are versioned. Version 1 files (before pins and frecency) are loaded seamlessly. `visit_count` defaults to 1 and pins start empty. No manual migration needed.

### Direct Pin Jumps (`g1`-`g9`)

Jump instantly to numbered pins without opening the browser:

```
g1   jump to pin 1
g2   jump to pin 2
...
g9   jump to pin 9
```

Set your frequently-visited files as pins, then access them with pure muscle memory.

### Jump to Most Recent (`g0`)

```
g0   jump to your most recent history entry
```

Quick "go back" to wherever you just were. No browser, no labels, just instant navigation.

### Pin Slot Assignment (`gp1`-`gp9`)

Set the current location as a specific numbered pin:

```
gp3   "Pin 3 set (3/9)", current location becomes pin 3
```

Useful for organizing your pins in a consistent order (e.g., "pin 1 is always my main file, pin 2 is always tests").

### Global Pins (`gP`, `gA`-`gZ`)

Cross-project bookmarks that work anywhere:

```
gP    prompts "Global pin letter (A-Z):"
       type "A" → "Global pin A set"
gA    jumps to global pin A (even from a different project)
gPA   directly sets global pin A at cursor (no prompt)
```

Global pins are stored separately from project-specific history and work across all your Neovim sessions. Use them for:
- Your dotfiles (`.zshrc`, `init.lua`)
- Notes or TODO files
- Frequently-edited configs across projects

26 slots available (A-Z). They persist across sessions and are pruned if the target file no longer exists.

---

## Next Steps

→ **[Building Custom Motions](Building-Custom-Motions.md)**: Create your own

→ **[Pipeline Architecture](Pipeline-Architecture.md)**: How it works internally

→ **[Configuration](Configuration.md)**: All settings explained
