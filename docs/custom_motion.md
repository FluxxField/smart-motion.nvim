# Creating a Custom Motion

This guide walks you through creating your own motion using SmartMotion's modular pipeline system.

> [!IMPORTANT]
> SmartMotion motions are **composable**, made up of collectors, extractors, filters, visualizers, and actions - plus an optional pipeline wrapper.

---

## ?? Basic Motion Structure

> [!TIP]
> The first argument to `register_motion(name, config)` becomes the motion's name. If `trigger_key` is not explicitly provided, it defaults to this name.
>
> This means you can do things like:
>
> ```lua
> require("smart-motion").register_motion("find_2char", {
>   trigger_key = "f",
>   ...
> })
> ```

Here's what a minimal custom motion might look like:

```lua
require("smart-motion").register_motion("m", {
  pipeline = {
    collector = "lines",
    extractor = "words",
    filter = "filter_visible_lines",
    visualizer = "hint_start",
  },
  pipeline_wrapper = "default",
  action = "jump",
  state = {
    direction = DIRECTION.AFTER_CURSOR,
    hint_position = HINT_POSITION.START,
  },
  map = true,
  modes = { "n" },
  metadata = {
    label = "My Custom Motion",
    description = "Example motion using word targets",
  },
})
```

This would:

- Extract words from all visible lines
- Visualize with hints
- Let the user select one
- Then jump to it

---

## ?? Step-by-Step Breakdown

### 1. Collector

Fetches source data. Most start with:

```lua
collector = "lines"
```

But you could register one for git changes, Telescope results, etc.

### 2. Extractor

Extracts targets from the collected data.

```lua
extractor = "words"
```

Extractors yield target objects, including position and metadata.

### 3. Filter (Optional)

Narrows down the targets based on visibility, direction, or custom rules.

```lua
filter = "filter_visible_lines"
```

### 4. Visualizer

Renders your targets however you want - hints, popup, floating menu, etc.

```lua
visualizer = "hint_start"
```

### 5. Pipeline Wrapper (Optional)

Controls _when_ and _how_ the pipeline runs.

```lua
pipeline_wrapper = "text_search"
```

### 6. Action

What happens when a target is selected.

```lua
action = "jump"
```

Or use `merge({ "jump", "delete" })` for compound motions.

---

## ?? State and Opts

Your motion config can include the following:

- `state`: for static configuration like `direction`, `hint_position`
- `opts`: for dynamic input like `num_of_char`

These are passed to all modules in the pipeline.

> [!NOTE]
> In a future version:
>
> - `opts` will be deprecated - all dynamic input will be stored directly in `motion_state`
> - `direction` will be handled by filters instead of state
> - `hint_position` will likely become a property of the visualizer at registration time, so you'll register multiple visualizers for `before`, `after`, or `both` - reducing the need to specify `hint_position` in `state`
>
> This improves consistency and separation of concerns.

---

## ?? Full Example: `2-char Find`

```lua
require("smart-motion").register_motion("f", {
  pipeline = {
    collector = "lines",
    extractor = "text_search",
    filter = "filter_visible_lines",
    visualizer = "hint_start",
  },
  pipeline_wrapper = "text_search",
  action = "jump",
  state = {
    direction = DIRECTION.AFTER_CURSOR,
    hint_position = HINT_POSITION.START,
  },
  opts = {
    num_of_char = 2,
  },
  map = true,
  modes = { "n" },
})
```

---

## ?? Full Motion Type Reference

Here are the fields you can use when calling `register_motion(name, config)`:

```ts
SmartMotionMotionEntry {
  trigger_key?: string  -- Optional override; defaults to `name`
  infer?: boolean   -- Is this an action trigger?
  pipeline: {
    collector: string
    extractor: string
    visualizer: string
    filter?: string
  }
  pipeline_wrapper?: string
  action: string
  state?: SmartMotionMotionState  -- Motion direction, hint position, etc.
  opts?: table                    -- Dynamic input like character count (deprecated soon)
  map?: boolean                   -- Whether to auto-create keymap
  modes?: string[]               -- Vim modes ("n", "v", etc.)
  name?: string                  -- Internal ID; usually same as first argument
  metadata?: {
    label?: string
    description?: string
  }
}
```

> [!NOTE]
> Most fields are optional, and many are auto-filled during registration:
>
> - `trigger_key` defaults to the motion name
> - `name`, `label`, and `description` are generated if not given
> - `opts` will be removed in favor of writing directly to `motion_state`

---

## Example: Treesitter Function Jump

This motion jumps to function definitions after the cursor using the treesitter collector:

```lua
require("smart-motion").register_motion("]]", {
  collector = "treesitter",
  extractor = "pass_through",
  modifier = "weight_distance",
  filter = "filter_words_after_cursor",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n" },
  metadata = {
    label = "Jump to Next Function",
    description = "Jump to a function definition after the cursor",
    motion_state = {
      ts_node_types = {
        "function_declaration",
        "function_definition",
        "arrow_function",
        "method_definition",
        "function_item",
        "method_declaration",
        "method",
      },
    },
  },
})
```

The `treesitter` collector walks the syntax tree for matching node types and yields them as targets. Since targets are already fully formed, the `pass_through` extractor is used.

---

## Example: Diagnostics Jump

This motion jumps to LSP error diagnostics after the cursor:

```lua
require("smart-motion").register_motion("]e", {
  collector = "diagnostics",
  extractor = "pass_through",
  modifier = "weight_distance",
  filter = "filter_words_after_cursor",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n" },
  metadata = {
    label = "Jump to Next Error",
    description = "Jump to an error diagnostic after the cursor",
    motion_state = {
      diagnostic_severity = vim.diagnostic.severity.ERROR,
    },
  },
})
```

The `diagnostics` collector fetches `vim.diagnostic.get()` results and the `diagnostic_severity` field in `motion_state` filters to only errors.

---

## Related Topics

- [`registering.md`](./registering.md)
- [`actions.md`](./actions.md)
- [`pipeline_wrappers.md`](./pipeline_wrappers.md)
