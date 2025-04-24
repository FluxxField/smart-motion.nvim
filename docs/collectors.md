# Collectors

Collectors are the **starting point** of every SmartMotion pipeline.
Their job is to gather a raw dataset — often lines of text from the current buffer — that can later be filtered, extracted, and visualized.

> [!TIP]
> Think of collectors as _input sources_. They define **where to look** before SmartMotion decides **what to act on**.

---

## ✅ What a Collector Does

A collector receives context (e.g. buffer, window) and returns a list (or stream) of strings or objects that represent the data to process.

This could be:

- All lines in the current buffer
- Just visible lines in the window
- Lines from multiple open buffers
- Results from Telescope or git

Anything that produces a list of “searchable units” can be a collector.

---

## 🔄 Generator-Based Design

SmartMotion collectors are **Lua coroutines** — they yield data as it's needed.

This has two big benefits:

1. **Early-exit performance**: Extractors can pull _just one match_ without collecting the full buffer.
   - When looking for the first valid target, the extractor runs once, and the collector yields only once — super efficient.
2. **Streaming scalability**: When building the full target list (for label generation), the entire collector output is walked, but only once.

This means the **entire pipeline only needs 2 loops total**:

- One loop to find the first match
- One loop to get all targets (if needed for hint labels)

> [!IMPORTANT]
> This is why both collectors and extractors are coroutines. It avoids unnecessary memory allocations and keeps everything responsive even with huge buffers.

---

## 📦 Built-in Collectors

| Name    | Description                             |
| ------- | --------------------------------------- |
| `lines` | Yields every line in the current buffer |

> [!NOTE]
> Additional built-in collectors like `visible_lines`, `multi_buffer_lines`, or `telescope_results` are planned or may be available in user modules.

---

## 🧱 Example Use

In a motion definition:

```lua
pipeline = {
  collector = "lines",
  extractor = "words",
  visualizer = "hint_start",
}
```

The collector here yields all lines in the buffer. The extractor pulls word targets from those lines.

---

## ✨ Building Your Own Collector

A collector is a module that implements a coroutine-style `run(ctx, cfg, motion_state)` function.

```lua
---@type SmartMotionCollectorModule
local M = {}

function M.run(ctx, cfg, motion_state)
  return coroutine.create(function()
    local lines = vim.api.nvim_buf_get_lines(ctx.bufnr, 0, -1, false)

    for i, line in ipairs(lines) do
      coroutine.yield({
        text = line,
        line_number = i - 1,
      })
    end
  end)
end

return M
```

> [!NOTE]
> This version yields **structured line objects** with metadata (`text`, `line_number`) — which is required by extractors like `lines`.

Register your collector like this:

```lua
require("smart-motion.core.registries")
  :get().collectors.register("my_lines", MyCollector)
```

---

## 🧪 Shared Module Context

All modules and wrappers receive:

| Param          | Description                                                                                                                                                                                                |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ctx`          | Context object (bufnr, winid, etc.)                                                                                                                                                                        |
| `cfg`          | User-defined plugin configuration from `setup(opts)` - includes global fields like `keys`, `presets`, and `highlight`. Rarely needed inside modules, but useful if global toggles or flags are introduced. |
| `motion_state` | Mutable state that persists across pipeline steps and ferries shared data                                                                                                                                  |

> [!WARNING]
> Only `motion_state` is intended to be mutated. Use it to store extracted targets, intermediate results, or flags shared between modules.

---

## 🔮 Future Possibilities

Collectors could be written to fetch from:

- Git changes (e.g., jump to modified lines)
- Telescope search results
- LSP diagnostics or references
- Multiple buffers or project-wide files

SmartMotion is designed to accommodate all of these.

---

For the next step in the pipeline, check out:

- [`extractors.md`](./extractors.md)
- [`filters.md`](./filters.md)
