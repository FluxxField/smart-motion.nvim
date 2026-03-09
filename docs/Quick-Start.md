# Quick Start

Get SmartMotion running in 60 seconds.

---

## Installation

### lazy.nvim

```lua
{
  "FluxxField/smart-motion.nvim",
  opts = {
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
    },
  },
}
```

### packer.nvim

```lua
use {
  "FluxxField/smart-motion.nvim",
  config = function()
    require("smart-motion").setup({
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
      },
    })
  end,
}
```

---

## Try It Now

Restart Neovim (or source your config), then:

### 1. Jump to a Word
Press `w` → labels appear on words ahead → press a label → cursor jumps there

### 2. Delete to a Word
Press `d` → press `w` → labels appear → press a label → text deleted from cursor to that word

### 3. Search and Jump
Press `s` → type characters → labels appear on matches as you type → press a label

### 4. Jump to a Function
Press `]]` → labels appear on all function definitions → press a label

### 5. Delete Around Function
Press `daf` → labels appear on all functions → select one → entire function deleted

### 6. Delete an Argument
With cursor in a function call, press `daa` → labels appear on arguments → select one → argument deleted (including comma)

---

## What You Just Got

With all presets enabled, you have **140+ keybindings**:

| Preset | Keys |
|--------|------|
| **words** | `w` `b` `e` `ge` |
| **lines** | `j` `k` |
| **search** | `s` `S` `f` `F` `t` `T` `;` `,` `gs` |
| **delete** | `d` `dt` `dT` `rdw` `rdl` |
| **yank** | `y` `yt` `yT` `ryw` `ryl` |
| **change** | `c` `ct` `cT` |
| **paste** | `p` `P` |
| **treesitter** | `]]` `[[` `]c` `[c` `]b` `[b` `af` `if` `ac` `ic` `aa` `ia` `fn` `saa` `gS` `R` |
| **diagnostics** | `]d` `[d` `]e` `[e` |
| **git** | `]g` `[g` |
| **quickfix** | `]q` `[q` `]l` `[l` |
| **marks** | `g'` `gm` |
| **misc** | `.` `g.` `g0` `g1`-`g9` `gp` `gp1`-`gp9` `gP` `gA`-`gZ` `gmd` `gmy` |

→ See **[Presets Guide](Presets.md)** for detailed explanations of each.

---

## Enable Only What You Want

Don't want to override native keys? Enable selectively:

```lua
presets = {
  -- Only enable these presets
  search = true,
  treesitter = true,
  diagnostics = true,
}
```

Or enable a preset but exclude specific keys:

```lua
presets = {
  words = {
    e = false,   -- don't override 'e'
    ge = false,  -- don't override 'ge'
  },
  search = true,
}
```

---

## Customize Labels

Change the hint characters (home row recommended):

```lua
opts = {
  keys = "fjdksleirughtynm",  -- default
  -- or for Colemak:
  -- keys = "arstneio",
}
```

Change colors:

```lua
opts = {
  highlight = {
    hint = { fg = "#FF2FD0" },
    two_char_hint = { fg = "#2FD0FF" },
    dim = "Comment",
  },
}
```

---

## Essential Settings

```lua
opts = {
  -- Hint characters (first char = most common)
  keys = "fjdksleirughtynm",

  -- Flow state timeout (ms) - how long between motions to stay in "flow"
  flow_state_timeout_ms = 300,

  -- Auto-jump when only one target exists
  auto_select_target = false,

  -- Show labels during native / search (toggle with <C-s>)
  native_search = true,

  -- Dim non-target text
  dim_background = true,

  -- Open folds at target position after jumping
  open_folds_on_jump = true,

  -- Save position to jumplist before jumping (j/k excluded to match native vim)
  save_to_jumplist = true,

  -- Search auto-proceed timeout (ms)
  search_timeout_ms = 500,

  -- Yank highlight flash duration (ms)
  yank_highlight_duration = 150,
}
```

---

## What's Next?

You're ready to use SmartMotion. Here's where to go next:

### Learn the Keybindings
→ **[Presets Guide](Presets.md)**: Every preset explained with examples

### Understand the Power
→ **[Advanced Features](Advanced-Features.md)**: Flow state, multi-window, operator-pending mode

### Build Your Own
→ **[Build Your Own Motions](Building-Custom-Motions.md)**: Create custom motions in minutes

### Configure Everything
→ **[Configuration](Configuration.md)**: All options explained
