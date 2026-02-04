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
- 🔀 **Composable d/y/c/p** — `d` + any motion deletes, `y` + any motion yanks, `c` + any motion changes, with visual feedback at every step
- ✂️ **Until motions** — `dt`, `yt`, `ct` operate from cursor to a labeled character on the current line
- 📡 **Remote operations** — `rdw`, `rdl`, `ryw`, `ryl` delete or yank words and lines without moving the cursor
- 🌳 **Treesitter-aware motions** — jump to functions (`]]`/`[[`), classes (`]c`/`[c`), delete/change/yank function names (`dfn`, `cfn`, `yfn`), and arguments (`daa`, `caa`, `yaa`)
- 🩺 **Diagnostics jumping** — navigate all diagnostics (`]d`/`[d`) or errors only (`]e`/`[e`)
- 🔎 **2-char find** — `f`/`F` for leap-style two-character search with labels
- 🔍 **Live search** — `s` for incremental search with labeled results across all visible text
- 🪟 **Multi-window jumping** — search, treesitter, and diagnostic motions show labels across all visible splits. Select a label in another window and jump there instantly.
- ⚙️ **Operator-pending mode** — use SmartMotion motions with any vim operator (`>w`, `gUw`, `=j`, `gqj`, etc.)
- 🔁 **Repeat** — `.` repeats the last SmartMotion
- 🧩 **Fully modular pipeline** — Collector → Extractor → Modifier → Filter → Visualizer → Selection → Action. Every stage is replaceable. Build entirely custom motions from scratch.
- 📦 **10 presets, 40 keybindings** — enable what you want, disable what you don't

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
      search = true,       -- s, f, F
      delete = true,       -- d, dt, dT, rdw, rdl
      yank = true,         -- y, yt, yT, ryw, ryl
      change = true,       -- c, ct, cT
      paste = true,        -- p, P
      treesitter = true,   -- ]], [[, ]c, [c, daa, caa, yaa, dfn, cfn, yfn
      diagnostics = true,  -- ]d, [d, ]e, [e
      misc = true,         -- . (repeat)
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
| `j` | n, v, o | Jump to line after cursor    |
| `k` | n, v, o | Jump to line before cursor   |

</details>

<details>
<summary><b>🔍 Search</b> — <code>s</code> <code>f</code> <code>F</code> 🪟</summary>

| Key | Mode | Description                                          |
|-----|------|------------------------------------------------------|
| `s` | n, o | Live search across all visible text with labels      |
| `f` | n, o | 2-char find forward with labels                      |
| `F` | n, o | 2-char find backward with labels                     |

> Multi-window: labels appear in all visible splits.

</details>

<details>
<summary><b>🗑️ Delete</b> — <code>d</code> <code>dt</code> <code>dT</code> <code>rdw</code> <code>rdl</code></summary>

| Key   | Mode | Description                                    |
|-------|------|------------------------------------------------|
| `d`   | n    | Composable delete — press `d` then any motion  |
| `dt`  | n    | Delete from cursor until character (forward)   |
| `dT`  | n    | Delete from cursor until character (backward)  |
| `rdw` | n    | Remote delete word (cursor stays in place)      |
| `rdl` | n    | Remote delete line (cursor stays in place)      |

</details>

<details>
<summary><b>📋 Yank</b> — <code>y</code> <code>yt</code> <code>yT</code> <code>ryw</code> <code>ryl</code></summary>

| Key   | Mode | Description                                   |
|-------|------|-----------------------------------------------|
| `y`   | n    | Composable yank — press `y` then any motion   |
| `yt`  | n    | Yank from cursor until character (forward)    |
| `yT`  | n    | Yank from cursor until character (backward)   |
| `ryw` | n    | Remote yank word (cursor stays in place)       |
| `ryl` | n    | Remote yank line (cursor stays in place)       |

</details>

<details>
<summary><b>✏️ Change</b> — <code>c</code> <code>ct</code> <code>cT</code></summary>

| Key  | Mode | Description                                    |
|------|------|------------------------------------------------|
| `c`  | n    | Composable change — press `c` then any motion  |
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
<summary><b>🌳 Treesitter</b> — <code>]]</code> <code>[[</code> <code>]c</code> <code>[c</code> <code>daa</code> <code>caa</code> <code>yaa</code> <code>dfn</code> <code>cfn</code> <code>yfn</code> 🪟</summary>

| Key   | Mode | Description                                   |
|-------|------|-----------------------------------------------|
| `]]`  | n, o | Jump to next function                         |
| `[[`  | n, o | Jump to previous function                     |
| `]c`  | n, o | Jump to next class/struct                     |
| `[c`  | n, o | Jump to previous class/struct                 |
| `daa` | n    | Delete around argument (includes separator)   |
| `caa` | n    | Change argument                               |
| `yaa` | n    | Yank argument                                 |
| `dfn` | n    | Delete function name                          |
| `cfn` | n    | Change function name (rename)                 |
| `yfn` | n    | Yank function name                            |

Works across Lua, Python, JavaScript, TypeScript, Rust, Go, C, C++, Java, C#, and Ruby. Non-matching node types are safely ignored.

> Multi-window: navigation motions (`]]`, `[[`, `]c`, `[c`) show labels across all visible splits. Editing motions stay in the current buffer.

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
<summary><b>🔁 Misc</b> — <code>.</code></summary>

| Key | Mode | Description            |
|-----|------|------------------------|
| `.` | n    | Repeat last SmartMotion |

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

All jump-only motions (`w`, `b`, `e`, `ge`, `j`, `k`, `s`, `f`, `F`, `]]`, `[[`, `]c`, `[c`, `]d`, `[d`, `]e`, `[e`) are available in operator-pending mode. SmartMotion's own operators (`d`, `y`, `c`, `p`, `P`) are not — they handle operators internally via inference.

---

## 🪟 Multi-Window Jumping

Search, treesitter navigation, and diagnostic motions collect targets from **all visible splits** — not just the current window. Labels from the current window get priority (closer targets get single-character labels), and selecting a label in another window jumps your cursor there.

Enabled by default for:
- **Search**: `s`, `f`, `F`
- **Treesitter navigation**: `]]`, `[[`, `]c`, `[c`
- **Diagnostics**: `]d`, `[d`, `]e`, `[e`

Word and line motions (`w`, `b`, `e`, `ge`, `j`, `k`) stay single-window — directional motions within one window are the natural UX.

Multi-window is automatically disabled in operator-pending mode, since vim operators expect cursor movement within the same buffer.

---

## 🧩 Why SmartMotion?

Every motion plugin does one thing well. SmartMotion does all of them — and exposes the machinery so you can build your own.

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

For a full guide on building custom motions, see [docs/custom_motion.md](./docs/custom_motion.md).

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

For full configuration documentation, see [docs/config.md](./docs/config.md).

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

📖 For full documentation, visit the [docs/](./docs) directory:

- [Configuration](./docs/config.md)
- [Presets](./docs/presets.md)
- [Custom Motions](./docs/custom_motion.md)
- [Overview](./docs/overview.md)
