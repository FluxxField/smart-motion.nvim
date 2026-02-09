# Pipeline Architecture

Every SmartMotion motion flows through a composable pipeline:

```
Collector → Extractor → Modifier → Filter → Visualizer → Selection → Action
```

This document explains each stage in depth.

---

## Overview

| Stage | Purpose | Required |
|-------|---------|----------|
| **Collector** | Gather raw data (lines, nodes, diagnostics) | Yes |
| **Extractor** | Find targets within collected data | Yes |
| **Modifier** | Enrich targets with metadata | No |
| **Filter** | Narrow down which targets to show | No |
| **Visualizer** | Render hints/labels to user | Yes |
| **Selection** | User picks a target | Automatic |
| **Action** | Execute on selected target | Yes |

Additionally, **Pipeline Wrappers** can intercept and control the entire flow.

---

## Collectors

Collectors are the **starting point**. They gather raw data that will be searched for targets.

### How They Work

Collectors are **Lua coroutines** that yield data incrementally:

```lua
function M.run(ctx, cfg, motion_state)
  return coroutine.create(function()
    local lines = vim.api.nvim_buf_get_lines(ctx.bufnr, 0, -1, false)
    for i, line in ipairs(lines) do
      coroutine.yield({
        text = line,
        line_number = i - 1,  -- 0-indexed
      })
    end
  end)
end
```

The coroutine design enables:
- **Early-exit**: Stop collecting when you have enough targets
- **Memory efficiency**: Don't load everything at once
- **Streaming**: Process data as it's produced

### Built-in Collectors

| Collector | What it yields |
|-----------|----------------|
| `lines` | Each line in the buffer with `text` and `line_number` |
| `treesitter` | Syntax nodes matching configured types |
| `diagnostics` | LSP diagnostic entries |
| `git_hunks` | Git changed regions (via gitsigns or git diff) |
| `quickfix` | Quickfix or location list entries |
| `marks` | Vim marks (a-z local, A-Z global) |
| `history` | Previous SmartMotion jump targets |

### Treesitter Collector Modes

The `treesitter` collector is powerful. It supports four modes:

**1. Raw Query** (`ts_query`)
```lua
motion_state = {
  ts_query = "(function_declaration name: (identifier) @name) @func",
}
```
Language-specific queries with full treesitter power.

**2. Node Type Matching** (`ts_node_types`)
```lua
motion_state = {
  ts_node_types = { "function_declaration", "method_definition" },
}
```
Walks the tree and yields nodes matching these types.

**3. Child Field Extraction** (`ts_node_types` + `ts_child_field`)
```lua
motion_state = {
  ts_node_types = { "function_declaration" },
  ts_child_field = "name",
}
```
Yields only the specified named field from matching nodes.

**4. Child Yielding** (`ts_node_types` + `ts_yield_children`)
```lua
motion_state = {
  ts_node_types = { "arguments", "parameters" },
  ts_yield_children = true,
  ts_around_separator = true,  -- include commas
}
```
Yields each named child of container nodes separately.

### Multi-Window Collection

When `motion_state.multi_window = true`, the pipeline automatically wraps collectors to run across all visible windows:

1. Creates a fresh collector coroutine per window
2. Injects `metadata.bufnr` and `metadata.winid` into each yielded item
3. Current window is processed first (for label priority)

This is transparent to collectors. They don't need modification.

### Creating a Custom Collector

```lua
local M = {}

function M.run(ctx, cfg, motion_state)
  return coroutine.create(function()
    -- Your data source
    local items = get_my_data()

    for _, item in ipairs(items) do
      coroutine.yield({
        text = item.text,
        line_number = item.line,  -- 0-indexed
        -- Add any fields you need
      })
    end
  end)
end

return M
```

Register:
```lua
require("smart-motion.core.registries"):get().collectors.register("my_collector", M)
```

---

## Extractors

Extractors process collected data and produce **targets**: the things users can jump to.

### How They Work

Extractors are also coroutines. They receive a collector coroutine and yield targets:

```lua
function M.run(collector, opts)
  return coroutine.create(function(ctx, cfg, motion_state)
    while true do
      local ok, data = coroutine.resume(collector, ctx, cfg, motion_state)
      if not ok or data == nil then break end

      -- Find targets in the data
      for match in data.text:gmatch("(%w+)") do
        coroutine.yield({
          row = data.line_number,
          col = start_col,
          text = match,
          start_pos = { row = data.line_number, col = start_col },
          end_pos = { row = data.line_number, col = end_col },
          type = "word",
        })
      end
    end
  end)
end
```

### Target Structure

A target should have:

```lua
{
  row = number,           -- 0-indexed line
  col = number,           -- 0-indexed column
  text = string,          -- display text
  start_pos = { row, col },
  end_pos = { row, col },
  type = string,          -- "word", "line", "node", etc.
  metadata = { ... },     -- optional extra data
}
```

### Built-in Extractors

