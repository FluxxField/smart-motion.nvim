# Building Custom Motions

This is where SmartMotion becomes yours.

Every built-in motion uses the same system you're about to learn. There's no magic, no internal APIs — just a pipeline you can configure however you want.

---

## Your First Custom Motion

Let's create a motion that jumps to words after the cursor and centers the screen:

```lua
require("smart-motion").register_motion("gw", {
  collector = "lines",
  extractor = "words",
  filter = "filter_words_after_cursor",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n", "v" },
})
```

That's it. Press `gw`, labels appear on words ahead, press a label, cursor jumps there and screen centers.

Let's break it down:

| Field | What it does |
|-------|--------------|
| `collector` | Where to look — `"lines"` means all buffer lines |
| `extractor` | What to find — `"words"` finds word boundaries |
| `filter` | Which to show — `"filter_words_after_cursor"` keeps only words ahead |
| `visualizer` | How to display — `"hint_start"` puts labels at word start |
| `action` | What to do — `"jump_centered"` moves cursor and centers screen |
| `map` | Whether to create a keymap |
| `modes` | Which vim modes this works in |

---

## The Pipeline

Every motion flows through this pipeline:

```
Collector → Extractor → Modifier → Filter → Visualizer → Selection → Action
```

Each stage is optional (except collector, extractor, visualizer, action). Each stage is a module you can swap.

### Collectors

**Where to look for targets.**

| Collector | What it collects |
|-----------|------------------|
| `lines` | All lines in the buffer |
| `treesitter` | Treesitter syntax nodes |
| `diagnostics` | LSP diagnostics |
| `git_hunks` | Git changed regions |
| `quickfix` | Quickfix/location list entries |
| `marks` | Vim marks |
| `history` | SmartMotion jump history |

### Extractors

**What to find within collected data.**

| Extractor | What it extracts |
|-----------|------------------|
| `words` | Word boundaries via regex |
| `lines` | Entire lines as targets |
| `text_search_1_char` | Single character matches |
| `text_search_1_char_until` | Single char, exclude target (for `t`/`T`) |
| `text_search_2_char` | Two character matches |
| `live_search` | Incremental search as you type |
| `fuzzy_search` | Fuzzy matching |
| `pass_through` | Use collector output directly |

### Filters

**Which targets to keep.**

| Filter | What it keeps |
|--------|---------------|
| `default` | Everything (no filtering) |
| `filter_visible` | Only visible in viewport |
| `filter_words_after_cursor` | Words after cursor |
| `filter_words_before_cursor` | Words before cursor |
| `filter_words_around_cursor` | Words in both directions |
| `filter_lines_after_cursor` | Lines after cursor |
| `filter_lines_before_cursor` | Lines before cursor |
| `filter_cursor_line_only` | Only on cursor line |
| `first_target` | Only the first target |

### Visualizers

**How to display targets.**

| Visualizer | How it displays |
|------------|-----------------|
| `hint_start` | Label at target start |
| `hint_end` | Label at target end |

### Actions

**What to do when user selects.**

| Action | What it does |
|--------|--------------|
| `jump` | Move cursor to target |
| `jump_centered` | Move cursor and center screen |
| `delete` | Delete target text |
| `delete_until` | Delete from cursor to target |
| `delete_line` | Delete entire target line |
| `yank` | Yank target text |
| `yank_until` | Yank from cursor to target |
| `yank_line` | Yank entire target line |
| `change` | Delete and enter insert mode |
| `change_until` | Change from cursor to target |
| `change_line` | Change entire target line |
| `paste` | Paste at target |
| `remote_delete` | Delete without moving cursor |
| `remote_delete_line` | Delete line without moving |
| `remote_yank` | Yank without moving cursor |
| `remote_yank_line` | Yank line without moving |
| `center` | Center screen on cursor |
| `restore` | Restore cursor to original position |

---

## Combining Actions

Want a motion that does multiple things? Use `merge`:

```lua
local merge = require("smart-motion.core.utils").action_utils.merge

require("smart-motion").register_motion("gy", {
  collector = "lines",
  extractor = "words",
  filter = "filter_words_after_cursor",
  visualizer = "hint_start",
  action = merge({ "jump", "yank" }),  -- jump THEN yank
  map = true,
  modes = { "n" },
})
```

Now `gy` jumps to a word and yanks it.

More examples:

```lua
-- Jump, delete, and center
action = merge({ "jump", "delete", "center" })

-- Yank without moving (remote yank)
action = merge({ "yank", "restore" })
```

---

## Example: Jump to Functions

```lua
require("smart-motion").register_motion("<leader>f", {
  collector = "treesitter",
  extractor = "pass_through",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n" },
  metadata = {
    motion_state = {
      ts_node_types = {
        "function_declaration",
        "function_definition",
        "arrow_function",
        "method_definition",
        "function_item",
      },
    },
  },
})
```

The `treesitter` collector uses `ts_node_types` to find matching syntax nodes. Since treesitter already yields full targets, we use `pass_through` extractor.

---

## Example: Jump to Errors Only

```lua
require("smart-motion").register_motion("<leader>e", {
  collector = "diagnostics",
  extractor = "pass_through",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n" },
  metadata = {
    motion_state = {
      diagnostic_severity = vim.diagnostic.severity.ERROR,
    },
  },
})
```

The `diagnostics` collector respects `diagnostic_severity` to filter by severity level.

---

## Example: Live Search

```lua
require("smart-motion").register_motion("<leader>s", {
  collector = "lines",
  extractor = "live_search",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n" },
  metadata = {
    motion_state = {
      multi_window = true,  -- search across all visible windows
    },
  },
})
```

