# SmartMotion.nvim

```
   _____                      __  __  ___      __  _                          _
  / ___/____ ___  ____ ______/ /_/  |/  /___  / /_(_)___  ____    ____ _   __(_)___ ___
  \__ \/ __ `__ \/ __ `/ ___/ __/ /|_/ / __ \/ __/ / __ \/ __ \  / __ \ | / / / __ `__ \
 ___/ / / / / / / /_/ / /  / /_/ /  / / /_/ / /_/ / /_/ / / / / / / / / |/ / / / / / / /
/____/_/ /_/ /_/\__,_/_/   \__/__/  /_/\____/\__/_/\____/_/ /_(_)__/ /_/|___/_/_/ /_/ /_/
```

**The last motion plugin you'll ever need.**

One plugin replaces hop, leap, flash, and mini.jump - then goes further with treesitter-aware editing, diagnostics jumping, composable operators, pins (harpoon style), and a pipeline architecture that lets you build any motion you can imagine.

---

![SmartMotion in action](assets/smart-motion-showcase.gif)

---

## ✨ Features

- 🌊 **Flow State** - chain motions without re-triggering hints. Select a target, then press any motion key within 300ms for instant movement. Hold `w` and watch it flow like native Vim. **No other motion plugin does this.**
- 🔀 **Composable operators** - `d`, `y`, `c`, `p` automatically compose with **every** motion via inference. `dw`, `ds`, `yf`, `cj` - 55+ compositions from 16 keys, zero explicit mappings needed.
- ⚡ **Word, line, and search jumping** with home-row hint labels - forward, backward, start, end
- 🌳 **Treesitter-aware motions** - jump to functions (`]]`/`[[`), classes (`]c`/`[c`), scopes/blocks (`]b`/`[b`), text objects for functions (`af`/`if`), classes (`ac`/`ic`), arguments (`aa`/`ia`), and function names (`fn`)
- 📡 **Remote operations** - `rdw`, `rdl`, `ryw`, `ryl` delete or yank words and lines without moving the cursor
- ✂️ **Until motions** - `dt`, `yt`, `ct` operate from cursor to a labeled character
- 🌲 **Treesitter incremental select** - `gS` selects node at cursor, `;` expands to parent, `,` shrinks to child
- 🔎 **Treesitter search** - `R` searches text, then lets you pick which surrounding syntax node to select (works with operators: `dR`, `yR`, `cR`)
- 🩺 **Diagnostics jumping** - navigate all diagnostics (`]d`/`[d`) or errors only (`]e`/`[e`)
- 🔀 **Git hunk jumping** - navigate git changed regions (`]g`/`[g`) with gitsigns.nvim integration
- 📋 **Quickfix/location list** - navigate quickfix (`]q`/`[q`) and location list (`]l`/`[l`) entries with labels
- 🔖 **Marks integration** - jump to any mark with labels (`g'`), set marks remotely (`gm`)
- 🔎 **2-char find** - `f`/`F` for leap-style two-character search with labels
- 🔍 **Live search** - `s` for incremental search with labeled results across all visible text
- 🔎 **Fuzzy search** - `S` for fuzzy matching (type "fn" to match "function", "filename", etc.)
- 🎯 **Till motions** - `t`/`T` for single-character till (jump to just before/after the match), with `;`/`,` to repeat
- 🔎 **Native search labels** - `/` shows labels incrementally as you type, `<C-s>` toggles labels on/off
- 🧠 **Label conflict avoidance** - labels can't be valid search continuations (no ambiguity)
- 🪟 **Multi-window jumping** - search, treesitter, and diagnostic motions show labels across all visible splits. Select a label in another window and jump there instantly.
- ⚙️ **Operator-pending mode** - use SmartMotion motions with any vim operator (`>w`, `gUw`, `=j`, `gqj`, etc.)
- 👁️ **Visual range selection** - `gs` picks two targets, enters visual mode spanning the range
- 🔄 **Argument swap** - `saa` picks two treesitter arguments and swaps them
- ✏️ **Multi-cursor edit** - `gmd`/`gmy` toggle-select multiple words, then delete or yank them all at once
- 🔁 **Repeat** - `.` repeats the last SmartMotion
- 🕰️ **Motion History** - `g.` opens a full-featured history browser with **pins** (`gp` to bookmark), **frecency ranking**, **j/k navigation with live preview**, **/search filtering**, and **action mode** (`d`/`y`/`c` to delete, yank, or change targets remotely). History persists across sessions.
- 📌 **Direct Pin Jumps** - `g1`-`g9` jump instantly to numbered pins. `g0` jumps to your most recent location. `gp1`-`gp9` set pins at specific slots.
- 🌍 **Global Pins** - `gP` creates cross-project bookmarks (`A`-`Z`). `gA`-`gZ` jump to global pins from any project. Great for dotfiles, notes, or common configs.
- 🧩 **Fully modular pipeline** - Collector → Extractor → Modifier → Filter → Visualizer → Selection → Action. Every stage is replaceable. Build entirely custom motions from scratch.
- 📦 **13 presets, 55+ inferred compositions, 100+ keybindings** - enable what you want, disable what you don't

---

## 🚀 Quick Start

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  "FluxxField/smart-motion.nvim",
  opts = {
    presets = {
      words = true,        -- w, b, e, ge
      lines = true,        -- j, k
      search = true,       -- s, f, F, t, T, ;, ,, gs
      delete = true,       -- d + any motion, dt, dT, rdw, rdl
      yank = true,         -- y + any motion, yt, yT, ryw, ryl
      change = true,       -- c + any motion, ct, cT
      paste = true,        -- p/P + any motion
      treesitter = true,   -- ]], [[, ]c, [c, ]b, [b, af, if, ac, ic, aa, ia, fn, saa
      diagnostics = true,  -- ]d, [d, ]e, [e
      git = true,          -- ]g, [g
      quickfix = true,     -- ]q, [q, ]l, [l
      marks = true,        -- g', gm
      misc = true,         -- . g. g0 g1-g9 gp gP gA-gZ gmd gmy (repeat, history, pins, global pins)
    },
  },
}
```

Everything is opt-in. Enable only the presets you want. Individual keys within a preset can be disabled too:

```lua
presets = {
  words = { e = false, ge = false },  -- only enable w and b
  search = true,
}
```

---

## 🌊 Flow State

This is SmartMotion's signature feature. Flow State lets you chain motions without seeing labels on every keystroke.

### Two Ways In

**1. Select a label, then chain:**

```
w  [labels appear]  f  cursor jumps to that word
                           (within 300ms)
                      j  instant jump to line below (no labels)
                           (within 300ms)
                      b  instant jump back a word (no labels)
                           (within 300ms)
                      w  instant jump forward (no labels)
```

**2. Hold or spam a motion key:**

```
w  [labels flash briefly]  w  instant jump  w  instant jump  w  ...
```

**Easiest way to feel it:** just hold down `w`. Labels appear for a split second, then it moves word-by-word exactly like native Vim. That's Flow State kicking in.

### Why This Matters

Other motion plugins force a choice: hints for precision OR native feel for speed. SmartMotion gives you both:

- **Labels** when you need to aim at a specific target
- **Instant movement** when you're flowing through code

The 300ms window resets on every motion, so you can chain indefinitely. And you can chain *different* motions - `w` → `j` → `b` → `w` all without hints.

Configure the timeout:

```lua
opts = {
  flow_state_timeout_ms = 300,  -- default
}
```

---

## 🔀 Composable Operators - The Inference System

When you press `d`, `y`, `c`, or `p`, SmartMotion reads the next key and **automatically infers the full pipeline** - extractor, filter, visualizer, and metadata - from the target motion. No explicit mapping needed.

```
dw    d (delete)  +  w (words extractor, after cursor filter)
db    d (delete)  +  b (words extractor, before cursor filter)
ds    d (delete)  +  s (live search extractor, multi-window)
yf    y (yank)    +  f (2-char search extractor)
cj    c (change)  +  j (lines extractor, after cursor filter)
```

Every composable motion (`w`, `b`, `e`, `j`, `k`, `s`, `S`, `f`, `F`, `t`, `T`) works with every operator (`d`, `y`, `c`, `p`, `P`). That's **55+ compositions** from 16 keys.

### Double-Tap for Cursor Target

Repeat the motion key to act on the target under cursor:

```
dww    delete this word (no labels)
yww    yank this word
cww    change this word
```

Labels still appear, but the second tap says "I mean this one."

### Why This Matters

Most motion plugins require explicit mappings for every combination. SmartMotion doesn't:

```lua
-- This is ALL you need.
presets = {
  words = true,    -- registers w, b, e, ge
  lines = true,    -- registers j, k
  search = true,   -- registers s, S, f, F, t, T
  delete = true,   -- d now works with ALL of the above
  yank = true,     -- y now works with ALL of the above
  change = true,   -- c now works with ALL of the above
}
```

Enable a motion preset → every operator can use it. Enable an operator preset → it works with every motion. The growth is multiplicative, not additive.

### Custom Trigger Keys

Remap an operator and all its compositions follow:

```lua
presets = {
  delete = {
    d = { trigger_key = "<leader>d" },
  },
}
-- Now: <leader>dw, <leader>ds, <leader>d]], etc.
```

If the motion key doesn't match any SmartMotion motion, it falls through to native vim. `d$`, `d0`, `dG` all work exactly as expected.

---

## 🎯 What You Get

Every preset and its keybindings at a glance. Enable a preset and all its bindings are ready.

<details>
<summary><b>⚡ Words</b> - <code>w</code> <code>b</code> <code>e</code> <code>ge</code></summary>

| Key  | Mode    | Description                          |
|------|---------|--------------------------------------|
| `w`  | n, v, o | Jump to start of word after cursor   |
| `b`  | n, v, o | Jump to start of word before cursor  |
| `e`  | n, v, o | Jump to end of word after cursor     |
| `ge` | n, v, o | Jump to end of word before cursor    |

</details>

<details>
<summary><b>📏 Lines</b> - <code>j</code> <code>k</code></summary>

| Key | Mode    | Description                  |
|-----|---------|------------------------------|
| `j` | n, v, o | Jump to line after cursor (supports count: `5j`)  |
| `k` | n, v, o | Jump to line before cursor (supports count: `3k`) |

</details>

<details>
<summary><b>🔍 Search</b> - <code>s</code> <code>S</code> <code>f</code> <code>F</code> <code>t</code> <code>T</code> <code>;</code> <code>,</code> <code>gs</code> 🪟</summary>

| Key  | Mode | Description                                          |
|------|------|------------------------------------------------------|
| `s`  | n, o | Live search across all visible text with labels      |
| `S`  | n, o | Fuzzy search - type partial patterns to match words  |
| `f`  | n, o | 2-char find forward with labels                      |
| `F`  | n, o | 2-char find backward with labels                     |
| `t`  | n, o | Till character forward (jump to just before match)   |
| `T`  | n, o | Till character backward (jump to just after match)   |
| `;`  | n, v | Repeat last f/F/t/T motion (same direction)          |
| `,`  | n, v | Repeat last f/F/t/T motion (reversed direction)      |
| `gs` | n    | Visual select via labels - pick two targets, enter visual mode |

> Multi-window: labels appear in all visible splits. Label conflict avoidance ensures labels can't be valid search continuations.

</details>

<details>
<summary><b>🔀 Composable Operators</b> - <code>d</code> <code>y</code> <code>c</code> <code>p</code> <code>P</code> + any motion</summary>

Press an operator, then any motion key - SmartMotion infers the pipeline, shows labels, and performs the action:

| Combo | What it does |
|-------|-------------|
| `dw`  | Jump to word after cursor, delete it |
| `db`  | Jump to word before cursor, delete it |
| `dj`  | Jump to line below, delete it |
| `ds`  | Live search → pick label → delete |
| `df`  | 2-char find → pick label → delete |
| `dt`  | Delete till character (from cursor to target) |
| `dd`  | Delete current line |

All work identically with `y` (yank), `c` (change), and `p`/`P` (paste).

Repeat the motion key for cursor target: `dww` = delete this word.

**Remote operations (cursor stays in place):**

| Key   | Description                |
|-------|----------------------------|
| `rdw` | Remote delete word         |
| `rdl` | Remote delete line         |
| `ryw` | Remote yank word           |
| `ryl` | Remote yank line           |

</details>

<details>
<summary><b>🌳 Treesitter</b> - <code>]]</code> <code>[[</code> <code>]c</code> <code>[c</code> <code>]b</code> <code>[b</code> <code>af</code> <code>if</code> <code>ac</code> <code>ic</code> <code>aa</code> <code>ia</code> <code>fn</code> <code>saa</code> <code>gS</code> <code>R</code> 🪟</summary>

| Key   | Mode    | Description                                           |
|-------|---------|-------------------------------------------------------|
| `]]`  | n, o    | Jump to next function                                 |
| `[[`  | n, o    | Jump to previous function                             |
| `]c`  | n, o    | Jump to next class/struct                             |
| `[c`  | n, o    | Jump to previous class/struct                         |
| `]b`  | n, o    | Jump to next block/scope (if, for, while, try, etc.)  |
| `[b`  | n, o    | Jump to previous block/scope                          |
| `af`  | x, o    | Select around function (works with any operator: `daf`, `yaf`, `gqaf`) |
| `if`  | x, o    | Select inside function body                           |
| `ac`  | x, o    | Select around class/struct                            |
| `ic`  | x, o    | Select inside class/struct body                       |
| `aa`  | x, o    | Select around argument (includes separator)           |
| `ia`  | x, o    | Select inside argument                                |
| `fn`  | o       | Select function name (works with operators: `dfn`, `cfn`, `yfn`) |
| `saa` | n       | Swap two arguments - pick two, swap their positions   |
| `gS`  | n, x    | Treesitter incremental select - `;` expand, `,` shrink |
| `R`   | n, x, o | Treesitter search - search text, pick match, pick ancestor scope |

Text objects compose with **any vim operator** automatically — `daf` deletes a function, `yaa` yanks an argument, `gqaf` formats a function, `=if` indents a function body, etc. Multi-char `fn` uses timeout-based resolution: `dfn` typed quickly selects function name, `df` + pause falls through to find-char.

Works across Lua, Python, JavaScript, TypeScript, Rust, Go, C, C++, Java, C#, and Ruby.

> Multi-window: navigation motions show labels across all visible splits.

</details>

<details>
<summary><b>🩺 Diagnostics</b> - <code>]d</code> <code>[d</code> <code>]e</code> <code>[e</code> 🪟</summary>

| Key  | Mode | Description                         |
|------|------|-------------------------------------|
| `]d` | n, o | Jump to next diagnostic             |
| `[d` | n, o | Jump to previous diagnostic         |
| `]e` | n, o | Jump to next error                  |
| `[e` | n, o | Jump to previous error              |

> Multi-window: labels appear in all visible splits.

</details>

<details>
<summary><b>🔀 Git</b> - <code>]g</code> <code>[g</code> 🪟</summary>

| Key  | Mode | Description                              |
|------|------|------------------------------------------|
| `]g` | n, o | Jump to next git hunk (changed region)   |
| `[g` | n, o | Jump to previous git hunk                |

> Works best with [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) installed.

</details>

<details>
<summary><b>📋 Quickfix</b> - <code>]q</code> <code>[q</code> <code>]l</code> <code>[l</code> 🪟</summary>

| Key  | Mode | Description                              |
|------|------|------------------------------------------|
| `]q` | n, o | Jump to next quickfix entry              |
| `[q` | n, o | Jump to previous quickfix entry          |
| `]l` | n, o | Jump to next location list entry         |
| `[l` | n, o | Jump to previous location list entry     |

</details>

<details>
<summary><b>🔖 Marks</b> - <code>g'</code> <code>gm</code> 🪟</summary>

| Key  | Mode | Description                                        |
|------|------|----------------------------------------------------|
| `g'` | n, o | Show labels on all marks, jump to selected         |
| `gm` | n    | Set mark at labeled target (prompts for mark name) |

</details>

<details>
<summary><b>🔁 Misc</b> - <code>.</code> <code>g.</code> <code>g0</code> <code>g1-g9</code> <code>gp</code> <code>gP</code> <code>gA-gZ</code> <code>gmd</code> <code>gmy</code></summary>

| Key   | Mode | Description                                          |
|-------|------|------------------------------------------------------|
| `.`   | n    | Repeat last SmartMotion                               |
| `g.`  | n    | History browser - pins, frecency, preview, search, actions |
| `g0`  | n    | Jump to most recent location (quick "go back")        |
| `g1`-`g9` | n | Jump directly to pin 1-9                             |
| `gp`  | n    | Toggle pin at cursor (up to 9)                        |
| `gp1`-`gp9` | n | Set current location as pin N                      |
| `gP`  | n    | Toggle global pin (prompts A-Z)                       |
| `gA`-`gZ` | n | Jump to global pin (works from any project)          |
| `gPA`-`gPZ` | n | Set global pin directly                            |
| `gmd` | n    | Multi-cursor delete - toggle-select, Enter to delete |
| `gmy` | n    | Multi-cursor yank - toggle-select, Enter to yank     |

</details>

---

## 📌 Pins - Quick File Navigation

SmartMotion includes a built-in pinning system for fast file navigation.

### Local Pins (Per-Project)

```
gp         toggle pin at cursor ("Pinned 1/9" or "Unpinned")
g1 - g9    jump instantly to pin 1-9
gp3        set current location as pin 3
g.         open history browser (pins at top)
```

**Workflow:**
1. Open your main file, `gp` → "Pinned (1/9)"
2. Open your test file, `gp` → "Pinned (2/9)"
3. Open your config, `gp` → "Pinned (3/9)"
4. Now: `g1` = main, `g2` = tests, `g3` = config

### Global Pins (Cross-Project)

```
gP         toggle global pin (prompts A-Z)
gA - gZ    jump to global pin from ANY project
gPA        set global pin A directly
```

26 slots for dotfiles, notes, configs - accessible from anywhere.

### Quick Navigation

| Key | What it does |
|-----|--------------|
| `g0` | Jump to most recent location |
| `g1`-`g9` | Jump to local pin |
| `gA`-`gZ` | Jump to global pin |

---

## 🪟 Multi-Window Jumping

Search, treesitter, diagnostic, git, quickfix, and mark motions show labels across **all visible splits**. Select a label in another window and jump there.

Enabled by default for: `s`, `f`, `F`, `t`, `T`, `]]`, `[[`, `]c`, `[c`, `]b`, `[b`, `]d`, `[d`, `]e`, `[e`, `]g`, `[g`, `]q`, `[q`, `]l`, `[l`, `g'`, `gm`

Word/line motions (`w`, `b`, `e`, `ge`, `j`, `k`) stay single-window - directional motions within one window are the natural UX.

---

## ⚙️ Operator-Pending Mode

SmartMotion motions work with **any vim operator**:

```
>w    - indent to labeled word
gUw   - uppercase to labeled word
=j    - auto-indent to labeled line
gqj   - format to labeled line
>]]   - indent to labeled function
```

All jump motions are available in operator-pending mode.

---

## 🕰️ Motion History

Press `g.` to open the history browser:

```
 1  *  "authenticate"            auth.lua:42
 2  *  "render"                  app.tsx:15
────────────────────────────────────────────────
 f  s   "config"          ████   config.lua:8     just now
 a  dw  "handle_error"    ███    server.lua:30    5m ago
 s  w   "validate"        ██     utils.lua:12     2h ago
────────────────────────────────────────────────
 j/k navigate  /search  d/y/c action  Enter select  Esc cancel
```

- **Pins** at top with number labels
- **Frecency** ranks by frequency + recency
- **j/k** navigation with live preview
- **/search** to filter
- **d/y/c** to act on targets remotely

History persists across sessions.

---

## 🧩 Why SmartMotion?

### One Plugin, Compound Benefits

- **Motion History** - every jump, search, delete recorded. Pin locations, browse frecency-ranked history, act remotely.
- **Composable operators** - 55+ compositions from 16 keys, zero explicit mappings.
- **Flow State** - chain any motion into any other without re-triggering.
- **Consistent labels** - same home-row system across 100+ keybindings.
- **One config** - enable, disable, remap from a single `opts` table.

### The Pipeline

Every motion flows through:

```
Collector → Extractor → Modifier → Filter → Visualizer → Selection → Action
```

Every stage is a module. Build custom motions by combining them:

```lua
local sm = require("smart-motion")

sm.motions.register("custom_jump", {
  collector = "lines",
  extractor = "words",
  filter = "filter_words_after_cursor",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n", "v" },
  trigger = "<leader>j",
})
```

For more, see the [Wiki](https://github.com/FluxxField/smart-motion.nvim/wiki/Building-Custom-Motions).

---

<details>
<summary><h2>⚙️ Configuration</h2></summary>

```lua
{
  keys = "fjdksleirughtynm",
  use_background_highlights = false,
  highlight = {
    hint = "SmartMotionHint",
    hint_dim = "SmartMotionHintDim",
    two_char_hint = "SmartMotionTwoCharHint",
    two_char_hint_dim = "SmartMotionTwoCharHintDim",
    dim = "SmartMotionDim",
    search_prefix = "SmartMotionSearchPrefix",
    search_prefix_dim = "SmartMotionSearchPrefixDim",
  },
  presets = {},
  flow_state_timeout_ms = 300,
  disable_dim_background = false,
  history_max_size = 20,
  auto_select_target = false,
  native_search = true,
  count_behavior = "target",
}
```

See [Wiki Configuration](https://github.com/FluxxField/smart-motion.nvim/wiki/Configuration) for details.

</details>

---

## 📦 Alternatives

SmartMotion is inspired by and unifies ideas from:

- [hop.nvim](https://github.com/phaazon/hop.nvim)
- [flash.nvim](https://github.com/folke/flash.nvim)
- [lightspeed.nvim](https://github.com/ggandor/lightspeed.nvim)
- [leap.nvim](https://github.com/ggandor/leap.nvim)
- [mini.jump](https://github.com/echasnovski/mini.nvim#mini.jump)

---

## 📜 License

[GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html)

## 👤 Author

Built by [FluxxField](https://github.com/FluxxField)

---

## 📖 Documentation

Visit the **[Wiki](https://github.com/FluxxField/smart-motion.nvim/wiki)**:

- [Home](https://github.com/FluxxField/smart-motion.nvim/wiki)
- [Why SmartMotion?](https://github.com/FluxxField/smart-motion.nvim/wiki/Why-SmartMotion)
- [Quick Start](https://github.com/FluxxField/smart-motion.nvim/wiki/Quick-Start)
- [Presets Guide](https://github.com/FluxxField/smart-motion.nvim/wiki/Presets)
- [Build Your Own](https://github.com/FluxxField/smart-motion.nvim/wiki/Building-Custom-Motions)
- [Configuration](https://github.com/FluxxField/smart-motion.nvim/wiki/Configuration)
- [API Reference](https://github.com/FluxxField/smart-motion.nvim/wiki/API-Reference)
