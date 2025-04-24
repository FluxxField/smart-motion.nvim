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

## ?? Built-in Filters

| Name                   | Description                                  |
| ---------------------- | -------------------------------------------- |
| `default`              | No filtering - returns all targets unchanged |
| `filter_visible_lines` | Keeps only targets in visible screen range   |

> [!NOTE]
> Directional filtering (before/after cursor) is expected to move to filters in future versions.

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