| Extractor | What it produces |
|-----------|------------------|
| `words` | Word boundaries via regex |
| `lines` | Entire lines as targets |
| `text_search_1_char` | Single character matches |
| `text_search_2_char` | Two character matches (inclusive) |
| `text_search_2_char_until` | Two char with `exclude_target = true` (till) |
| `live_search` | Incremental search matches |
| `fuzzy_search` | Fuzzy matched targets |
| `pass_through` | Collector output unchanged |

### Input-Based Extractors

Some extractors need user input. They use a `before_input_loop` hook:

```lua
M.before_input_loop = function(ctx, cfg, motion_state)
  -- Get character from user
  local char = vim.fn.getchar()
  motion_state.search_text = vim.fn.nr2char(char)
end
```

The `module_wrapper` utility handles this automatically.

### Creating a Custom Extractor

```lua
local M = {}

function M.run(collector, opts)
  return coroutine.create(function(ctx, cfg, motion_state)
    while true do
      local ok, data = coroutine.resume(collector, ctx, cfg, motion_state)
      if not ok or data == nil then break end

      -- Your extraction logic
      -- Yield targets as you find them
      coroutine.yield({
        row = ...,
        col = ...,
        text = ...,
        start_pos = { row = ..., col = ... },
        end_pos = { row = ..., col = ... },
        type = "my_type",
      })
    end
  end)
end

return M
```

Register:
```lua
require("smart-motion.core.registries"):get().extractors.register("my_extractor", M)
```

---

## Modifiers

Modifiers enrich targets with **metadata** after extraction but before filtering. They don't remove targets, they add information.

### When to Use

- Add distance-based sorting weights
- Attach syntax information
- Compute relevance scores
- Add context for visualization

### Built-in Modifiers

| Modifier | What it adds |
|----------|--------------|
| `distance_metadata` | `metadata.sort_weight` based on Manhattan distance from cursor |

### How Sorting Works

Set `motion_state.sort_by` to sort targets by a metadata field:

```lua
motion_state = {
  sort_by = "sort_weight",
  sort_descending = false,  -- ascending by default
}
```

The visualizer will sort before assigning labels.

### Creating a Custom Modifier

```lua
local M = {}

function M.run(input_gen)
  return coroutine.create(function(ctx, cfg, motion_state)
    while true do
      local ok, target = coroutine.resume(input_gen, ctx, cfg, motion_state)
      if not ok or not target then break end

      -- Add metadata
      target.metadata = target.metadata or {}
      target.metadata.my_score = calculate_score(target)

      coroutine.yield(target)
    end
  end)
end

return M
```

Register:
```lua
require("smart-motion.core.registries"):get().modifiers.register("my_modifier", M)
```

---

## Filters

Filters narrow down targets based on visibility, direction, or custom criteria.

### How They Work

Filters receive a list of targets and return a filtered list:

```lua
function M.run(targets, ctx, cfg, motion_state)
  return vim.tbl_filter(function(target)
    return target.row > ctx.cursor_line
  end, targets)
end
```

### Built-in Filters

| Filter | What it keeps |
|--------|---------------|
| `default` | Everything unchanged |
| `filter_visible` | Only in current viewport |
| `filter_cursor_line_only` | Only on cursor line |
| `filter_words_after_cursor` | Words after cursor |
| `filter_words_before_cursor` | Words before cursor |
| `filter_words_around_cursor` | Both directions |
| `filter_lines_after_cursor` | Lines after cursor |
| `filter_lines_before_cursor` | Lines before cursor |
| `filter_lines_around_cursor` | Both directions |
| `filter_words_on_cursor_line_after_cursor` | Cursor line, after cursor |
| `filter_words_on_cursor_line_before_cursor` | Cursor line, before cursor |
| `first_target` | Only first target |

### Multi-Window Behavior

Directional filters have special handling in multi-window mode:
- Targets from **other windows** pass through unchanged
- Direction filtering only applies to the **current window**

Visibility filters use each target's `winid` to check against the correct viewport.

### Creating a Custom Filter

```lua
local M = {}

function M.run(targets, ctx, cfg, motion_state)
  return vim.tbl_filter(function(target)
    -- Your filtering logic
    return should_keep(target)
  end, targets)
end

return M
```

Register:
```lua
require("smart-motion.core.registries"):get().filters.register("my_filter", M)
```

---

## Visualizers

Visualizers render targets to the user, typically as hint labels.

### How They Work

```lua
function M.run(ctx, cfg, motion_state)
  local targets = motion_state.targets

  for i, target in ipairs(targets) do
    local label = motion_state.hint_labels[i]
    -- Render label at target position
  end
end
```

### Built-in Visualizers

| Visualizer | How it renders |
|------------|----------------|
| `hint_start` | Label at target start position |
| `hint_end` | Label at target end position |

### Label System

Labels are generated based on:
- `cfg.keys`: Available characters
- Number of targets: Single chars for few, double for many
- Label conflict avoidance: In search mode, labels can't be valid continuations

### Creating a Custom Visualizer

