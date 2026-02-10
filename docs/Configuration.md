# Configuration

Complete guide to configuring SmartMotion.

---

## Default Configuration

```lua
{
  -- Characters used for hint labels (first = most common targets)
  keys = "fjdksleirughtynm",

  -- Use background highlighting instead of character replacement
  use_background_highlights = false,

  -- Highlight groups
  highlight = {
    hint = "SmartMotionHint",
    hint_dim = "SmartMotionHintDim",
    two_char_hint = "SmartMotionTwoCharHint",
    two_char_hint_dim = "SmartMotionTwoCharHintDim",
    dim = "SmartMotionDim",
    search_prefix = "SmartMotionSearchPrefix",
    search_prefix_dim = "SmartMotionSearchPrefixDim",
    selected = "SmartMotionSelected",
  },

  -- Enable/disable preset groups
  presets = {},

  -- Flow state timeout (ms): how long to stay in "flow" between motions
  flow_state_timeout_ms = 300,

  -- Disable dimming of non-target text
  disable_dim_background = false,

  -- Maximum motions stored in repeat history
  history_max_size = 20,

  -- Automatically jump when only one target exists
  auto_select_target = false,

  -- Show labels during native / search (toggle with <C-s>)
  native_search = true,

  -- How count prefix interacts with motions (j/k), "target" or "native"
  count_behavior = "target",
}
```

---

## Hint Keys

The `keys` string defines which characters are used for labels:

```lua
keys = "fjdksleirughtynm"  -- default, home row focused
```

