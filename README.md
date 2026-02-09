# SmartMotion.nvim

```
   _____                      __  __  ___      __  _                          _
  / ___/____ ___  ____ ______/ /_/  |/  /___  / /_(_)___  ____    ____ _   __(_)___ ___
  \__ \/ __ `__ \/ __ `/ ___/ __/ /|_/ / __ \/ __/ / __ \/ __ \  / __ \ | / / / __ `__ \
 ___/ / / / / / / /_/ / /  / /_/ /  / / /_/ / /_/ / /_/ / / / / / / / / |/ / / / / / / /
/____/_/ /_/ /_/\__,_/_/   \__/__/  /_/\____/\__/_/\____/_/ /_(_)__/ /_/|___/_/_/ /_/ /_/
```

A motion framework for Neovim. Enable a motion, enable an operator. They compose automatically.

![SmartMotion in action](assets/smart-motion-showcase.gif)

---

## Quick Start

```lua
{
  "FluxxField/smart-motion.nvim",
  opts = {
    presets = {
      words = true,        -- w, b, e, ge
      lines = true,        -- j, k
      search = true,       -- s, S, f, F, t, T, ;, ,
      delete = true,       -- d + any motion
      yank = true,         -- y + any motion
      change = true,       -- c + any motion
      treesitter = true,   -- ]], [[, af, if, ac, ic, aa, ia, fn, saa, gS, R
      diagnostics = true,  -- ]d, [d, ]e, [e
      misc = true,         -- . g. g0 g1-g9 gp (repeat, history, pins)
    },
  },
}
```

Everything is opt-in. Enable only what you want. Disable individual keys within a preset too:

```lua
presets = {
  words = { e = false, ge = false },  -- only w and b
  search = { s = false },             -- keep native s (substitute)
}
```

---

## What Happens When You Use It

**Press `w`.** Labels appear on every word ahead of your cursor. Press a label and you're there. No counting, no guessing. You looked at the word, you pressed `w`, you pressed the label.

**Press `dw`.** Same labels appear. Press one and that word is deleted. Press `w` again instead (`dww`) and the word under your cursor is deleted. `yw`, `cw`, `pw` all work the same way.

**That's the entire mental model.** Motion key shows targets. Label picks one. Operator + motion shows targets and acts on your pick.

---

## Why This Is Different

### Composable operators with zero explicit mappings

Enable `words` and `delete` as presets. Now `dw`, `db`, `de`, `dge` all work. Enable `search` and `ds`, `dS`, `df`, `dt` work too. Enable `lines` and you get `dj`, `dk`. Every motion preset **multiplies** with every operator preset:

```
11 composable motions  ×  5 operators  =  55+ compositions
         from 16 keys, zero mappings defined
```

Unknown keys fall through to native Vim. `d$`, `d0`, `dG` work exactly as expected.

### Flow State chains motions without labels

Select a target, then press any motion key within 300ms for instant movement with no labels. Chain different motions: `w` → `j` → `b` → `w`, all without hints.

**Hold `w`.** Labels flash once, then it moves word-by-word like native Vim. That's Flow State.

```
w  [labels]  f  → jump        (within 300ms)
                  j  → instant   (within 300ms)
                       b  → instant   (within 300ms)
                            w  → instant
