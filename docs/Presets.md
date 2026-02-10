# Presets Guide

SmartMotion ships with **13 presets** containing **140+ keybindings**. Each preset is a logical group of related motions. Enable what you need, disable what you don't.

> **Every preset can be customized.** Want to make `f` single-char? Words bidirectional? Search line-constrained? See the [Recipes](Recipes.md) guide for practical examples.

---

## Quick Reference

| Preset | Keys | Description |
|--------|------|-------------|
| `words` | `w` `b` `e` `ge` | Word navigation |
| `lines` | `j` `k` | Line navigation |
| `search` | `s` `S` `f` `F` `t` `T` `;` `,` `gs` | Search and find |
| `delete` | `d` `dt` `dT` `rdw` `rdl` | Delete operations |
| `yank` | `y` `yt` `yT` `ryw` `ryl` | Yank operations |
| `change` | `c` `ct` `cT` | Change operations |
| `paste` | `p` `P` | Paste operations |
| `treesitter` | `]]` `[[` `]c` `[c` `]b` `[b` `af` `if` `ac` `ic` `aa` `ia` `fn` `saa` `gS` `R` | Syntax-aware motions |
| `diagnostics` | `]d` `[d` `]e` `[e` | LSP diagnostic navigation |
| `git` | `]g` `[g` | Git hunk navigation |
| `quickfix` | `]q` `[q` `]l` `[l` | Quickfix/location list |
| `marks` | `g'` `gm` | Mark navigation and setting |
| `misc` | `.` `g.` `g0` `g1`-`g9` `gp` `gp1`-`gp9` `gP` `gA`-`gZ` `gmd` `gmy` | Repeat, history, pins, global pins, and multi-cursor |

---

## words

Navigate by words with home-row hints.

| Key | Modes | What it does |
|-----|-------|--------------|
| `w` | n, v, o | Jump to **start** of word **after** cursor |
| `b` | n, v, o | Jump to **start** of word **before** cursor |
| `e` | n, v, o | Jump to **end** of word **after** cursor |
| `ge` | n, v, o | Jump to **end** of word **before** cursor |

**Example workflow:**
```
Press w → labels appear on all words ahead → press 'f' → cursor jumps to that word
```

**Works with operators:**
```
>w     indent from cursor to labeled word
gUw    uppercase from cursor to labeled word
```

---

## lines

Navigate by lines.

| Key | Modes | What it does |
|-----|-------|--------------|
| `j` | n, v, o | Jump to line **after** cursor |
| `k` | n, v, o | Jump to line **before** cursor |

**Example workflow:**
```
Press j → labels appear on lines below → press 'a' → cursor jumps to that line
```

**Works with operators:**
```
=j     auto-indent from cursor to labeled line
gqj    format from cursor to labeled line
```

**Count prefix support:**
```
5j     jumps to the 5th line target below (no labels shown)
3k     jumps to the 3rd line target above
```

