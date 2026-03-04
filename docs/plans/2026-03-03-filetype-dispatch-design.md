# Filetype-Aware Pipeline Dispatch

## Problem

Filetypes without treesitter parsers (e.g., fugitive's `gitcommit`) have no way to participate in smart-motion's treesitter-based workflows. Users must scatter per-filetype mappings across ftplugin files. A single keymap should adapt its pipeline behavior based on the current buffer's filetype.

## Solution

Two independent, composable modules:

1. **Patterns collector** — generic vim regex matching against buffer lines
2. **Filetype dispatch middleware** — pre-pipeline hook that swaps motion properties per filetype

## Design

### Patterns Collector

**File:** `lua/smart-motion/collectors/patterns.lua`

A standalone collector that finds targets using vim regex patterns.

**Input (from motion_state):**
- `patterns` — array of vim regex strings (required)
- `patterns_whole_line` — boolean, if true the entire matching line is the target (default false)

**Behavior:**
- Iterates all lines in the buffer
- For each line, runs `vim.fn.matchstrpos(line, pattern)` for each pattern
- Each match yields a standard target
- Multiple matches per line supported (advances past each match)
- Pattern order determines priority when matches overlap

**Target format:**
```lua
{
  text = "matched text",
  start_pos = { row = line_idx, col = match_start },
  end_pos = { row = line_idx, col = match_end },
  type = "pattern",
  metadata = {
    pattern_index = 1,  -- which pattern matched (1-indexed)
  },
}
```

**Registration:** Added to `collectors/init.lua` alongside existing collectors.

### Filetype Dispatch Middleware

**File:** `lua/smart-motion/core/engine/filetype_dispatch.lua`

A pre-pipeline middleware inserted into `setup.run()`.

**Integration point:** After shallow copy (line 20), before module loading (line 26):
```lua
motion_state.motion = vim.tbl_extend("force", {}, motion)
filetype_dispatch.apply(ctx, motion_state)  -- NEW
local modules = module_loader.get_modules(ctx, cfg, motion_state)
```

**How it works:**
1. Reads `motion_state.motion.metadata.motion_state.filetype_overrides`
2. Looks up `filetype_overrides[vim.bo[ctx.bufnr].filetype]`
3. If found, deep-merges the override into `motion_state.motion`
4. If not found, returns immediately (zero cost)

**Override capabilities:** Any motion property can be overridden per filetype:
- `collector`, `extractor`, `filter`, `visualizer`, `modifier`, `action` — swap pipeline modules
- `motion_state` — merged into `motion.metadata.motion_state` (for patterns, ts_query, ts_node_types, etc.)

### Config Example

```lua
["]]"] = {
  collector = "treesitter",
  extractor = "pass_through",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = "jump_centered",
  metadata = {
    motion_state = {
      ts_node_types = { "function_declaration", "function_definition" },
      multi_window = true,
      filetype_overrides = {
        gitcommit = {
          collector = "patterns",
          motion_state = {
            patterns = { "\\vmodified:\\s+\\zs\\S.*$" },
          },
        },
        sql = {
          motion_state = {
            ts_query = [[ (function_definition name: (identifier) @fn) ]],
          },
        },
      },
    },
  },
}
```

### Standalone Patterns Usage (No Filetype Dispatch)

```lua
sm.motions.register("ry", {
  collector = "patterns",
  extractor = "pass_through",
  filter = "filter_visible",
  visualizer = "hint_before",
  action = "remote_yank",
  metadata = {
    motion_state = {
      patterns = { "\\v\\f+" },
    },
  },
})
```

## System Interactions

- **Infer:** Dispatch runs before infer. Operator composition (`d]]` in gitcommit) works automatically.
- **Multi-window:** Patterns collector yields standard targets; `create_multi_window_collector` wraps it transparently.
- **Filters:** All existing filters work with pattern targets (standard start_pos/end_pos format).
- **Native search:** Not affected (standalone module outside pipeline).

## Scope

| Component | File | Change |
|-----------|------|--------|
| Patterns collector | `collectors/patterns.lua` | New file |
| Filetype dispatch | `core/engine/filetype_dispatch.lua` | New file |
| Setup integration | `core/engine/setup.lua` | Add 1 line |
| Collector registration | `collectors/init.lua` | Add patterns to register_many |

**Not building:** No new filters/extractors/visualizers. No global config key. No built-in presets. No Lua pattern support.
