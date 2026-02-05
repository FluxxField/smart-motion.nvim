# SmartMotion.nvim

```
   _____                      __  __  ___      __  _                          _
  / ___/____ ___  ____ ______/ /_/  |/  /___  / /_(_)___  ____    ____ _   __(_)___ ___
  \__ \/ __ `__ \/ __ `/ ___/ __/ /|_/ / __ \/ __/ / __ \/ __ \  / __ \ | / / / __ `__ \
 ___/ / / / / / / /_/ / /  / /_/ /  / / /_/ / /_/ / /_/ / / / / / / / / |/ / / / / / / /
/____/_/ /_/ /_/\__,_/_/   \__/__/  /_/\____/\__/_/\____/_/ /_(_)__/ /_/|___/_/_/ /_/ /_/
```

**The last motion plugin you'll ever need.**

One plugin replaces hop, leap, flash, and mini.jump — then goes further with treesitter-aware editing, diagnostics jumping, composable operators, and a pipeline architecture that lets you build any motion you can imagine.

> [!WARNING]
> SmartMotion is under active development. The API is stabilizing but breaking changes may still occur.

---

![SmartMotion in action](assets/smart-motion-showcase.gif)

---

## ✨ Features

- ⚡ **Word, line, and search jumping** with home-row hint labels — forward, backward, start, end
- 🌊 **Flow State** — chain motions without re-triggering; press `w` → select → press `w` again instantly
- 🔀 **Composable d/y/c/p** — `d` + any motion deletes, `y` + any motion yanks, `c` + any motion changes, with visual feedback at every step. Repeat the motion key to act on the target under cursor (`dww` = delete this word, `dw` + label = delete that word)
- ✂️ **Until motions** — `dt`, `yt`, `ct` operate from cursor to a labeled character on the current line
- 📡 **Remote operations** — `rdw`, `rdl`, `ryw`, `ryl` delete or yank words and lines without moving the cursor
- 🌳 **Treesitter-aware motions** — jump to functions (`]]`/`[[`), classes (`]c`/`[c`), scopes/blocks (`]b`/`[b`), delete/change/yank function names (`dfn`, `cfn`, `yfn`), and arguments (`daa`, `caa`, `yaa`)
- 🌲 **Treesitter incremental select** — `gS` selects node at cursor, `;` expands to parent, `,` shrinks to child
- 🔎 **Treesitter search** — `R` searches text and selects the surrounding syntax node (works with operators: `dR`, `yR`, `cR`)
- 🩺 **Diagnostics jumping** — navigate all diagnostics (`]d`/`[d`) or errors only (`]e`/`[e`)
- 🔀 **Git hunk jumping** — navigate git changed regions (`]g`/`[g`) with gitsigns.nvim integration
- 📋 **Quickfix/location list** — navigate quickfix (`]q`/`[q`) and location list (`]l`/`[l`) entries with labels
- 🔖 **Marks integration** — jump to any mark with labels (`g'`), set marks remotely (`gm`)
- 🔎 **2-char find** — `f`/`F` for leap-style two-character search with labels
- 🔍 **Live search** — `s` for incremental search with labeled results across all visible text
- 🔎 **Fuzzy search** — `S` for fuzzy matching (type "fn" to match "function", "filename", etc.)
- 🎯 **Till motions** — `t`/`T` for single-character till (jump to just before/after the match), with `;`/`,` to repeat
- 🔎 **Native search labels** — `/` shows labels incrementally as you type, `<C-s>` toggles labels on/off
- 🧠 **Label conflict avoidance** — labels can't be valid search continuations (no ambiguity)
- 🪟 **Multi-window jumping** — search, treesitter, and diagnostic motions show labels across all visible splits. Select a label in another window and jump there instantly.
- ⚙️ **Operator-pending mode** — use SmartMotion motions with any vim operator (`>w`, `gUw`, `=j`, `gqj`, etc.)
- 👁️ **Visual range selection** — `gs` picks two targets, enters visual mode spanning the range
- 🔄 **Argument swap** — `saa` picks two treesitter arguments and swaps them
- ✏️ **Multi-cursor edit** — `gmd`/`gmy` toggle-select multiple words, then delete or yank them all at once
- 🔁 **Repeat** — `.` repeats the last SmartMotion
- 🕰️ **Motion History** — `g.` opens a labeled history with **pins** at top (`gp` to bookmark, `1`-`9` to jump), **frecency-ranked** entries below, and **action mode** (`d`/`y`/`c` to delete, yank, or change targets remotely without leaving your position). History persists across sessions with visit counts that push frequently-visited locations to the top.
- 🧩 **Fully modular pipeline** — Collector → Extractor → Modifier → Filter → Visualizer → Selection → Action. Every stage is replaceable. Build entirely custom motions from scratch.
- 📦 **13 presets, 59+ keybindings** — enable what you want, disable what you don't

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
      delete = true,       -- d, dt, dT, rdw, rdl
      yank = true,         -- y, yt, yT, ryw, ryl
      change = true,       -- c, ct, cT
      paste = true,        -- p, P
      treesitter = true,   -- ]], [[, ]c, [c, ]b, [b, daa, caa, yaa, dfn, cfn, yfn, saa
      diagnostics = true,  -- ]d, [d, ]e, [e
      git = true,          -- ]g, [g
      quickfix = true,     -- ]q, [q, ]l, [l
      marks = true,        -- g', gm
      misc = true,         -- . (repeat), g. (history), gp (pin), gmd, gmy
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

## 🎯 What You Get

Every preset and its keybindings at a glance. Enable a preset and all its bindings are ready.

<details>
<summary><b>⚡ Words</b> — <code>w</code> <code>b</code> <code>e</code> <code>ge</code></summary>

| Key  | Mode    | Description                          |
|------|---------|--------------------------------------|
| `w`  | n, v, o | Jump to start of word after cursor   |
| `b`  | n, v, o | Jump to start of word before cursor  |
| `e`  | n, v, o | Jump to end of word after cursor     |
| `ge` | n, v, o | Jump to end of word before cursor    |

</details>

<details>
<summary><b>📏 Lines</b> — <code>j</code> <code>k</code></summary>

| Key | Mode    | Description                  |
|-----|---------|------------------------------|
| `j` | n, v, o | Jump to line after cursor (supports count: `5j`)  |
| `k` | n, v, o | Jump to line before cursor (supports count: `3k`) |

</details>

<details>
<summary><b>🔍 Search</b> — <code>s</code> <code>S</code> <code>f</code> <code>F</code> <code>t</code> <code>T</code> <code>;</code> <code>,</code> <code>gs</code> 🪟</summary>

| Key  | Mode | Description                                          |
|------|------|------------------------------------------------------|
| `s`  | n, o | Live search across all visible text with labels      |
| `S`  | n, o | Fuzzy search — type partial patterns to match words  |
| `f`  | n, o | 2-char find forward with labels                      |
| `F`  | n, o | 2-char find backward with labels                     |
| `t`  | n, o | Till character forward (jump to just before match)   |
| `T`  | n, o | Till character backward (jump to just after match)   |
| `;`  | n, v | Repeat last f/F/t/T motion (same direction)          |
| `,`  | n, v | Repeat last f/F/t/T motion (reversed direction)      |
| `gs` | n    | Visual select via labels — pick two targets, enter visual mode |

> Multi-window: labels appear in all visible splits. Label conflict avoidance ensures labels can't be valid search continuations.

</details>

<details>
<summary><b>🗑️ Delete</b> — <code>d</code> <code>dt</code> <code>dT</code> <code>rdw</code> <code>rdl</code></summary>

| Key   | Mode | Description                                    |
|-------|------|------------------------------------------------|
| `d`   | n    | Composable delete — press `d` then any motion. Repeat motion key for cursor target (`dww`) |
| `dt`  | n    | Delete from cursor until character (forward)   |
| `dT`  | n    | Delete from cursor until character (backward)  |
| `rdw` | n    | Remote delete word (cursor stays in place)      |
| `rdl` | n    | Remote delete line (cursor stays in place)      |

</details>

<details>
<summary><b>📋 Yank</b> — <code>y</code> <code>yt</code> <code>yT</code> <code>ryw</code> <code>ryl</code></summary>

| Key   | Mode | Description                                   |
|-------|------|-----------------------------------------------|
| `y`   | n    | Composable yank — press `y` then any motion. Repeat motion key for cursor target (`yww`)  |
| `yt`  | n    | Yank from cursor until character (forward)    |
| `yT`  | n    | Yank from cursor until character (backward)   |
| `ryw` | n    | Remote yank word (cursor stays in place)       |
| `ryl` | n    | Remote yank line (cursor stays in place)       |

</details>

<details>
<summary><b>✏️ Change</b> — <code>c</code> <code>ct</code> <code>cT</code></summary>

| Key  | Mode | Description                                    |
|------|------|------------------------------------------------|
| `c`  | n    | Composable change — press `c` then any motion. Repeat motion key for cursor target (`cww`) |
| `ct` | n    | Change from cursor until character (forward)   |
| `cT` | n    | Change from cursor until character (backward)  |

</details>

<details>
<summary><b>📌 Paste</b> — <code>p</code> <code>P</code></summary>

| Key | Mode | Description                                   |
|-----|------|-----------------------------------------------|
| `p` | n    | Composable paste after — press `p` then motion |
| `P` | n    | Composable paste before — press `P` then motion |

</details>

<details>
<summary><b>🌳 Treesitter</b> — <code>]]</code> <code>[[</code> <code>]c</code> <code>[c</code> <code>]b</code> <code>[b</code> <code>daa</code> <code>caa</code> <code>yaa</code> <code>dfn</code> <code>cfn</code> <code>yfn</code> <code>saa</code> <code>gS</code> <code>R</code> 🪟</summary>

| Key   | Mode    | Description                                           |
|-------|---------|-------------------------------------------------------|
| `]]`  | n, o    | Jump to next function                                 |
| `[[`  | n, o    | Jump to previous function                             |
| `]c`  | n, o    | Jump to next class/struct                             |
| `[c`  | n, o    | Jump to previous class/struct                         |
| `]b`  | n, o    | Jump to next block/scope (if, for, while, try, etc.)  |
| `[b`  | n, o    | Jump to previous block/scope                          |
| `daa` | n       | Delete around argument (includes separator)           |
| `caa` | n       | Change argument                                       |
| `yaa` | n       | Yank argument                                         |
| `dfn` | n       | Delete function name                                  |
| `cfn` | n       | Change function name (rename)                         |
| `yfn` | n       | Yank function name                                    |
| `saa` | n       | Swap two arguments — pick two, swap their positions   |
| `gS`  | n, x    | Treesitter incremental select — `;` expand, `,` shrink |
| `R`   | n, x, o | Treesitter search — search text, select surrounding node |

Works across Lua, Python, JavaScript, TypeScript, Rust, Go, C, C++, Java, C#, and Ruby. Non-matching node types are safely ignored.

> Multi-window: navigation motions (`]]`, `[[`, `]c`, `[c`, `]b`, `[b`) show labels across all visible splits. Editing motions stay in the current buffer.

</details>

<details>
<summary><b>🩺 Diagnostics</b> — <code>]d</code> <code>[d</code> <code>]e</code> <code>[e</code> 🪟</summary>

| Key  | Mode | Description                         |
|------|------|-------------------------------------|
| `]d` | n, o | Jump to next diagnostic             |
| `[d` | n, o | Jump to previous diagnostic         |
| `]e` | n, o | Jump to next error                  |
| `[e` | n, o | Jump to previous error              |

> Multi-window: labels appear in all visible splits.

</details>

<details>
<summary><b>🔀 Git</b> — <code>]g</code> <code>[g</code> 🪟</summary>

| Key  | Mode | Description                              |
|------|------|------------------------------------------|
| `]g` | n, o | Jump to next git hunk (changed region)   |
| `[g` | n, o | Jump to previous git hunk                |

> Works best with [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) installed. Falls back to `git diff` parsing without gitsigns.

> Multi-window: labels appear in all visible splits.

</details>

<details>
<summary><b>📋 Quickfix</b> — <code>]q</code> <code>[q</code> <code>]l</code> <code>[l</code> 🪟</summary>

| Key  | Mode | Description                              |
|------|------|------------------------------------------|
| `]q` | n, o | Jump to next quickfix entry              |
| `[q` | n, o | Jump to previous quickfix entry          |
| `]l` | n, o | Jump to next location list entry         |
| `[l` | n, o | Jump to previous location list entry     |

> Quickfix entries come from `:vimgrep`, `:make`, `:grep`, LSP, etc. Location list (`]l`/`[l`) is window-local.

> Multi-window: labels appear in all visible splits.

</details>

<details>
<summary><b>🔖 Marks</b> — <code>g'</code> <code>gm</code> 🪟</summary>

| Key  | Mode | Description                                        |
|------|------|----------------------------------------------------|
| `g'` | n, o | Show labels on all marks, jump to selected         |
| `gm` | n    | Set mark at labeled target (prompts for mark name) |

> `g'` shows labels on all marks (a-z local, A-Z global). `gm` lets you set a mark at any visible location without moving your cursor.

> Multi-window: global marks (A-Z) from other visible buffers are included.

</details>

<details>
<summary><b>🔁 Misc</b> — <code>.</code> <code>g.</code> <code>gp</code> <code>gmd</code> <code>gmy</code></summary>

| Key   | Mode | Description                                          |
|-------|------|------------------------------------------------------|
| `.`   | n    | Repeat last SmartMotion                               |
| `g.`  | n    | History browser — pins at top, frecency-ranked entries, action mode (`d`/`y`/`c`) |
| `gp`  | n    | Toggle pin at cursor — bookmark locations for instant access (up to 9) |
| `gmd` | n    | Multi-cursor delete — toggle-select words, press Enter to delete all |
| `gmy` | n    | Multi-cursor yank — toggle-select words, press Enter to yank all    |

</details>

---

## 🌊 Flow State

Press a motion key, see labels, select a target. Then press the same key (or a different motion key) again within the timeout window — labels appear instantly with no re-trigger delay. You're in flow.

Flow State makes chained navigation feel native. Jump word-to-word, switch from `w` to `b` mid-flow, or chain any combination of motions seamlessly.

Configure the timeout (default 300ms):

```lua
opts = {
  flow_state_timeout_ms = 300,
}
```

---

## ⚙️ Operator-Pending Mode

SmartMotion motions work with **any vim operator**. Type an operator, then a SmartMotion motion key — labels appear, and the operator applies from your cursor to the selected target.

```
>w    — indent from cursor to labeled word
gUw   — uppercase from cursor to labeled word
=j    — auto-indent from cursor to labeled line
gqj   — format from cursor to labeled line
>]]   — indent from cursor to labeled function
```

All jump-only motions (`w`, `b`, `e`, `ge`, `j`, `k`, `s`, `f`, `F`, `t`, `T`, `]]`, `[[`, `]c`, `[c`, `]b`, `[b`, `]d`, `[d`, `]e`, `[e`, `]g`, `[g`, `]q`, `[q`, `]l`, `[l`, `g'`) are available in operator-pending mode. SmartMotion's own operators (`d`, `y`, `c`, `p`, `P`) and standalone actions (`gs`, `saa`, `gmd`, `gmy`, `gm`) are not — they handle operations internally.

---

## 🪟 Multi-Window Jumping

Search, treesitter navigation, and diagnostic motions collect targets from **all visible splits** — not just the current window. Labels from the current window get priority (closer targets get single-character labels), and selecting a label in another window jumps your cursor there.

Enabled by default for:
- **Search**: `s`, `f`, `F`, `t`, `T`, `;`, `,`, `gs`
- **Treesitter navigation**: `]]`, `[[`, `]c`, `[c`, `]b`, `[b`
- **Diagnostics**: `]d`, `[d`, `]e`, `[e`
- **Git**: `]g`, `[g`
- **Quickfix**: `]q`, `[q`, `]l`, `[l`
- **Marks**: `g'`, `gm`

Word and line motions (`w`, `b`, `e`, `ge`, `j`, `k`) stay single-window — directional motions within one window are the natural UX.

Multi-window is automatically disabled in operator-pending mode, since vim operators expect cursor movement within the same buffer.

---

## 🕰️ Motion History

Every motion you take through SmartMotion is recorded. Press `g.` to open a full-featured history browser with **pins**, **frecency ranking**, and **remote actions**:

```
 1  *  "authenticate"            auth.lua:42
 2  *  "render"                  app.tsx:15
────────────────────────────────────────────────
 f  s   "config"          ████   config.lua:8     just now
 j  dw  "handle_error"    ███    server.lua:30    5m ago
 k  w   "validate"        ██     utils.lua:12     2h ago
```

**Pins** (`gp`) bookmark up to 9 locations — they stick to the top with number labels for instant access. **Frecency** ranks entries by how often and how recently you visit them — your most-used locations rise to the top automatically. **Action mode** lets you press `d`, `y`, or `c` inside the browser to delete, yank, or change a target's text remotely without ever navigating there.

Press a label to jump back instantly. If the buffer was closed, SmartMotion reopens it from the file path. History and pins persist across sessions — your frecency scores, visit counts, and bookmarks survive restarts.

This is a benefit unique to centralizing your motions through one plugin. Vim's jumplist tracks cursor positions, but SmartMotion's history tracks *intent* — what you did, where you did it, and when. Every `w`, `dw`, `cR`, `f`, `/`, `;` feeds the same history, building a complete picture of your editing session that you can navigate at any time.

---

## 🧩 Why SmartMotion?

Every motion plugin does one thing well. SmartMotion does all of them — and exposes the machinery so you can build your own.

### One Plugin, Compound Benefits

When all your motions flow through the same system, you get things no combination of separate plugins can offer:

- **Motion History** — every jump, search, delete, and change is recorded. Pin locations with `gp`, browse frecency-ranked history with `g.`, and act on targets remotely with `d`/`y`/`c` from the browser.
- **Composable operators** — `d`, `y`, `c` work with *every* motion: words, lines, search, treesitter nodes, diagnostics, marks.
- **Flow State** — chain any motion into any other motion without re-triggering.
- **Consistent labels** — the same home-row label system across 59+ keybindings. Learn it once.
- **One config** — enable, disable, or remap everything from a single `opts` table.

The more you use SmartMotion, the more valuable it becomes. Each motion feeds the history, each keystroke builds on the same muscle memory, and every new preset you enable works with everything else automatically.

### The Pipeline

Every motion flows through a composable pipeline:

```
Collector → Extractor → Modifier → Filter → Visualizer → Selection → Action
```

| Stage        | Role                                                        |
|--------------|-------------------------------------------------------------|
| **Collector**   | Gathers raw data (lines, treesitter nodes, diagnostics)  |
| **Extractor**   | Finds targets within collected data (words, lines, search matches) |
| **Modifier**    | Transforms targets (e.g., weight by distance)            |
| **Filter**      | Narrows targets (after cursor, before cursor, visible only) |
| **Visualizer**  | Renders hint labels on targets                           |
| **Selection**   | User picks a target via label keypress                   |
| **Action**      | Executes on the selected target (jump, delete, yank, change) |

Every stage is a module. Swap any stage, combine actions, or write your own. Register a custom motion in a few lines:

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

Combine actions with `merge`:

```lua
local sm = require("smart-motion")

sm.motions.register("jump_and_yank", {
  collector = "lines",
  extractor = "words",
  filter = "filter_words_after_cursor",
  visualizer = "hint_start",
  action = sm.merge_actions({ "jump", "yank" }),
  map = true,
  modes = { "n" },
  trigger = "<leader>y",
})
```

For a full guide on building custom motions, see the [Wiki](https://github.com/FluxxField/smart-motion.nvim/wiki/Building-Custom-Motions).

---

<details>
<summary><h2>⚙️ Configuration</h2></summary>

Full default configuration:

```lua
{
  -- Characters used for hint labels (home row first for speed)
  keys = "fjdksleirughtynm",

  -- Use background highlighting instead of character replacement
  use_background_highlights = false,

  -- Highlight groups (string = existing group, table = custom definition)
  highlight = {
    hint = "SmartMotionHint",               -- { fg = "#FF2FD0" }
    hint_dim = "SmartMotionHintDim",
    two_char_hint = "SmartMotionTwoCharHint", -- { fg = "#2FD0FF" }
    two_char_hint_dim = "SmartMotionTwoCharHintDim",
    dim = "SmartMotionDim",                 -- "Comment"
    search_prefix = "SmartMotionSearchPrefix",
    search_prefix_dim = "SmartMotionSearchPrefixDim",
  },

  -- Enable/disable preset groups
  presets = {},

  -- Flow state timeout in milliseconds
  flow_state_timeout_ms = 300,

  -- Disable dimming of non-target text
  disable_dim_background = false,

  -- Maximum motions stored in repeat history
  history_max_size = 20,

  -- Automatically select when only one target exists
  auto_select_target = false,

  -- Enable label overlay during native / search (toggle with <C-s>)
  native_search = true,

  -- How count prefix interacts with motions (j/k): "target" or "native"
  count_behavior = "target",
}
```

### 🎨 Highlight Customization

Highlight values accept either a string (existing highlight group name) or a table (color definition):

| Group | Default | Description |
|-------|---------|-------------|
| `hint` | `SmartMotionHint` | Primary jump label |
| `hint_dim` | `SmartMotionHintDim` | Dimmed secondary label |
| `two_char_hint` | `SmartMotionTwoCharHint` | Two-character jump label |
| `two_char_hint_dim` | `SmartMotionTwoCharHintDim` | Dimmed two-character label |
| `dim` | `SmartMotionDim` | Backdrop for non-target text |
| `search_prefix` | `SmartMotionSearchPrefix` | Search prefix label |
| `search_prefix_dim` | `SmartMotionSearchPrefixDim` | Dimmed search prefix |
| `selected` | `SmartMotionSelected` | Multi-cursor selected target |

```lua
highlight = {
  hint = { fg = "#FF2FD0" },
  two_char_hint = { fg = "#2FD0FF" },
  dim = "Comment",
}
```

Toggle background-style hints:

```lua
opts = {
  use_background_highlights = true,
}
```

For full configuration documentation, see the [Wiki](https://github.com/FluxxField/smart-motion.nvim/wiki/Configuration).

</details>

---

## 📦 Alternatives

SmartMotion is inspired by and aims to unify the best ideas from:

- [hop.nvim](https://github.com/phaazon/hop.nvim)
- [flash.nvim](https://github.com/folke/flash.nvim)
- [lightspeed.nvim](https://github.com/ggandor/lightspeed.nvim)
- [leap.nvim](https://github.com/ggandor/leap.nvim)
- [mini.jump](https://github.com/echasnovski/mini.nvim#mini.jump)

---

## 📜 License

Licensed under [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html).

## 👤 Author

Built by [FluxxField](https://github.com/FluxxField)

---

## 📖 Documentation

Visit the **[Wiki](https://github.com/FluxxField/smart-motion.nvim/wiki)** for full documentation:

- **[Home](https://github.com/FluxxField/smart-motion.nvim/wiki)** — Overview and introduction
- **[Why SmartMotion?](https://github.com/FluxxField/smart-motion.nvim/wiki/Why-SmartMotion)** — Philosophy and comparison with alternatives
- **[Quick Start](https://github.com/FluxxField/smart-motion.nvim/wiki/Quick-Start)** — Install and configure in 60 seconds
- **[Presets Guide](https://github.com/FluxxField/smart-motion.nvim/wiki/Presets)** — All 13 presets and 59+ keybindings
- **[Build Your Own](https://github.com/FluxxField/smart-motion.nvim/wiki/Building-Custom-Motions)** — Create custom motions in minutes
- **[Configuration](https://github.com/FluxxField/smart-motion.nvim/wiki/Configuration)** — All options explained
- **[API Reference](https://github.com/FluxxField/smart-motion.nvim/wiki/API-Reference)** — Complete module reference