```

### Text objects that work with any operator

`af`, `if`, `ac`, `ic`, `aa`, `ia` are real text objects in operator-pending and visual mode. They work with everything, not just `d`/`y`/`c`:

```
daf   delete a function       gqaf  format a function
yaa   yank an argument        =if   indent a function body
cic   change inside a class   >ac   indent a class
```

### It's a framework, not just a plugin

Every built-in motion uses the same public API:

```lua
require("smart-motion").register_motion("custom_jump", {
  collector = "lines",
  extractor = "words",
  filter = "filter_words_after_cursor",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n", "v" },
})
```

Collector → Extractor → Modifier → Filter → Visualizer → Selection → Action. Every stage is swappable. Register custom collectors, extractors, filters, actions. Build motions that don't exist yet.

---

## All Presets

<details>
<summary><b>Words</b>: <code>w</code> <code>b</code> <code>e</code> <code>ge</code></summary>

| Key  | Mode    | Description                          |
|------|---------|--------------------------------------|
| `w`  | n, v, o | Jump to start of word after cursor   |
| `b`  | n, v, o | Jump to start of word before cursor  |
| `e`  | n, v, o | Jump to end of word after cursor     |
| `ge` | n, v, o | Jump to end of word before cursor    |

Works with any operator in operator-pending mode: `>w`, `gUw`, `=w`

</details>

<details>
<summary><b>Lines</b>: <code>j</code> <code>k</code></summary>

| Key | Mode    | Description                  |
|-----|---------|------------------------------|
| `j` | n, v, o | Jump to line after cursor (supports count: `5j`)  |
| `k` | n, v, o | Jump to line before cursor (supports count: `3k`) |

Works with any operator: `=j`, `gqj`, `>j`

</details>

<details>
<summary><b>Search</b>: <code>s</code> <code>S</code> <code>f</code> <code>F</code> <code>t</code> <code>T</code> <code>;</code> <code>,</code> <code>gs</code></summary>

| Key  | Mode | Description                                          |
|------|------|------------------------------------------------------|
| `s`  | n, o | Live search with labels across all visible text      |
| `S`  | n, o | Fuzzy search: type partial patterns to match words   |
| `f`  | n, o | 2-char find forward (inclusive, line-constrained)    |
| `F`  | n, o | 2-char find backward (inclusive, line-constrained)   |
| `t`  | n, o | 2-char till forward (exclusive, line-constrained)    |
| `T`  | n, o | 2-char till backward (exclusive, line-constrained)   |
| `;`  | n, v | Repeat last f/F/t/T (same direction)                 |
| `,`  | n, v | Repeat last f/F/t/T (reversed direction)             |
| `gs` | n    | Visual select: pick two targets, enter visual mode   |

Multi-window: `s` and `S` show labels across all visible splits. Label conflict avoidance ensures labels can't be valid search continuations.

`f`/`F`/`t`/`T` can be made multi-line or multi-window. See [Customizing Motions](#customizing-motions).

</details>

<details>
<summary><b>Operators</b>: <code>d</code> <code>y</code> <code>c</code> <code>p</code> <code>P</code> + any motion</summary>

Press an operator, then any motion key. Labels appear, pick a target, action runs:

| Combo | What it does |
|-------|-------------|
| `dw`  | Labels words after cursor → pick one → delete it |
| `ds`  | Live search → pick match → delete it |
| `df`  | 2-char find → delete from cursor to target (inclusive) |
| `dt`  | 2-char till → delete from cursor to just before target |
| `dd`  | Delete current line |

All work identically with `y` (yank), `c` (change), `p`/`P` (paste).

Repeat the motion key for the target under cursor: `dww` = delete this word, `yww` = yank this word.

**Remote operations** (cursor stays in place):

| Key   | Description                |
|-------|----------------------------|
| `rdw` | Remote delete word         |
| `rdl` | Remote delete line         |
| `ryw` | Remote yank word           |
| `ryl` | Remote yank line           |

</details>

<details>
<summary><b>Treesitter</b>: <code>]]</code> <code>[[</code> <code>]c</code> <code>[c</code> <code>]b</code> <code>[b</code> + text objects + <code>saa</code> <code>gS</code> <code>R</code></summary>

**Navigation** (multi-window):

| Key   | Mode    | Description                          |
|-------|---------|--------------------------------------|
| `]]`  | n, o    | Jump to next function                |
| `[[`  | n, o    | Jump to previous function            |
| `]c`  | n, o    | Jump to next class/struct            |
| `[c`  | n, o    | Jump to previous class/struct        |
| `]b`  | n, o    | Jump to next block/scope             |
| `[b`  | n, o    | Jump to previous block/scope         |

**Text objects** (work with ANY operator: `daf`, `gqaf`, `=if`, `>ac`):

| Key   | Mode    | Description                          |
|-------|---------|--------------------------------------|
| `af`  | x, o    | Around function                      |
| `if`  | x, o    | Inside function body                 |
| `ac`  | x, o    | Around class/struct                  |
| `ic`  | x, o    | Inside class/struct body             |
| `aa`  | x, o    | Around argument (includes separator) |
| `ia`  | x, o    | Inside argument                      |
| `fn`  | o       | Function name (`dfn`, `cfn`, `yfn`)  |

**Advanced**:

| Key   | Mode       | Description                                    |
|-------|------------|------------------------------------------------|
| `saa` | n          | Swap two arguments                             |
| `gS`  | n, x       | Incremental select (`;` expand, `,` shrink)    |
| `R`   | n, x, o    | Search text → pick match → pick syntax scope   |

Works across Lua, Python, JavaScript, TypeScript, Rust, Go, C, C++, Java, C#, Ruby.

</details>

<details>
<summary><b>Diagnostics</b>: <code>]d</code> <code>[d</code> <code>]e</code> <code>[e</code></summary>

| Key  | Mode | Description                         |
|------|------|-------------------------------------|
| `]d` | n, o | Jump to next diagnostic             |
| `[d` | n, o | Jump to previous diagnostic         |
| `]e` | n, o | Jump to next error                  |
| `[e` | n, o | Jump to previous error              |

Multi-window. Works with operators: `d]d`, `y]e`

</details>

<details>
<summary><b>Git</b>: <code>]g</code> <code>[g</code></summary>

| Key  | Mode | Description                              |
|------|------|------------------------------------------|
| `]g` | n, o | Jump to next git hunk (changed region)   |
| `[g` | n, o | Jump to previous git hunk                |

Works best with [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim). Multi-window.

</details>

<details>
<summary><b>Quickfix</b>: <code>]q</code> <code>[q</code> <code>]l</code> <code>[l</code></summary>

| Key  | Mode | Description                              |
|------|------|------------------------------------------|
| `]q` | n, o | Jump to next quickfix entry              |
| `[q` | n, o | Jump to previous quickfix entry          |
| `]l` | n, o | Jump to next location list entry         |
| `[l` | n, o | Jump to previous location list entry     |

</details>

<details>
<summary><b>Marks</b>: <code>g'</code> <code>gm</code></summary>

| Key  | Mode | Description                                        |
|------|------|----------------------------------------------------|
| `g'` | n, o | Show labels on all marks, jump to selected         |
| `gm` | n    | Set mark at labeled target (prompts for mark name) |

</details>

<details>
<summary><b>Misc</b>: repeat, history, pins, global pins, multi-cursor</summary>

| Key          | Mode | Description                                          |
|--------------|------|------------------------------------------------------|
| `.`          | n    | Repeat last SmartMotion                              |
| `g.`         | n    | History browser with pins, frecency, preview, search, remote actions |
| `g0`         | n    | Jump to most recent location                         |
| `g1`-`g9`   | n    | Jump to pin 1-9                                      |
| `gp`         | n    | Toggle pin at cursor (up to 9)                       |
| `gp1`-`gp9` | n    | Set pin at specific slot                             |
| `gP`         | n    | Toggle global pin (cross-project, prompts A-Z)       |
| `gA`-`gZ`   | n    | Jump to global pin (works from any project)          |
| `gmd`        | n    | Multi-cursor delete: toggle-select, Enter to delete  |
| `gmy`        | n    | Multi-cursor yank: toggle-select, Enter to yank      |

**Pins workflow:** `gp` at main file → `gp` at test file → `gp` at config → now `g1` = main, `g2` = tests, `g3` = config.

</details>

---

## Operator-Pending Mode

SmartMotion motions work with **any Vim operator**:

```
>w    indent to labeled word       gUw   uppercase to labeled word
=j    auto-indent to labeled line  gqj   format to labeled line
>]]   indent to labeled function   zf]]  fold to labeled function
```

---

## Multi-Window

Search, treesitter, diagnostic, git, quickfix, and mark motions show labels across all visible splits. Select a label in another window and jump there.

Word and line motions stay single-window by default. See [Customizing Motions](#customizing-motions) for multi-window overrides.

---

## Customizing Motions

Individual motions can be tweaked by passing a table instead of `true`. For example, make `f`/`F` work across multiple lines:

```lua
presets = {
  search = {
    f = { filter = "filter_words_after_cursor" },
    F = { filter = "filter_words_before_cursor" },
  },
}
```

Add multi-window to find motions:

```lua
presets = {
  search = {
    f = {
      filter = "filter_words_after_cursor",
      metadata = { motion_state = { multi_window = true } },
    },
  },
}
```

You can override any motion property: `extractor`, `filter`, `visualizer`, `action`, `modes`, etc.

---

## What You're Replacing

With all presets enabled, SmartMotion consolidates:

```
flash.nvim          →  search, treesitter, labels
harpoon             →  pins (g1-g9, gp) + history (g.)
nvim-treesitter-    →  af/if/ac/ic/aa/ia text objects
  textobjects
mini.ai             →  around/inside objects
```

One plugin, one config. Your pins know about your history. Your text objects work with flow state. Your operators compose with motions you haven't thought of yet.

---

## Honest Comparison

<details>
<summary>Feature matrix vs hop, leap, flash</summary>

| Feature | hop | leap | flash | SmartMotion |
|---------|-----|------|-------|-------------|
| Word/line jumping | yes | yes | yes | yes |
| 2-char search | | yes | yes | yes |
| Live incremental search | | | yes | yes |
| Fuzzy search | | | | yes |
| Treesitter navigation | | | yes | yes |
| Treesitter text objects | | | | yes |
| Composable d/y/c/p | | | partial | full |
| Remote operations | | | yes | yes |
| Multi-window | | via plugin | yes | yes |
| Operator-pending mode | yes | yes | yes | yes |
| Label conflict avoidance | | | | yes |
| Flow state chaining | | | | yes |
| Multi-cursor selection | | | | yes |
| Argument swap | | | | yes |
| Visual range selection | | | | yes |
| Motion history + pins | | | | yes |
| Global cross-project pins | | | | yes |
| Extensible pipeline | | | | yes |
| Build custom motions | limited | limited | limited | full |

</details>

### When to choose something else

**[leap.nvim](https://github.com/ggandor/leap.nvim)**: The 2-character search UX is beautifully refined. If that's your primary motion pattern, leap's polish is hard to beat.

**[flash.nvim](https://github.com/folke/flash.nvim)**: The most feature-complete alternative. Excellent treesitter integration, large community. If you're happy with flash, it's a great plugin.

**[hop.nvim](https://github.com/phaazon/hop.nvim)**: Simpler and battle-tested. If you just need word/line jumping with hints, hop does its job with less surface area.

SmartMotion wouldn't exist without these plugins. See [Why SmartMotion](https://github.com/FluxxField/smart-motion.nvim/wiki/Why-SmartMotion) for the full story.

---

## Configuration

```lua
{
  keys = "fjdksleirughtynm",        -- label characters, home row first
  flow_state_timeout_ms = 300,       -- chaining window, 0 to disable
  disable_dim_background = false,    -- dim non-target text
  auto_select_target = false,        -- auto-jump on single target
  native_search = true,              -- labels during / search
  count_behavior = "target",         -- "target" or "native" for j/k counts
  history_max_size = 20,             -- persistent history entries
}
```

See [Configuration](https://github.com/FluxxField/smart-motion.nvim/wiki/Configuration) for the full reference.

---

## Documentation

- [Presets Guide](https://github.com/FluxxField/smart-motion.nvim/wiki/Presets): every preset explained in detail
- [Advanced Features](https://github.com/FluxxField/smart-motion.nvim/wiki/Advanced-Features): flow state, operator-pending, multi-window, history browser
- [Building Custom Motions](https://github.com/FluxxField/smart-motion.nvim/wiki/Building-Custom-Motions): create your own with the pipeline API
- [Pipeline Architecture](https://github.com/FluxxField/smart-motion.nvim/wiki/Pipeline-Architecture): how the framework works internally
- [API Reference](https://github.com/FluxxField/smart-motion.nvim/wiki/API-Reference): full module and motion_state reference
- [Configuration](https://github.com/FluxxField/smart-motion.nvim/wiki/Configuration): all settings

---

## License

[GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html)

Built by [FluxxField](https://github.com/FluxxField)
