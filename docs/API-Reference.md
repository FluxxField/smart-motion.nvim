# API Reference

Complete reference for SmartMotion modules and data structures.

---

## Table of Contents

- [Motion Registration](#motion-registration)
- [Built-in Modules](#built-in-modules)
- [Motion State](#motion-state)
- [Context Object](#context-object)
- [Target Structure](#target-structure)
- [Registries](#registries)
- [Utility Functions](#utility-functions)

---

## Motion Registration

### register_motion

```lua
require("smart-motion").register_motion(name, config)
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Motion identifier (also default trigger key) |
| `config` | table | Motion configuration |

**Config fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `trigger_key` | string | No | Override keybinding (defaults to `name`) |
| `collector` | string | Yes | Collector module name |
| `extractor` | string | Yes | Extractor module name |
| `modifier` | string | No | Modifier module name |
| `filter` | string | No | Filter module name |
| `visualizer` | string | Yes | Visualizer module name |
| `action` | string/function | Yes | Action module name or merged action |
| `pipeline_wrapper` | string | No | Pipeline wrapper name |
| `map` | boolean | No | Whether to create keymap (default: true) |
| `modes` | string[] | No | Vim modes (default: {"n"}) |
| `infer` | boolean | No | Enable operator inference |
| `metadata` | table | No | Additional metadata |

**Example:**

```lua
require("smart-motion").register_motion("gw", {
  collector = "lines",
  extractor = "words",
  filter = "filter_words_after_cursor",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n", "v", "o" },
  metadata = {
    label = "Jump to word",
    description = "Jump to a word after cursor",
    motion_state = {
      multi_window = false,
    },
  },
})
```

### register_many_motions

```lua
require("smart-motion").register_many_motions(motions)
```

Register multiple motions at once:

```lua
require("smart-motion").register_many_motions({
  gw = { ... },
  gb = { ... },
})
```

### map_motion

```lua
require("smart-motion").map_motion(name)
```

Manually map a registered motion (useful when `map = false`):

```lua
require("smart-motion").map_motion("w")
```

---

## Built-in Modules

### Collectors

| Name | Description |
|------|-------------|
| `lines` | All buffer lines |
| `treesitter` | Syntax nodes (see Treesitter modes below) |
| `diagnostics` | LSP diagnostics |
| `git_hunks` | Git changed regions |
| `quickfix` | Quickfix/location list entries |
| `marks` | Vim marks |
| `history` | SmartMotion jump history |

**Treesitter collector modes:**

1. `ts_query` — Raw treesitter query string
2. `ts_node_types` — Match node types
3. `ts_node_types` + `ts_child_field` — Yield named field
4. `ts_node_types` + `ts_yield_children` — Yield children

### Extractors

| Name | Description |
|------|-------------|
| `words` | Word boundaries |
| `lines` | Entire lines |
| `text_search_1_char` | Single char matches |
| `text_search_1_char_until` | Single char, exclude target |
| `text_search_2_char` | Two char matches |
| `live_search` | Incremental search |
| `fuzzy_search` | Fuzzy matching |
| `pass_through` | Collector output unchanged |

### Modifiers

| Name | Description |
|------|-------------|
| `distance_metadata` | Adds `sort_weight` by distance |

### Filters

| Name | Description |
|------|-------------|
| `default` | No filtering |
| `filter_visible` | Viewport only |
| `filter_cursor_line_only` | Cursor line only |
| `filter_words_after_cursor` | Words after cursor |
| `filter_words_before_cursor` | Words before cursor |
| `filter_words_around_cursor` | Both directions |
| `filter_lines_after_cursor` | Lines after cursor |
| `filter_lines_before_cursor` | Lines before cursor |
| `filter_lines_around_cursor` | Both directions |
| `filter_words_on_cursor_line_after_cursor` | Cursor line, after |
| `filter_words_on_cursor_line_before_cursor` | Cursor line, before |
| `first_target` | First target only |

### Visualizers

| Name | Description |
|------|-------------|
| `hint_start` | Label at target start |
| `hint_end` | Label at target end |

### Actions

| Name | Description |
|------|-------------|
| `jump` | Move cursor |
| `jump_centered` | Move cursor, center screen |
| `center` | Center screen |
| `delete` | Delete target |
| `delete_until` | Delete cursor→target |
| `delete_line` | Delete line |
| `yank` | Yank target |
| `yank_until` | Yank cursor→target |
| `yank_line` | Yank line |
| `change` | Change target |
| `change_until` | Change cursor→target |
| `change_line` | Change line |
| `paste` | Paste at target |
| `remote_delete` | Delete without moving |
| `remote_delete_line` | Delete line without moving |
| `remote_yank` | Yank without moving |
| `remote_yank_line` | Yank line without moving |
| `restore` | Restore cursor position |
| `run_motion` | Re-run from history |

### Pipeline Wrappers

| Name | Description |
|------|-------------|
| `default` | Run once |
| `text_search` | Prompt for chars, then run |
| `live_search` | Re-run on each keystroke |

---

## Motion State

The `motion_state` table is mutable state passed through all pipeline stages.

### Core Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Motion name |
| `trigger_key` | string | Key that triggered motion |
| `direction` | string | `"before"` or `"after"` |
| `hint_position` | string | `"start"`, `"end"`, `"middle"` |
| `target_type` | string | `"word"`, `"line"`, `"char"`, etc. |
| `max_lines` | integer | Max lines to consider |
| `max_labels` | integer | Max hint labels |
| `total_keys` | integer | Available hint keys count |

### Target Fields

| Field | Type | Description |
|-------|------|-------------|
| `targets` | Target[] | List of targets |
| `jump_target_count` | integer | Number of valid targets |
| `selected_jump_target` | Target | User's selected target |
| `hint_labels` | string[] | Generated labels |
| `assigned_hint_labels` | table | Label→metadata mapping |
| `single_label_count` | integer | Single-char labels used |
| `double_label_count` | integer | Double-char labels used |

### Selection Fields

| Field | Type | Description |
|-------|------|-------------|
| `selection_mode` | string | `"single"`, `"double"`, `"stepwise"` |
| `selection_first_char` | string | First char of 2-char selection |
| `auto_select_target` | boolean | Auto-jump on single target |
| `allow_quick_action` | boolean | Immediate execution on cursor target |

### Search Fields

| Field | Type | Description |
|-------|------|-------------|
| `is_searching_mode` | boolean | Live search active |
| `search_text` | string | Current search input |
| `last_search_text` | string | Previous search |
| `num_of_char` | number | Character limit (f/t) |
| `exclude_target` | boolean | Exclude target from range (till) |

### Rendering Fields

| Field | Type | Description |
|-------|------|-------------|
| `virt_text_pos` | string | `"eol"`, `"overlay"`, `"inline"` |
| `should_show_prefix` | boolean | Show motion key prefix |

### Sorting Fields

| Field | Type | Description |
|-------|------|-------------|
| `sort_by` | string | Metadata key to sort by |
| `sort_descending` | boolean | Reverse sort order |

### Treesitter Fields

| Field | Type | Description |
|-------|------|-------------|
| `ts_query` | string | Raw treesitter query |
| `ts_node_types` | string[] | Node types to match |
| `ts_child_field` | string | Named field to yield |
| `ts_yield_children` | boolean | Yield container children |
| `ts_around_separator` | boolean | Include separators |

### Multi-Window Fields

| Field | Type | Description |
|-------|------|-------------|
| `multi_window` | boolean | Enable multi-window |
| `affected_buffers` | table | Buffers with highlights |

### Diagnostic Fields

| Field | Type | Description |
|-------|------|-------------|
| `diagnostic_severity` | number/number[] | Severity filter |

### Paste Fields

| Field | Type | Description |
|-------|------|-------------|
| `paste_mode` | string | `"before"` or `"after"` |

### Pattern Fields

| Field | Type | Description |
|-------|------|-------------|
| `word_pattern` | string | Custom word regex |

---

## Context Object

The `ctx` object provides read-only context to all modules.

| Field | Type | Description |
|-------|------|-------------|
| `bufnr` | integer | Current buffer number |
| `winid` | integer | Current window ID |
| `cursor_line` | integer | Cursor line (0-indexed) |
| `cursor_col` | integer | Cursor column (0-indexed) |
| `last_line` | integer | Last line in buffer |
| `mode` | string | Vim mode from `mode(true)` |
| `windows` | integer[] | Visible window IDs (current first) |
| `filetype` | string | Buffer filetype |

---

## Target Structure

Targets are the jump destinations produced by extractors.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `row` | integer | Yes | Line number (0-indexed) |
| `col` | integer | Yes | Column number (0-indexed) |
| `text` | string | Yes | Display text |
| `start_pos` | {row, col} | Yes | Range start |
| `end_pos` | {row, col} | Yes | Range end |
| `type` | string | No | Target type identifier |
| `metadata` | table | No | Additional data |

**Common metadata fields:**

| Field | Description |
|-------|-------------|
| `bufnr` | Buffer containing target |
| `winid` | Window containing target |
| `filetype` | Filetype of buffer |
| `sort_weight` | Sorting weight |
| `hunk_type` | Git hunk type ("add", "delete", "change") |
| `entry_type` | Quickfix entry type (E/W/I/N/H) |
| `qf_idx` | Quickfix entry index |
| `exclude_target` | Whether target is excluded from range |

---

## Registries

Access module registries:

```lua
local registries = require("smart-motion.core.registries"):get()
```

### Available Registries

| Registry | Access |
|----------|--------|
| Collectors | `registries.collectors` |
| Extractors | `registries.extractors` |
| Modifiers | `registries.modifiers` |
| Filters | `registries.filters` |
| Visualizers | `registries.visualizers` |
| Actions | `registries.actions` |
| Pipeline Wrappers | `registries.pipeline_wrappers` |
| Motions | `registries.motions` |

### Registry Methods

```lua
-- Register a module
registries.filters.register("my_filter", MyModule)

-- Get by name
local filter = registries.filters.get_by_name("my_filter")

-- Get by key (for infer)
local extractor = registries.extractors.get_by_key("w")
```

---

## Utility Functions

### Action Merging

```lua
local merge = require("smart-motion.core.utils").action_utils.merge

local combined = merge({ "jump", "delete" })
local triple = merge({ "jump", "yank", "center" })
```

### Range Resolution

```lua
local resolve_range = require("smart-motion.actions.utils").resolve_range

local start_pos, end_pos = resolve_range(ctx, motion_state, target)
```

### Logging

```lua
local log = require("smart-motion.core.log")

log.debug("Debug message")
log.info("Info message")
log.warn("Warning message")
log.error("Error message")
```

Enable logging:
```lua
vim.g.smart_motion_log_level = "debug"  -- or "info", "warn", "error", "off"
```

---

## Module Signatures

### Collector

```lua
function M.run(ctx, cfg, motion_state)
  return coroutine.create(function()
    -- yield items
    coroutine.yield({ text = "...", line_number = 0 })
  end)
end
```

### Extractor

```lua
function M.run(collector, opts)
  return coroutine.create(function(ctx, cfg, motion_state)
    while true do
      local ok, data = coroutine.resume(collector, ctx, cfg, motion_state)
      if not ok or data == nil then break end
      -- yield targets
      coroutine.yield({ row = 0, col = 0, text = "...", ... })
    end
  end)
end

-- Optional: called before each pipeline iteration
function M.before_input_loop(ctx, cfg, motion_state)
  -- gather input
end
```

### Modifier

```lua
function M.run(input_gen)
  return coroutine.create(function(ctx, cfg, motion_state)
    while true do
      local ok, target = coroutine.resume(input_gen, ctx, cfg, motion_state)
      if not ok or not target then break end
      -- enrich target
      target.metadata.my_field = "value"
      coroutine.yield(target)
    end
  end)
end
```

### Filter

```lua
function M.run(targets, ctx, cfg, motion_state)
  return vim.tbl_filter(function(target)
    return should_keep(target)
  end, targets)
end
```

### Visualizer

```lua
function M.run(ctx, cfg, motion_state)
  local targets = motion_state.targets
  -- render labels
end
```

### Action

```lua
function M.run(ctx, cfg, motion_state)
  local target = motion_state.selected_jump_target
  if not target then return end
  -- perform action
end
```

### Pipeline Wrapper

```lua
function M.run(run_pipeline, ctx, cfg, motion_state, opts)
  -- optionally gather input or modify state
  run_pipeline(ctx, cfg, motion_state, opts)
end
```

---

## Next Steps

→ **[Building Custom Motions](Building-Custom-Motions.md)** — Practical examples

→ **[Pipeline Architecture](Pipeline-Architecture.md)** — How it works

→ **[Debugging](Debugging.md)** — Troubleshooting