When a count precedes `j` or `k`, SmartMotion skips the label step and auto-selects the Nth target. This can be changed to native vim behavior via `count_behavior = "native"` in config. See **[Configuration](Configuration.md#count-behavior)**.

---

## search

Powerful search with multiple modes.

| Key | Modes | Multi-window | What it does |
|-----|-------|--------------|--------------|
| `s` | n, o | Yes | **Live search**: labels update as you type |
| `S` | n, o | Yes | **Fuzzy search**: type "fn" to match "function" |
| `f` | n, o | Yes | **2-char find** forward (like leap) |
| `F` | n, o | Yes | **2-char find** backward |
| `t` | n, o | Yes | **Till** character forward (cursor lands before match) |
| `T` | n, o | Yes | **Till** character backward (cursor lands after match) |
| `;` | n, v | Yes | **Repeat** last f/F/t/T (same direction) |
| `,` | n, v | Yes | **Repeat** last f/F/t/T (reversed direction) |
| `gs` | n | Yes | **Visual select**: pick two targets, enter visual mode |

### Live Search (`s`)

```
Press s → type "func" → labels appear on all "func" matches → press label → jump
```

Labels update in real-time. Backspace works. Press ESC to cancel.

### Fuzzy Search (`S`)

```
Press S → type "fn" → labels appear on "function", "filename", "find", etc.
```

Fuzzy matching uses word boundaries, camelCase, and consecutive character scoring.

### 2-Char Find (`f`/`F`)

```
Press f → type "th" → labels appear on all "th" matches ahead → press label → jump
```

Like leap.nvim's 2-character search.

### Till (`t`/`T`)

```
Press t → type ")" → cursor lands just BEFORE the ")" → perfect for dt)
```

### Visual Select (`gs`)

```
Press gs → pick first word → pick second word → visual selection spans the range
```

Great for selecting arbitrary ranges without counting.

### Label Conflict Avoidance

When searching, labels are chosen to avoid ambiguity. If you're searching for "fu" and there's a match followed by "n", the label won't be "n", because that could be continuing your search.

---

## delete

Delete operations with visual feedback.

| Key | Modes | What it does |
|-----|-------|--------------|
| `d` | n | **Composable delete**: press `d` then any composable motion (jumps to target, deletes) |
| `dt` | n | Delete from cursor **until** character (forward) |
| `dT` | n | Delete from cursor **until** character (backward) |
| `rdw` | n | **Remote delete word**: delete a word without moving cursor |
| `rdl` | n | **Remote delete line**: delete a line without moving cursor |

### Composable Delete (`d`)

```
Press d → press w → labels appear on words → select target → cursor jumps there, word deleted
Press d → press ]] → labels appear on functions → select one → cursor jumps there, deleted
Press d → press s → live search → type text → labels appear → select → jump and delete
```

Works with ANY composable SmartMotion motion (`w`, `b`, `e`, `j`, `k`, `s`, `S`, `f`, `F`, `t`, `T`). Unknown keys fall through to native vim (`d$`, `d0`, `dG` work as expected).

### Repeat Motion Key (Quick Action)

When labels appear, pressing the motion key **again** acts on the target under your cursor:

```
dww    delete the word under the cursor (repeat 'w')
djj    delete to the current line target (repeat 'j')
d]]]]  delete to the function at cursor (repeat ']]')
```

This gives you the best of both worlds: `dw` shows labels so you can pick any target, but `dww` is a fast shortcut for the common case of acting right where you are. The motion key is excluded from the label pool so there's never ambiguity.

### Delete Until (`dt`/`dT`)

```
Press dt → type ")" → deletes from cursor to just before ")"
```

Like native `dt)` but with labels when multiple matches exist.

### Remote Delete (`rdw`/`rdl`)

```
Press rdw → labels appear on words → select one → that word is deleted, cursor stays put
Press rdl → labels appear on lines → select one → that line is deleted, cursor stays put
```

Edit code without losing your place.

---

## yank

Yank (copy) operations.

| Key | Modes | What it does |
|-----|-------|--------------|
| `y` | n | **Composable yank**: press `y` then any composable motion (jumps to target, yanks) |
| `yt` | n | Yank from cursor **until** character (forward) |
| `yT` | n | Yank from cursor **until** character (backward) |
| `ryw` | n | **Remote yank word**: yank a word without moving cursor |
| `ryl` | n | **Remote yank line**: yank a line without moving cursor |

Same patterns as delete, but yanks to register instead. Cursor jumps to the target.

Repeat motion key works here too: `yww` yanks the word under cursor, `yw` + label yanks a specific word.

---

## change

Change (delete + insert) operations.

| Key | Modes | What it does |
|-----|-------|--------------|
| `c` | n | **Composable change**: press `c` then any composable motion (jumps to target, deletes, enters insert) |
| `ct` | n | Change from cursor **until** character (forward) |
| `cT` | n | Change from cursor **until** character (backward) |

```
Press c → press w → labels appear → select target → cursor jumps there, text deleted, insert mode
```

Repeat motion key works here too: `cww` changes the word under cursor, `cw` + label changes a specific word.

---

## paste

Paste at target location.

| Key | Modes | What it does |
|-----|-------|--------------|
| `p` | n | **Paste after**: press `p` then a motion, jump to target, paste after it |
| `P` | n | **Paste before**: press `P` then a motion, jump to target, paste before it |

```
Yank some text → press pw → select a word target → cursor jumps there, yanked text pastes after
```

---

## treesitter

Syntax-aware navigation and editing. Works across Lua, Python, JavaScript, TypeScript, Rust, Go, C, C++, Java, C#, Ruby, and more.

### Navigation

| Key | Modes | Multi-window | What it does |
|-----|-------|--------------|--------------|
| `]]` | n, o | Yes | Jump to next **function** |
| `[[` | n, o | Yes | Jump to previous **function** |
| `]c` | n, o | Yes | Jump to next **class/struct** |
| `[c` | n, o | Yes | Jump to previous **class/struct** |
| `]b` | n, o | Yes | Jump to next **block/scope** (if, for, while, try) |
| `[b` | n, o | Yes | Jump to previous **block/scope** |

```
Press ]] → labels appear on all function definitions → select one → jump there
Works in operator-pending: >]] indents to labeled function
```

### Text Objects

| Key | Modes | What it does |
|-----|-------|--------------|
| `af` | x, o | **Around function**: select entire function (works with any operator: `daf`, `yaf`, `gqaf`) |
| `if` | x, o | **Inside function**: select function body only |
| `ac` | x, o | **Around class/struct**: select entire class |
| `ic` | x, o | **Inside class/struct**: select class body only |
| `aa` | x, o | **Around argument**: includes comma/separator |
| `ia` | x, o | **Inside argument**: argument text only |
| `fn` | o | **Function name**: select function name (works with operators: `dfn`, `cfn`, `yfn`) |
| `saa` | n | **Swap arguments**: pick two, swap positions |

```
In: calculate(first, second, third)
Press daa → labels appear on arguments → select "second" → becomes: calculate(first, third)
Press vaf → labels appear on functions → select one → entire function visually selected
Press daf → labels appear on functions → select one → entire function deleted
Press cfn → labels appear on function names → select one → name deleted, insert mode
Press gqaf → labels appear on functions → select one → function formatted
```

Text objects compose with **any vim operator** automatically. No explicit mappings needed. `daf`, `yaf`, `cif`, `>af`, `=if`, `gqaf` all work out of the box.

**Multi-char infer (`fn`):** When you type `dfn` quickly, the infer system resolves `fn` as a function name motion. If you type `df` and pause (up to `timeoutlen`), it falls through to find-char. This timeout-based resolution avoids conflicts between `f` (find-char) and `fn` (function name).

### Selection

| Key | Modes | What it does |
|-----|-------|--------------|
| `gS` | n, x | **Incremental select**: `;` expands to parent, `,` shrinks to child |
| `R` | n, x, o | **Treesitter search**: search text, pick match, pick ancestor scope |

```
Press gS → smallest node at cursor selected → press ; → expands to parent node → etc.
Shows node type in echo area. Enter confirms, ESC cancels.

Press R → type "error" → labels on matches → pick match → labels on ancestors → pick scope
Press dR → type "error" → pick match → pick ancestor → entire node deleted
Press yR → type "func" → pick match → pick ancestor → entire node yanked (with highlight flash)
```

**Two-phase selection:** SmartMotion's approach differs from Flash. Instead of labeling all ancestor nodes of all matches at once (which can flood the screen), you first pick which match location you care about, then pick how much of the syntax tree to select. See **[Advanced Features: Treesitter Search](Advanced-Features.md#treesitter-search)** for details.

---

## diagnostics

Navigate LSP diagnostics with labels.

| Key | Modes | Multi-window | What it does |
|-----|-------|--------------|--------------|
| `]d` | n, o | Yes | Jump to next **diagnostic** (any severity) |
| `[d` | n, o | Yes | Jump to previous **diagnostic** |
| `]e` | n, o | Yes | Jump to next **error** only |
| `[e` | n, o | Yes | Jump to previous **error** only |

```
Press ]d → labels appear on all diagnostics ahead → select one → jump there
Press ]e → only errors shown
```

---

## git

Navigate git changed regions. Works best with [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim).

| Key | Modes | Multi-window | What it does |
|-----|-------|--------------|--------------|
| `]g` | n, o | Yes | Jump to next **git hunk** (changed region) |
| `[g` | n, o | Yes | Jump to previous **git hunk** |

```
Press ]g → labels appear on all changed regions → select one → jump there
```

Without gitsigns, falls back to parsing `git diff` output directly.

---

## quickfix

Navigate quickfix and location list entries.

| Key | Modes | Multi-window | What it does |
|-----|-------|--------------|--------------|
| `]q` | n, o | Yes | Jump to next **quickfix entry** |
| `[q` | n, o | Yes | Jump to previous **quickfix entry** |
| `]l` | n, o | Yes | Jump to next **location list entry** |
| `[l` | n, o | Yes | Jump to previous **location list entry** |

Quickfix entries come from `:vimgrep`, `:make`, `:grep`, LSP, etc.

```
:vimgrep /TODO/ **/*.lua
Press ]q → labels appear on all TODO matches → select one → jump there
```

---

## marks

Jump to marks or set marks remotely.

| Key | Modes | Multi-window | What it does |
|-----|-------|--------------|--------------|
| `g'` | n, o | Yes | Show labels on all **marks**, jump to selected |
| `gm` | n | Yes | **Set mark** at labeled target (prompts for mark name) |

```
Press g' → labels appear on all marks (a-z local, A-Z global) → select one → jump there

Press gm → labels appear on words → select target → type 'a' → mark 'a' set at that location
```

---

## misc

Repeat, history, pins, and multi-cursor operations.

| Key | Modes | What it does |
|-----|-------|--------------|
| `.` | n | **Repeat** last SmartMotion |
| `g.` | n | **History browser**: browse pins and past targets with frecency ranking and action mode |
| `g0` | n | **Jump to most recent**: instant jump to your last location |
| `g1`-`g9` | n | **Direct pin jump**: jump to pin N without opening browser |
| `gp` | n | **Toggle pin**: bookmark/unbookmark the current cursor position |
| `gp1`-`gp9` | n | **Set pin at slot**: set current location as pin N |
| `gP` | n | **Toggle global pin**: cross-project bookmark (prompts A-Z) |
| `gA`-`gZ` | n | **Jump to global pin**: jump to cross-project pin (`gP`/`gS` reserved) |
| `gPA`-`gPZ` | n | **Set global pin**: set current location as global pin |
| `gmd` | n | **Multi-cursor delete**: toggle-select multiple words, delete all |
| `gmy` | n | **Multi-cursor yank**: toggle-select multiple words, yank all |

### History Browser (`g.`)

```
Press g. → floating window with pins at top, frecency-ranked entries below, help bar at bottom
→ j/k to navigate with live preview
→ / to search/filter entries
→ press number (1-9) to jump to a pin
→ press letter label to jump to an entry
→ d/y/c to enter action mode, then press label to act on that target remotely
→ Enter to select highlighted entry, Esc to cancel
```

The browser shows:
- **Pins** (numbered `1`-`9` with `*` marker)
- **Entries** (letter labels, sorted by frecency with `█` bar indicators)
- **Help bar** (contextual hints that update based on mode)
- **Preview window** (appears when navigating with `j`/`k`, shows context around target)

**Navigation:** Use `j`/`k` to move through entries with a live preview window showing ~7 lines of context. Press `Enter` to jump to the highlighted entry.

**Search:** Press `/` to filter entries by target text, filename, or motion key. The list updates live as you type.

**Action mode:** Press `d`, `y`, or `c`. The title changes to `[D]`/`[Y]`/`[C]`, then press a label to delete, yank, or change that target without navigating there.

History persists across Neovim sessions. Visit counts accumulate over time, pushing frequently-visited locations to the top. See **[Advanced Features: Motion History](Advanced-Features.md#motion-history)** for full details.

### Direct Pin Jumps (`g1`-`g9`)

```
gp at location A → "Pinned (1/9)"
gp at location B → "Pinned (2/9)"
g1 → instantly jumps to location A
g2 → instantly jumps to location B
```

Jump directly to numbered pins without opening the browser. Pure muscle memory.

### Jump to Most Recent (`g0`)

```
Navigate around, use motions...
g0 → instantly jump back to your most recent location
```

Quick "go back" without opening the history browser.

### Pins (`gp`)

```
Press gp → "Pinned (1/9)", current location bookmarked
Press gp again at same spot → "Unpinned"
```

Up to 9 pins. Pins persist across sessions and appear at the top of the history browser with number labels for instant access.

### Pin Slot Assignment (`gp1`-`gp9`)

```
gp3 → "Pin 3 set (3/9)", current location becomes pin 3
```

Set current location at a specific pin slot, replacing any existing pin there. Useful for organizing your pins in a consistent order.

### Global Pins (`gP`, `gA`-`gZ`)

Cross-project bookmarks that work across all your projects.

```
gP → prompts "Global pin letter (A-Z):" → type "A" → "Global pin A set"
gA → jumps to global pin A (even if it's in a different project)
gPA → directly sets global pin A at cursor (no prompt)
```

Global pins are stored separately from project pins and persist across all Neovim sessions. Use them for frequently-accessed files like your dotfiles, notes, or commonly-edited configs.

**Note:** `gP` (toggle global pin) and `gS` (treesitter incremental select) are reserved. Use `gPA`-`gPZ` to set/access pins at those slots, or use the history browser.

### Multi-Cursor (`gmd`/`gmy`)

```
Press gmd → labels appear on all words → press labels to TOGGLE selection (turns green)
→ press more labels to select more → press Enter → all selected words deleted
```

Selection is toggle-based: press a label once to select, again to deselect. ESC cancels.

---

## Configuring Presets

### Enable All

```lua
presets = {
  words = true,
  lines = true,
  search = true,
  delete = true,
  yank = true,
  change = true,
  paste = true,
  treesitter = true,
  diagnostics = true,
  git = true,
  quickfix = true,
  marks = true,
  misc = true,
}
```

### Enable Selectively

```lua
presets = {
  search = true,
  treesitter = true,
  diagnostics = true,
  -- others are disabled
}
```

### Exclude Specific Keys

```lua
presets = {
  words = {
    e = false,   -- don't override native 'e'
    ge = false,  -- don't override native 'ge'
  },
  search = {
    s = false,   -- keep native 's' (substitute)
  },
}
```

### Override Motion Settings

```lua
presets = {
  words = {
    w = {
      map = false,  -- register but don't map (map manually later)
    },
  },
}
```

Then map manually:
```lua
require("smart-motion").map_motion("w")
```

---

## Mode Reference

| Mode | Meaning |
|------|---------|
| `n` | Normal mode |
| `v` | Visual mode |
| `o` | Operator-pending mode |
| `x` | Visual mode only (not select mode) |

Motions in `o` mode work with **any vim operator**: `>`, `<`, `gU`, `gu`, `=`, `gq`, `!`, `zf`, etc.

---

## Multi-Window

Motions marked with **Multi-window: Yes** show labels across all visible (non-floating) windows.

- Current window gets label priority (closer targets get shorter labels)
- Selecting a label in another window switches to that window
- Disabled automatically in operator-pending mode

---

## Next Steps

→ **[Advanced Features](Advanced-Features.md)**: Flow state, operator-pending details, more

→ **[Build Your Own Motions](Building-Custom-Motions.md)**: Create custom motions

→ **[Configuration](Configuration.md)**: All settings explained