```lua
local M = {}

function M.run(ctx, cfg, motion_state)
  local targets = motion_state.targets

  -- Could show in a floating window, Telescope, etc.
  for i, target in ipairs(targets) do
    local label = motion_state.hint_labels[i]
    -- Your rendering logic
  end
end

return M
```

Register:
```lua
require("smart-motion.core.registries"):get().visualizers.register("my_visualizer", M)
```

---

## Actions

Actions execute when the user selects a target.

### How They Work

```lua
function M.run(ctx, cfg, motion_state)
  local target = motion_state.selected_jump_target
  if not target then return end

  -- Do something with the target
  vim.api.nvim_win_set_cursor(0, { target.row + 1, target.col })
end
```

### Built-in Actions

| Action | What it does |
|--------|--------------|
| `jump` | Move cursor to target |
| `jump_centered` | Move cursor, center screen |
| `center` | Center screen on cursor |
| `delete` | Delete target text |
| `delete_until` | Delete from cursor to target |
| `delete_line` | Delete entire line |
| `yank` | Yank target text |
| `yank_until` | Yank from cursor to target |
| `yank_line` | Yank entire line |
| `change` | Delete and enter insert mode |
| `change_until` | Change from cursor to target |
| `change_line` | Change entire line |
| `paste` | Paste at target |
| `remote_delete` | Delete without moving cursor |
| `remote_delete_line` | Delete line without moving |
| `remote_yank` | Yank without moving cursor |
| `remote_yank_line` | Yank line without moving |
| `restore` | Restore cursor to original position |

### Action Merging

Combine multiple actions:

```lua
local merge = require("smart-motion.core.utils").action_utils.merge

action = merge({ "jump", "delete" })
action = merge({ "jump", "yank", "center" })
```

Actions execute in order.

### Creating a Custom Action

```lua
local M = {}

function M.run(ctx, cfg, motion_state)
  local target = motion_state.selected_jump_target
  if not target then return end

  -- Your action logic
end

return M
```

Register:
```lua
require("smart-motion.core.registries"):get().actions.register("my_action", M)
```

---

## Pipeline Wrappers

Wrappers intercept the entire pipeline flow. They control **when** and **how** the pipeline runs.

### When to Use

- Multi-character input (like `f/2`)
- Live search that re-runs on each keystroke
- Interactive filtering
- Modal interfaces

### How They Work

```lua
function M.run(run_pipeline, ctx, cfg, motion_state, opts)
  -- Optionally gather input
  -- Optionally modify motion_state
  -- Then run the pipeline
  run_pipeline(ctx, cfg, motion_state, opts)
end
```

### Built-in Wrappers

| Wrapper | Behavior |
|---------|----------|
| `default` | Run pipeline once, unchanged |
| `text_search` | Prompt for characters, then run |
| `live_search` | Re-run on each keystroke |

### Creating a Custom Wrapper

```lua
local M = {}

function M.run(run_pipeline, ctx, cfg, motion_state, opts)
  -- Get 3 characters
  local chars = ""
  for i = 1, 3 do
    local c = vim.fn.getchar()
    chars = chars .. vim.fn.nr2char(c)
  end

  motion_state.search_text = chars
  run_pipeline(ctx, cfg, motion_state, opts)
end

return M
```

Register:
```lua
require("smart-motion.core.registries"):get().pipeline_wrappers.register("my_wrapper", M)
```

---

## Context and Motion State

Every module receives three arguments:

| Argument | Purpose |
|----------|---------|
| `ctx` | Read-only context (bufnr, winid, cursor position) |
| `cfg` | User configuration from setup() |
| `motion_state` | Mutable state shared across the pipeline |

### Context (`ctx`)

```lua
{
  bufnr = number,
  winid = number,
  cursor_line = number,   -- 0-indexed
  cursor_col = number,    -- 0-indexed
  last_line = number,
  mode = string,          -- from vim.fn.mode(true)
  windows = { winid, ... },  -- visible windows (current first)
}
```

### Motion State (`motion_state`)

See **[API Reference](API-Reference.md)** for complete motion_state documentation.

Key fields:
- `targets`: List of targets after filtering
- `selected_jump_target`: The target user selected
- `search_text`: Current search input
- `multi_window`: Whether multi-window is enabled
- `ts_node_types`: For treesitter collector
- `diagnostic_severity`: For diagnostics collector

---

## Registry System

All modules are stored in global registries:

```lua
local registries = require("smart-motion.core.registries"):get()

registries.collectors.register("name", Module)
registries.extractors.register("name", Module)
registries.modifiers.register("name", Module)
registries.filters.register("name", Module)
registries.visualizers.register("name", Module)
registries.actions.register("name", Module)
registries.pipeline_wrappers.register("name", Module)
```

Lookup:
```lua
local collector = registries.collectors.get_by_name("lines")
```

This enables:
- Plugins contributing modules
- Users overriding built-ins
- Motions referencing any registered module by name

---

## Next Steps

→ **[Building Custom Motions](Building-Custom-Motions.md)**: Practical examples

→ **[API Reference](API-Reference.md)**: Complete reference

→ **[Debugging](Debugging.md)**: Troubleshooting
