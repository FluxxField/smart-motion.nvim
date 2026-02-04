# Filters

Filters are the **third stage** in the SmartMotion pipeline. They operate after targets have been extracted and decide **which ones should remain visible or selectable**.

> [!TIP]
> Extractors generate all possible targets. Filters narrow them down based on context - like direction, visibility, or custom logic.

---

## ? What a Filter Does

A filter receives a list of targets (from an extractor) and returns a modified version of that list.

Typical filter jobs:

- Remove targets before/after the cursor (based on `motion_state.direction`)
- Limit targets to those visible in the current window
- Filter by custom metadata or motion-specific needs

---

## ?? Example Usage

Defined in the pipeline:

```lua
pipeline = {
  collector = "lines",
  extractor = "words",
  filter = "filter_visible_lines",
  visualizer = "hint_start",
}
```

This would:

- Extract words from all lines
- Only keep those visible in the current window

---

## Built-in Filters

### Base Filters

| Name                   | Description                                  |
| ---------------------- | -------------------------------------------- |
| `default`              | No filtering — returns all targets unchanged |
| `filter_visible`       | Keeps only targets visible in the current window |
| `filter_cursor_line_only` | Keeps only targets on the cursor line     |
| `first_target`         | Keeps only the first target                  |

### Directional Filters (Merged Composites)

These filters combine visibility filtering with directional logic. Each is a merged pipeline of simpler filters.

| Name                                        | Description                                          |
| ------------------------------------------- | ---------------------------------------------------- |
| `filter_lines_after_cursor`                 | Visible lines after the cursor                       |
| `filter_lines_before_cursor`                | Visible lines before the cursor                      |
| `filter_lines_around_cursor`                | Visible lines before and after the cursor            |
| `filter_words_after_cursor`                 | Visible words after the cursor                       |
| `filter_words_before_cursor`                | Visible words before the cursor                      |
| `filter_words_around_cursor`                | Visible words before and after the cursor            |

### Cursor-Line Filters (Merged Composites)

| Name                                        | Description                                          |
| ------------------------------------------- | ---------------------------------------------------- |
| `filter_words_on_cursor_line_after_cursor`   | Words on the cursor line after the cursor           |
| `filter_words_on_cursor_line_before_cursor`  | Words on the cursor line before the cursor          |

> [!NOTE]
> Most built-in filters are merged composites — for example, `filter_words_after_cursor` combines `filter_visible_lines` + `filter_words_after_cursor` internally using the `merge()` utility from `filters/utils.lua`.

---

## ? Building Your Own Filter

A filter is a simple Lua function:

```lua
---@type SmartMotionFilterModule
local M = {}

function M.run(targets, ctx, cfg, motion_state)
  return vim.tbl_filter(function(target)
    return target.row > ctx.cursor_line  -- only after cursor
  end, targets)
end

return M
```

Then register it:

```lua
require("smart-motion.core.registries")
  :get().filters.register("only_after", MyFilter)
```

---

## ?? Future Possibilities

You could build filters for:

- Limiting based on text contents
- Highlight group presence
- Diagnostic severity from LSP
- Target types (e.g., filter out lines but keep words)

---

Continue to:

- [`visualizers.md`](./visualizers.md)
- [`actions.md`](./actions.md)