The `live_search` extractor handles user input automatically — labels update as you type.

---

## Example: 2-Char Find

```lua
require("smart-motion").register_motion("<leader>f", {
  collector = "lines",
  extractor = "text_search_2_char",
  filter = "filter_words_after_cursor",
  visualizer = "hint_start",
  action = "jump",
  map = true,
  modes = { "n", "o" },
})
```

The `text_search_2_char` extractor prompts for 2 characters before showing labels.

---

## Example: Delete to Function Name

```lua
local merge = require("smart-motion.core.utils").action_utils.merge

require("smart-motion").register_motion("dfn", {
  collector = "treesitter",
  extractor = "pass_through",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = merge({ "jump", "delete" }),
  map = true,
  modes = { "n" },
  metadata = {
    motion_state = {
      ts_node_types = {
        "function_declaration",
        "function_definition",
        "method_definition",
      },
      ts_child_field = "name",  -- only the "name" field of the function
    },
  },
})
```

The `ts_child_field` option makes the collector yield only the specified named field (like `name`) from matching nodes.

---

## Example: Multi-Window Search

```lua
require("smart-motion").register_motion("<leader>/", {
  collector = "lines",
  extractor = "live_search",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n" },
  metadata = {
    motion_state = {
      multi_window = true,
    },
  },
})
```

Setting `multi_window = true` makes the collector run across all visible windows.

---

## Treesitter Collector Modes

The `treesitter` collector supports four modes depending on which fields you set:

### 1. Raw Query (`ts_query`)

Full treesitter query power:

```lua
metadata = {
  motion_state = {
    ts_query = "(function_declaration) @func",
  },
}
```

### 2. Node Type Matching (`ts_node_types`)

Jump to nodes of specific types:

```lua
metadata = {
  motion_state = {
    ts_node_types = { "function_declaration", "class_definition" },
  },
}
```

### 3. Child Field (`ts_node_types` + `ts_child_field`)

Jump to a specific named field of matched nodes:

```lua
metadata = {
  motion_state = {
    ts_node_types = { "function_declaration" },
    ts_child_field = "name",  -- jump to function names
  },
}
```

### 4. Yield Children (`ts_node_types` + `ts_yield_children`)

Jump to individual children of container nodes (like arguments):

```lua
metadata = {
  motion_state = {
    ts_node_types = { "arguments", "parameters" },
    ts_yield_children = true,
    ts_around_separator = true,  -- include commas in range
  },
}
```

---

## Adding motion_state

The `metadata.motion_state` field lets you set initial state for your motion:

```lua
metadata = {
  motion_state = {
    direction = "after",        -- or "before"
    multi_window = true,        -- enable multi-window
    ts_node_types = { ... },    -- for treesitter
    diagnostic_severity = ...,  -- for diagnostics
    sort_by = "sort_weight",    -- sort targets by metadata
    sort_descending = false,    -- sort direction
  },
},
```

See **[API Reference](API-Reference.md)** for all motion_state fields.

---

## Registering in Your Config

With lazy.nvim:

```lua
{
  "FluxxField/smart-motion.nvim",
  config = function()
    local sm = require("smart-motion")

    sm.setup({
      presets = { ... },
    })

    -- Register custom motions after setup
    sm.register_motion("gw", {
      collector = "lines",
      extractor = "words",
      filter = "filter_words_after_cursor",
      visualizer = "hint_start",
      action = "jump_centered",
      map = true,
      modes = { "n", "v" },
    })
  end,
}
```

---

## Creating Custom Modules

Want to go deeper? You can create your own collectors, extractors, filters, visualizers, and actions.

### Custom Filter

```lua
local M = {}

function M.run(targets, ctx, cfg, motion_state)
  -- Keep only targets containing "TODO"
  return vim.tbl_filter(function(target)
    return target.text:match("TODO")
  end, targets)
end

return M
```

Register it:

```lua
require("smart-motion.core.registries"):get().filters.register("todo_only", M)
```

Use it:

```lua
filter = "todo_only"
```

### Custom Action

```lua
local M = {}

function M.run(ctx, cfg, motion_state)
  local target = motion_state.selected_jump_target
  if not target then return end

  -- Do something with the target
  vim.notify("Selected: " .. target.text)
end

return M
```

Register it:

```lua
require("smart-motion.core.registries"):get().actions.register("notify_target", M)
```

Use it:

```lua
action = "notify_target"
```

---

## Infer Mode (Advanced)

The `infer` flag enables composable operators like `d` + motion:

```lua
require("smart-motion").register_motion("d", {
  infer = true,
  action = "delete",
  map = true,
  modes = { "n" },
})
```

When `infer = true`:
1. First keypress (`d`) triggers the operator
2. Second keypress (`w`) determines the motion
3. Pipeline runs with the motion, action is applied

This is how SmartMotion creates `dw`, `cj`, `y]]` etc. without defining every combination.

---

## Tips

1. **Start simple** — Get a basic motion working, then add complexity.

2. **Use existing modules** — Browse the built-in collectors, extractors, etc. before writing custom ones.

3. **Test in operator-pending** — Add `"o"` to modes if you want your motion to work with native operators.

4. **Check multi-window** — Set `multi_window = true` if your motion makes sense across splits.

5. **Debug with logging** — Enable `vim.g.smart_motion_log_level = "debug"` to see what's happening.

---

## Next Steps

→ **[Pipeline Architecture](Pipeline-Architecture.md)** — Deep dive into each pipeline stage

→ **[API Reference](API-Reference.md)** — Complete module and motion_state reference

→ **[Debugging](Debugging.md)** — Troubleshooting tips
