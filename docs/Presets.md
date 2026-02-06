# Presets Guide

SmartMotion ships with **13 presets** containing **57+ keybindings**. Each preset is a logical group of related motions. Enable what you need, disable what you don't.

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
| `treesitter` | `]]` `[[` `]c` `[c` `]b` `[b` `daa` `caa` `yaa` `dfn` `cfn` `yfn` `saa` `gS` `R` | Syntax-aware motions |
| `diagnostics` | `]d` `[d` `]e` `[e` | LSP diagnostic navigation |
| `git` | `]g` `[g` | Git hunk navigation |
| `quickfix` | `]q` `[q` `]l` `[l` | Quickfix/location list |
| `marks` | `g'` `gm` | Mark navigation and setting |
| `misc` | `.` `g.` `gp` `gmd` `gmy` | Repeat, history, pins, and multi-cursor |

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
>w    — indent from cursor to labeled word
gUw   — uppercase from cursor to labeled word
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
=j    — auto-indent from cursor to labeled line
gqj   — format from cursor to labeled line
```

**Count prefix support:**
```
5j    — jumps to the 5th line target below (no labels shown)
3k    — jumps to the 3rd line target above
```

When a count precedes `j` or `k`, SmartMotion skips the label step and auto-selects the Nth target. This can be changed to native vim behavior via `count_behavior = "native"` in config. See **[Configuration](Configuration.md#count-behavior)**.

---

## search

Powerful search with multiple modes.

| Key | Modes | Multi-window | What it does |
|-----|-------|--------------|--------------|
| `s` | n, o | Yes | **Live search** — labels update as you type |
| `S` | n, o | Yes | **Fuzzy search** — type "fn" to match "function" |
| `f` | n, o | Yes | **2-char find** forward (like leap) |
| `F` | n, o | Yes | **2-char find** backward |
| `t` | n, o | Yes | **Till** character forward (cursor lands before match) |
| `T` | n, o | Yes | **Till** character backward (cursor lands after match) |
| `;` | n, v | Yes | **Repeat** last f/F/t/T (same direction) |
| `,` | n, v | Yes | **Repeat** last f/F/t/T (reversed direction) |
| `gs` | n | Yes | **Visual select** — pick two targets, enter visual mode |

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

When searching, labels are chosen to avoid ambiguity. If you're searching for "fu" and there's a match followed by "n", the label won't be "n" — because that could be continuing your search.

---

## delete

Delete operations with visual feedback.

| Key | Modes | What it does |
|-----|-------|--------------|
| `d` | n | **Composable delete** — press `d` then any motion |
| `dt` | n | Delete from cursor **until** character (forward) |
| `dT` | n | Delete from cursor **until** character (backward) |
| `rdw` | n | **Remote delete word** — delete a word without moving cursor |
| `rdl` | n | **Remote delete line** — delete a line without moving cursor |

### Composable Delete (`d`)

```
Press d → press w → labels appear → select target → text deleted from cursor to target
Press d → press ]] → labels appear on functions → select one → deleted to that function
```

Works with ANY SmartMotion motion.

### Repeat Motion Key (Quick Action)

When labels appear, pressing the motion key **again** acts on the target under your cursor:

```
dww   — delete the word under the cursor (repeat 'w')
djj   — delete to the current line target (repeat 'j')
d]]]] — delete to the function at cursor (repeat ']]')
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
| `y` | n | **Composable yank** — press `y` then any motion |
| `yt` | n | Yank from cursor **until** character (forward) |
| `yT` | n | Yank from cursor **until** character (backward) |
| `ryw` | n | **Remote yank word** — yank a word without moving cursor |
| `ryl` | n | **Remote yank line** — yank a line without moving cursor |

Same patterns as delete, but yanks to register instead.

Repeat motion key works here too: `yww` yanks the word under cursor, `yw` + label yanks a specific word.

---

## change

Change (delete + insert) operations.

| Key | Modes | What it does |
|-----|-------|--------------|
| `c` | n | **Composable change** — press `c` then any motion |
| `ct` | n | Change from cursor **until** character (forward) |
| `cT` | n | Change from cursor **until** character (backward) |

```
Press c → press w → select target → text deleted, insert mode activated
```

Repeat motion key works here too: `cww` changes the word under cursor, `cw` + label changes a specific word.

---

## paste

Paste at target location.

| Key | Modes | What it does |
|-----|-------|--------------|
| `p` | n | **Paste after** — select target, paste after it |
| `P` | n | **Paste before** — select target, paste before it |

```
Yank some text → press p → select a word → yanked text pastes after that word
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

### Editing

| Key | Modes | What it does |
|-----|-------|--------------|
| `daa` | n | **Delete around argument** (includes comma/separator) |
| `caa` | n | **Change around argument** |
| `yaa` | n | **Yank around argument** |
| `dfn` | n | **Delete function name** |
| `cfn` | n | **Change function name** (instant rename) |
| `yfn` | n | **Yank function name** |
| `saa` | n | **Swap arguments** — pick two, swap positions |

```
In: calculate(first, second, third)
Press daa → labels appear on arguments → select "second" → becomes: calculate(first, third)

Press cfn → labels appear on function names → select one → name deleted, insert mode
```

### Selection

| Key | Modes | What it does |
|-----|-------|--------------|
| `gS` | n, x | **Incremental select** — `;` expands to parent, `,` shrinks to child |
| `R` | n, x, o | **Treesitter search** — search text, pick match, pick ancestor scope |

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
| `g.` | n | **History browser** — browse pins and past targets with frecency ranking and action mode |
| `gp` | n | **Toggle pin** — bookmark/unbookmark the current cursor position |
| `gmd` | n | **Multi-cursor delete** — toggle-select multiple words, delete all |
| `gmy` | n | **Multi-cursor yank** — toggle-select multiple words, yank all |

### History Browser (`g.`)

```
Press g. → floating window with pins at top, frecency-ranked entries below
→ press number (1-9) to jump to a pin
→ press letter label to jump to an entry
→ press d/y/c to enter action mode, then press label to act on that target remotely
```

The browser shows two sections: **pins** (numbered `1`-`9` with `*` marker) and **entries** (letter labels, sorted by frecency with `█` bar indicators). Press `d`, `y`, or `c` to enter action mode — the title changes to `[D]`/`[Y]`/`[C]`, then press a label to delete, yank, or change that target without navigating there.

History persists across Neovim sessions. Visit counts accumulate over time, pushing frequently-visited locations to the top. See **[Advanced Features: Motion History](Advanced-Features.md#motion-history)** for full details.

### Pins (`gp`)

```
Press gp → "Pinned (1/9)" — current location bookmarked
Press gp again at same spot → "Unpinned"
```

Up to 9 pins. Pins persist across sessions and appear at the top of the history browser with number labels for instant access.

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

→ **[Advanced Features](Advanced-Features.md)** — Flow state, operator-pending details, more

→ **[Build Your Own Motions](Building-Custom-Motions.md)** — Create custom motions

→ **[Configuration](Configuration.md)** — All settings explained