**Tips:**
- Put most-used keys first (they're assigned to closest targets)
- Use home row keys for speed
- More keys = more single-character labels before needing two-character

**Alternative layouts:**

```lua
-- Colemak
keys = "arstneio"

-- Dvorak
keys = "aoeuhtns"

-- Minimal (fewer keys, more double-character labels)
keys = "fjdksl"

-- Extended (more single-character coverage)
keys = "fjdksleirughtynmcvbxzaoqp"
```

**How labels are assigned:**
- With N keys, you get N single-character labels
- Two-character labels use combinations (N² possible)
- Closest targets get shortest labels

---

## Presets

Enable motion groups:

```lua
presets = {
  words = true,        -- w, b, e, ge
  lines = true,        -- j, k
  search = true,       -- s, S, f, F, t, T, ;, ,, gs
  delete = true,       -- d, dt, dT, rdw, rdl
  yank = true,         -- y, yt, yT, ryw, ryl
  change = true,       -- c, ct, cT
  paste = true,        -- p, P
  treesitter = true,   -- ]], [[, ]c, [c, ]b, [b, af, if, ac, ic, aa, ia, fn, saa, gS, R
  diagnostics = true,  -- ]d, [d, ]e, [e
  git = true,          -- ]g, [g
  quickfix = true,     -- ]q, [q, ]l, [l
  marks = true,        -- g', gm
  misc = true,         -- . g. g0 g1-g9 gp gP gA-gZ gmd gmy (repeat, history, pins, global pins)
}
```

### Selective Enable

```lua
presets = {
  search = true,
  treesitter = true,
  -- others disabled
}
```

### Exclude Specific Keys

```lua
presets = {
  words = {
    e = false,   -- don't override 'e'
    ge = false,  -- don't override 'ge'
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
      map = false,  -- register but don't auto-map
    },
  },
}
```

Map manually later:
```lua
require("smart-motion").map_motion("w")
```

See **[Presets Guide](Presets.md)** for complete preset documentation.

For practical examples of what you can customize (multiline f, single-char find, camelCase words, and more), see the **[Recipes](Recipes.md)** guide.

---

## Highlights

Customize colors with tables or existing highlight group names:

```lua
highlight = {
  -- Custom colors
  hint = { fg = "#FF2FD0", bold = true },
  two_char_hint = { fg = "#2FD0FF" },

  -- Use existing highlight groups
  dim = "Comment",
  selected = "Visual",
}
```

### Available Groups

| Group | Default | Purpose |
|-------|---------|---------|
| `hint` | SmartMotionHint | Primary single-char label |
| `hint_dim` | SmartMotionHintDim | Dimmed single-char label |
| `two_char_hint` | SmartMotionTwoCharHint | Two-char label |
| `two_char_hint_dim` | SmartMotionTwoCharHintDim | Dimmed two-char label |
| `dim` | SmartMotionDim | Background dim for non-targets |
| `search_prefix` | SmartMotionSearchPrefix | Search text prefix |
| `search_prefix_dim` | SmartMotionSearchPrefixDim | Dimmed search prefix |
| `selected` | SmartMotionSelected | Multi-cursor selected targets |

### Custom Color Table

```lua
{
  fg = "#RRGGBB",     -- foreground color
  bg = "#RRGGBB",     -- background color
  bold = true,        -- bold text
  italic = true,      -- italic text
  underline = true,   -- underlined text
}
```

### Background Mode

Switch to background highlighting (label on background, text unchanged):

```lua
use_background_highlights = true
```

---

## Flow State

Flow state enables rapid motion chaining:

```lua
flow_state_timeout_ms = 300  -- default
```

**How it works:**
1. Trigger a motion, select a target
2. Within timeout, press another motion key
3. Labels appear instantly, you're in flow

**Adjust timing:**
```lua
flow_state_timeout_ms = 500  -- slower, more forgiving
flow_state_timeout_ms = 150  -- faster, for experienced users
flow_state_timeout_ms = 0    -- disable flow state
```

---

## Native Search

Enable label overlay during `/` and `?` search:

```lua
native_search = true  -- default
```

**How it works:**
1. Press `/` and type your search
2. Labels appear on matches as you type
3. Press Enter → cmdline closes, labels remain
4. Press a label to jump

**Toggle during search:** Press `<C-s>` to turn labels on/off.

**Disable:**
```lua
native_search = false
```

---

## Auto Select

Automatically jump when only one target exists:

```lua
auto_select_target = true  -- default: false
```

When enabled, if your motion finds exactly one target, it jumps immediately without showing labels.

---

## Count Behavior

Control what happens when a count precedes a motion like `j` or `k`:

```lua
count_behavior = "target"  -- default
```

**`"target"` (default):** The count selects the Nth target directly: no labels shown, instant jump. `5j` jumps to the 5th line target below the cursor. If the count exceeds available targets, it clamps to the last one.

**`"native"`:** The count bypasses SmartMotion entirely and feeds the native vim motion. `5j` moves 5 lines down, exactly like vanilla vim.

```lua
-- Jump to the 5th target (default)
count_behavior = "target"

-- Pass through to native vim motion
count_behavior = "native"
```

**Currently applies to:** `j`, `k`

---

## Background Dimming

Dim non-target text for better label visibility:

```lua
disable_dim_background = false  -- dimming enabled (default)
disable_dim_background = true   -- dimming disabled
```

---

## History

Configure motion history size:

```lua
history_max_size = 20  -- default
history_max_size = 50  -- keep more history
history_max_size = 0   -- effectively disables persistence
```

Controls how many entries are stored for both `.` (repeat) and `g.` (history browser). History persists across Neovim sessions, stored per-project in `~/.local/share/nvim/smart-motion/history/`. Entries older than 30 days or pointing to deleted files are automatically pruned.

See **[Advanced Features: Motion History](Advanced-Features.md#motion-history)** for full details.

---

## Complete Example

```lua
{
  "FluxxField/smart-motion.nvim",
  opts = {
    -- Colemak-friendly keys
    keys = "arstneiodhqwfpgjluy",

    -- Slightly longer flow timeout
    flow_state_timeout_ms = 400,

    -- Auto-jump on single target
    auto_select_target = true,

    -- Count selects nth target for j/k
    count_behavior = "target",

    -- Custom highlights
    highlight = {
      hint = { fg = "#FF6B6B", bold = true },
      two_char_hint = { fg = "#4ECDC4" },
      dim = "Comment",
    },

    -- Enable most presets, customize some
    presets = {
      words = true,
      lines = true,
      search = {
        s = true,
        S = true,
        f = true,
        F = true,
        t = true,
        T = true,
        gs = false,  -- don't need visual select
      },
      delete = true,
      yank = true,
      change = true,
      paste = false,  -- use native paste
      treesitter = true,
      diagnostics = true,
      git = true,
      quickfix = true,
      marks = true,
      misc = true,
    },

    -- Disable native search labels
    native_search = false,
  },
}
```

---

## With config Function

For more control, use a config function:

```lua
{
  "FluxxField/smart-motion.nvim",
  config = function()
    local sm = require("smart-motion")

    sm.setup({
      keys = "fjdksleirughtynm",
      presets = {
        words = true,
        search = true,
        treesitter = true,
      },
    })

    -- Register custom motions after setup
    sm.register_motion("<leader>j", {
      collector = "lines",
      extractor = "words",
      filter = "filter_words_after_cursor",
      visualizer = "hint_start",
      action = "jump_centered",
      map = true,
      modes = { "n", "v" },
    })

    -- Register custom modules
    local registries = require("smart-motion.core.registries"):get()
    registries.filters.register("my_filter", MyFilterModule)
  end,
}
```

---

## Next Steps

→ **[Presets Guide](Presets.md)**: All presets explained

→ **[Building Custom Motions](Building-Custom-Motions.md)**: Create your own

→ **[Advanced Features](Advanced-Features.md)**: Flow state, multi-window, more
