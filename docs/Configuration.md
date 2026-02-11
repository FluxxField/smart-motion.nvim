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

  -- Open folds at target position after jumping
  open_folds_on_jump = true,

  -- Save position to jumplist before jumping
  save_to_jumplist = true,

  -- Maximum number of pin slots
  max_pins = 9,

  -- Search timeout: auto-proceed to label selection after typing (ms)
  search_timeout_ms = 500,

  -- Search idle timeout: exit search if no input typed (ms)
  search_idle_timeout_ms = 2000,

  -- Yank highlight flash duration (ms)
  yank_highlight_duration = 150,

  -- Prune history entries older than this many days
  history_max_age_days = 30,
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

## Fold Handling

Control whether folds are opened when jumping to a target:

```lua
open_folds_on_jump = true   -- open folds at target (default)
open_folds_on_jump = false  -- keep folds closed
```

When enabled, SmartMotion runs `zv` after every jump to reveal the target line. This applies to all jump actions including pipeline jumps, history navigation, and pin jumps.

Disable this if you prefer folds to stay closed and want to open them manually.

---

## Jumplist

Control whether SmartMotion saves the current position to the jumplist before jumping:

```lua
save_to_jumplist = true   -- save to jumplist (default)
save_to_jumplist = false  -- don't save to jumplist
```

When enabled, `m'` is set before every jump so `<C-o>` takes you back. This applies to all jump actions including pipeline jumps, history navigation, and pin jumps.

Disable this if you don't want SmartMotion populating your jumplist, especially for frequent short hops.

---

## Pins

Configure the maximum number of pin slots:

```lua
max_pins = 9   -- default (labels 1-9)
max_pins = 20  -- more pin slots
```

Controls how many positions can be pinned via `gp`. Pin labels in the history browser use number keys (1-9 by default), so values above 9 will use letter labels for the extra slots.

---

## Search Timeouts

Tune how long search modes wait before auto-proceeding or exiting:

```lua
search_timeout_ms = 500       -- default: auto-proceed to labels after typing
search_idle_timeout_ms = 2000 -- default: exit search if nothing typed
```

**`search_timeout_ms`**: After you type in a search motion (`s`, `S`, `R`), this is how long SmartMotion waits before automatically proceeding to label selection. Lower values feel snappier; higher values give more time to refine your search.

**`search_idle_timeout_ms`**: If you trigger a search motion but don't type anything, SmartMotion exits after this timeout. Set higher if you need more thinking time.

```lua
search_timeout_ms = 300       -- fast typist, proceed quickly
search_timeout_ms = 800       -- slower, more time to type

search_idle_timeout_ms = 5000 -- very patient idle timeout
```

---

## Yank Highlight

Control how long the yank flash is shown after yanking with SmartMotion operators:

```lua
yank_highlight_duration = 150  -- default (ms)
yank_highlight_duration = 300  -- longer flash
yank_highlight_duration = 0    -- disable yank highlight
```

This is the SmartMotion equivalent of Neovim's `vim.hl.on_yank()` duration. Applies to `y` operator actions and treesitter search yanks.

---

## History

Configure motion history size:

```lua
history_max_size = 20  -- default
history_max_size = 50  -- keep more history
history_max_size = 0   -- effectively disables persistence
```

Controls how many entries are stored for both `.` (repeat) and `g.` (history browser). History persists across Neovim sessions, stored per-project in `~/.local/share/nvim/smart-motion/history/`. Entries pointing to deleted files are automatically pruned.

Configure how long history entries are retained:

```lua
history_max_age_days = 30  -- default
history_max_age_days = 90  -- keep entries longer
history_max_age_days = 7   -- aggressive pruning
```

Entries older than this are discarded when history is loaded at startup and during disk merges.

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

    -- Keep folds closed when jumping
    open_folds_on_jump = false,

    -- Don't pollute jumplist with SmartMotion jumps
    save_to_jumplist = false,

    -- More pin slots
    max_pins = 20,

    -- Faster search auto-proceed
    search_timeout_ms = 300,

    -- Longer yank flash
    yank_highlight_duration = 300,

    -- Keep history for 90 days
    history_max_age_days = 90,
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
