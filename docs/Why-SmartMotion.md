# Why SmartMotion?

You have choices. Hop, leap, flash, mini.jump — they're all excellent plugins. So why SmartMotion?

---

## The Problem with Motion Plugins

Every motion plugin solves the same fundamental problem: **getting your cursor somewhere faster**. And they all solve it well enough. But they share a limitation:

**They're closed systems.**

Want a motion that doesn't exist? You either wait for the maintainer to add it, hack around the plugin's internals, or write your own plugin from scratch.

SmartMotion takes a different approach.

---

## SmartMotion is a Framework

The 57+ built-in keybindings aren't special. They're built using the exact same system available to you:

```lua
-- This is literally how the built-in 'w' motion is defined
require("smart-motion").register_motion("w", {
  collector = "lines",
  extractor = "words",
  filter = "filter_words_after_cursor",
  visualizer = "hint_start",
  action = "jump",
  modes = { "n", "v", "o" },
})
```

Every motion flows through a pipeline:

```
Collector → Extractor → Modifier → Filter → Visualizer → Selection → Action
```

Each stage is a module. Swap any module, combine modules, or write your own. The architecture is **open by design**.

---

## Detailed Comparison

### vs. hop.nvim

**Hop** pioneered the hint-based jumping pattern in Neovim. It's fast, reliable, and well-maintained.

| Aspect | hop.nvim | SmartMotion |
|--------|----------|-------------|
| Word/line jumping | ✓ | ✓ |
| Pattern search | ✓ | ✓ |
| Treesitter integration | Limited | Full |
| Composable operators | No | Yes |
| Multi-window | No | Yes |
| Custom motion creation | Difficult | Built-in |
| Architecture | Monolithic | Modular pipeline |

**When to choose Hop**: You want a simple, proven solution and don't need advanced features.

**When to choose SmartMotion**: You want treesitter integration, composable operators, or the ability to create custom motions.

---

### vs. leap.nvim

**Leap** introduced the elegant 2-character search pattern. Its "clairvoyant" highlighting is beautiful.

| Aspect | leap.nvim | SmartMotion |
|--------|-----------|-------------|
| 2-char search | ✓ | ✓ |
| Multi-window | Via plugin | Built-in |
| Treesitter integration | Via plugin | Built-in |
| Composable d/y/c | No | Yes |
| Live incremental search | No | Yes |
| Fuzzy search | No | Yes |
| Remote operations | No | Yes |
| Custom motion creation | Limited | Full |

**When to choose Leap**: You love the 2-char search UX and want a minimal, focused plugin.

**When to choose SmartMotion**: You want the 2-char search pattern plus treesitter, composable operators, and extensibility.

---

### vs. flash.nvim

**Flash** is currently the most feature-rich motion plugin. It has treesitter integration, search-based jumping, and remote operations.

| Aspect | flash.nvim | SmartMotion |
|--------|------------|-------------|
| Search-based jumping | ✓ | ✓ |
| Treesitter integration | ✓ | ✓ |
| Multi-window | ✓ | ✓ |
| Composable operators | Partial | Full |
| Remote operations | ✓ | ✓ |
| Fuzzy search | No | Yes |
| Label conflict avoidance | No | Yes |
| Multi-cursor selection | No | Yes |
| Argument swap | No | Yes |
| Treesitter incremental select | No | Yes |
| Custom motion creation | Limited | Full pipeline |
| Plugin interop | Limited | Registry system |

**When to choose Flash**: It's excellent and you're already happy with it.

**When to choose SmartMotion**: You want fuzzy search, multi-cursor operations, full composability, or the ability to build entirely custom motions.

---

### vs. mini.jump

**mini.jump** is part of the mini.nvim ecosystem. It's minimal and fast.

| Aspect | mini.jump | SmartMotion |
|--------|-----------|-------------|
| Character jumping | ✓ | ✓ |
| Word jumping | Via mini.jump2d | ✓ |
| Treesitter integration | No | Yes |
| Composable operators | No | Yes |
| Multi-window | No | Yes |
| Ecosystem integration | mini.nvim | Standalone |

**When to choose mini.jump**: You're invested in the mini.nvim ecosystem.

**When to choose SmartMotion**: You want a comprehensive standalone solution.

---

## What SmartMotion Does Differently

### 1. True Composability

In SmartMotion, operators and motions are separate concerns that compose freely:

```lua
-- Operator 'd' + motion 'w' = delete to word
-- Operator 'y' + motion 'j' = yank to line
-- Operator 'c' + motion ']]' = change to function

-- And you can create compound actions:
action = merge({ "jump", "delete" })
action = merge({ "jump", "yank", "center" })
```

This isn't special syntax. It's how the system works.

### 2. Registry-Based Architecture

Every module type has a global registry:

```lua
-- Register a custom collector
require("smart-motion.core.registries"):get().collectors.register("my_collector", MyCollector)

-- Now use it in any motion
{ collector = "my_collector", ... }
```

This means:
- Plugins can contribute modules
- Users can override built-in modules
- Custom motions can use any registered module

### 3. Treesitter as a First-Class Citizen

The `treesitter` collector isn't a bolt-on feature. It supports four distinct modes:

1. **Raw queries** — Full treesitter query power
2. **Node type matching** — Jump to functions, classes, etc.
3. **Child field extraction** — Jump to function names, class names
4. **Child yielding** — Jump to individual arguments with separator awareness

This powers motions like `daa` (delete argument around) and `cfn` (change function name).

### 4. Multi-Window Without Compromise

When enabled, labels appear across all visible splits. But it's smart:

- Current window gets label priority (closer = shorter label)
- Directional filters still work within each window
- Disabled automatically in operator-pending mode
- Each target knows its window for correct jumping

### 5. Flow State

Press a motion, select a target, press another motion within 300ms — you're in flow. Labels appear instantly. Navigation feels native.

This isn't a gimmick. It's how SmartMotion makes repeated motions feel like Vim, not like a plugin.

---

## The Philosophy

### 1. Everything is a Pipeline

A motion isn't a function. It's a data flow:

```
Collector (where to look)
    ↓
Extractor (what to find)
    ↓
Modifier (enrich with metadata)
    ↓
Filter (narrow down)
    ↓
Visualizer (show to user)
    ↓
Selection (user picks)
    ↓
Action (do something)
```

Each stage is independent. You can swap the visualizer without touching the collector. You can add a modifier without changing the filter. **Separation of concerns, applied to motions.**

### 2. No Magic

The built-in `w` motion doesn't use special internal APIs. It's registered the same way you'd register a custom motion. **What we use, you can use.**

### 3. Vim-Native Feel

SmartMotion doesn't fight Vim:

- Operator-pending mode works (`>w`, `gUj`, `=]]`)
- Repeat with `.` works
- Visual mode works
- Marks, registers, all of it

If it feels like Vim, it's because SmartMotion respects Vim's model.

---

## When NOT to Choose SmartMotion

Be honest with yourself:

- **If you just need basic jumping** — hop or leap might be simpler
- **If you never customize anything** — any motion plugin will work
- **If you want minimal dependencies** — mini.jump is smaller

SmartMotion shines when you want **power and extensibility**. If you don't need that, simpler options exist.

---

## Ready to Try It?

→ **[Quick Start](Quick-Start.md)** — Get running in 60 seconds

→ **[Presets Guide](Presets.md)** — See all 57+ built-in keybindings

→ **[Build Your Own](Building-Custom-Motions.md)** — Create your first custom motion
