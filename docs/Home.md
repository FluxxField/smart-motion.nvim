# SmartMotion.nvim

> A motion framework for Neovim. Enable a motion, enable an operator. They compose automatically.

---

## What if you could build any motion you can imagine?

Other motion plugins give you a fixed set of features. SmartMotion gives you a **pipeline architecture** where every motion flows through composable stages:

```
Collector → Extractor → Modifier → Filter → Visualizer → Selection → Action
```

This isn't just a plugin. It's a **framework**. The 140+ built-in keybindings? They're all built on the same system you can use to create your own.

---

## One Plugin to Replace Them All

SmartMotion unifies the best ideas from hop, leap, flash, and mini.jump, then goes further:

| Feature | hop | leap | flash | SmartMotion |
|---------|-----|------|-------|-------------|
| Word/line jumping | ✓ | ✓ | ✓ | ✓ |
| 2-char search | | ✓ | ✓ | ✓ |
| Live incremental search | | | ✓ | ✓ |
| Fuzzy search | | | | ✓ |
| Treesitter integration | | | ✓ | ✓ |
| Composable d/y/c operators | | | partial | ✓ |
| Remote operations | | | | ✓ |
| Multi-window jumping | | | ✓ | ✓ |
| Operator-pending mode | ✓ | ✓ | ✓ | ✓ |
| Multi-cursor selection | | | | ✓ |
| Argument swap | | | | ✓ |
| Visual range selection | | | | ✓ |
| **Extensible pipeline** | | | | ✓ |
| **Build your own motions** | | | | ✓ |

The difference isn't just features, it's **architecture**. SmartMotion is designed from the ground up to be extended.

---

## See It In Action

### Basic Navigation
Press `w` → labels appear on every word → press a label → you're there.

### Composable Operators
Press `d` → press `w` → labels appear → select target → text deleted from cursor to target.

Works with `y` (yank), `c` (change), `p` (paste). Chain any operator with any motion.

### Treesitter-Aware Editing
- `]]` / `[[` - jump to functions
- `]c` / `[c` - jump to classes
- `daf` - delete around function (text object + operator)
- `cfn` - change function name (instant rename via multi-char infer)
- `yaa` - yank around argument (with separator awareness)
- `saa` - swap two arguments

### Search That Actually Works
- `s` - live search with labels as you type
- `S` - fuzzy search (type "fn" to match "function")
- `/` - native search with label overlay
- Label conflict avoidance means labels never interfere with your search

### Multi-Window
Search, treesitter, and diagnostic motions show labels across **all visible splits**. Jump anywhere in your viewport with a single keystroke.

---

## Quick Start

```lua
-- lazy.nvim
{
  "FluxxField/smart-motion.nvim",
  opts = {
    presets = {
      words = true,        -- w, b, e, ge
      lines = true,        -- j, k
      search = true,       -- s, S, f, F, t, T, ;, ,
      delete = true,       -- d, dt, dT, rdw, rdl
      yank = true,         -- y, yt, yT, ryw, ryl
      change = true,       -- c, ct, cT
      paste = true,        -- p, P
      treesitter = true,   -- ]], [[, ]c, [c, ]b, [b, af, if, ac, ic, aa, ia, fn, saa, gS, R
      diagnostics = true,  -- ]d, [d, ]e, [e
      git = true,          -- ]g, [g
      quickfix = true,     -- ]q, [q, ]l, [l
      marks = true,        -- g', gm
      misc = true,         -- . g. g1-g9 gp gP gA-gZ gmd gmy (repeat, history, pins, multi-cursor)
    },
  },
}
```

That's it. You now have 140+ motions that work together seamlessly.

---

## The Power of the Pipeline

Here's what makes SmartMotion different. Want a custom motion? It's just a few lines:

```lua
require("smart-motion").register_motion("custom_jump", {
  collector = "lines",           -- where to look
  extractor = "words",           -- what to find
  filter = "filter_words_after_cursor",  -- which ones to show
  visualizer = "hint_start",     -- how to display
  action = "jump_centered",      -- what to do
  map = true,
  modes = { "n", "v" },
  trigger = "<leader>j",
})
```

Every built-in motion uses this same system. You have the same power.

Want a motion that jumps to a word and yanks it in one action?

```lua
action = merge({ "jump", "yank" })
```

Want to jump to treesitter function definitions?

```lua
collector = "treesitter",
metadata = {
  motion_state = {
    ts_node_types = { "function_declaration", "function_definition" },
  },
}
```

Want to jump to LSP diagnostics?

```lua
collector = "diagnostics",
metadata = {
  motion_state = {
    diagnostic_severity = vim.diagnostic.severity.ERROR,
  },
}
```

The possibilities are endless because **you control every stage**.

---

## Documentation

### Getting Started
- **[Quick Start](Quick-Start.md)**: Install and configure in 60 seconds
- **[Why SmartMotion?](Why-SmartMotion.md)**: Philosophy and comparison with alternatives
- **[Migration Guide](Migration.md)**: Coming from flash, leap, hop, or mini.jump

### Using SmartMotion
- **[Presets Guide](Presets.md)**: All 13 presets and 140+ keybindings
- **[Advanced Features](Advanced-Features.md)**: Flow state, multi-window, operator-pending mode

### Building Your Own
- **[Build Your Own Motions](Building-Custom-Motions.md)**: Create custom motions in minutes
- **[Pipeline Architecture](Pipeline-Architecture.md)**: Deep dive into collectors, extractors, filters, and more

### Reference
- **[Configuration](Configuration.md)**: All options explained
- **[API Reference](API-Reference.md)**: Complete module and motion_state reference
- **[Debugging](Debugging.md)**: Tips for troubleshooting

---

## Philosophy

SmartMotion is built on three principles:

1. **Composability.** Every piece should work with every other piece. Operators compose with motions. Actions compose with each other. Modules compose into pipelines.

2. **Extensibility.** The architecture that powers built-in motions is the same architecture available to you. No hidden magic.

3. **Native Feel.** Motions should feel like Vim, not fight against it. Operator-pending mode works. Repeat with `.` works. Flow state makes chaining feel instant.

---

## Contributing

SmartMotion is open source under GPL-3.0. Contributions welcome!

- [GitHub Repository](https://github.com/FluxxField/smart-motion.nvim)
- [Report Issues](https://github.com/FluxxField/smart-motion.nvim/issues)

---

*Built by [FluxxField](https://github.com/FluxxField)*
