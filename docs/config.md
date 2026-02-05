# Configuration Guide

This guide explains how to configure SmartMotion using `setup({ ... })`, what the default options look like, and how your configuration is passed into the pipeline.

---

## ⚙️ Default Config

Here’s what the default config looks like internally:

```lua
local default_config = {
  keys = "fjdksleirughtynm", -- Keys used for hints
  use_background_highlights = false, -- Toggles between character and background highlights
  highlight = { -- Highlights used for hints
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
  native_search = true, -- incremental labels during / search (toggle with <C-s>)
}
```

> [!NOTE]
> The `highlight` values can either be highlight group names (strings) or tables with custom colors (`{ fg = "#HEX" }`).

---

## 🧪 Simple Config Example

```lua
return {
  "FluxxField/smart-motion.nvim",
  opts = {},
}
```

This will use all default settings — no presets, default highlight groups, and default label keys.

---

## ✅ Enable All Presets

```lua
return {
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
      misc = true,
    },
  },
}
```

You can also exclude individual motions:

```lua
presets = {
  words = { "w", "b" },
  delete = false,
}
```

---

## 🎨 Override Highlights

```lua
highlight = {
  hint = { fg = "#FF2FD0" },
  two_char_hint = { fg = "#2FD0FF" },
  dim = { fg = "Comment" },
}
```

This allows SmartMotion to fit your theme or visual system.

You can also use the toggle use_background_highlights to change between character and background hints

```lua
opts = {
  use_background_highlights = true,
}
```

---

## 🧷 Change Keys

```lua
keys = "arstneio"
```

This defines the keys used for labeling. The string should contain only unique, lowercase characters.

> [!IMPORTANT]
> The number of unique targets you can display depends on how many keys you define. With `N` keys, SmartMotion can create up to `N^2` unique 2-character labels. If you use too few keys, you may not be able to label all targets.

---

## 🔁 Passing Config to Modules and Why It Matters

Every module receives:

- `ctx`: context like `bufnr`, `winid`, `cursor_line`
- `cfg`: your full `setup()` config
- `motion_state`: shared mutable state for the current motion

> [!TIP]
> This means `cfg` is available inside **collectors, extractors, filters, visualizers, actions, and wrappers**.
>
> [!NOTE]
> The reason `cfg` is passed to all modules is to support advanced behavior as SmartMotion evolves. For example:
>
> - A future setting like `flow_timeout` (for how fast you must press to chain motions) may be needed by visualizers or wrappers.
> - A `debug` flag could enable extra logging in actions.
> - A `max_targets` setting might help collectors limit result size.
>
> Passing `cfg` gives you full access to your own global settings inside any stage of the motion pipeline.

---

## 🔧 Registering Inside `config = function()`

If you're using Lazy.nvim or another plugin manager, this is the best place to register custom modules or motions:

```lua
return {
  "FluxxField/smart-motion.nvim",
  config = function()
    local sm = require("smart-motion")
    sm.register_motion("x", { ... })
    sm.filters.register("my_filter", MyFilter)
  end,
}
```

This ensures all your code runs after SmartMotion is loaded and configured.

---

Next:

- [`custom_motion.md`](./custom_motion.md)
- [`presets.md`](./presets.md)
