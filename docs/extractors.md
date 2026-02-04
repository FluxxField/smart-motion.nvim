# Extractors

Extractors are the **second stage** in the SmartMotion pipeline. They receive data yielded from a collector and generate **targets** — positional objects describing where actions can apply.

> [!TIP]
> If collectors define _where_ to look, extractors decide _what_ to act on.

---

## ✅ What an Extractor Does

Extractors operate on each yielded item from the collector (often a line object) and generate one or more `SmartMotionTarget` entries. These targets include position info, visual text, and metadata that can be used for labeling, filtering, and execution.

Extractors are also written as **coroutines**, allowing for:

- Early-exit target detection (e.g. flow state or quick jump)
- Scalable, memory-efficient target generation

> [!IMPORTANT]
> Extractors should **not** apply logic for direction, cursor filtering, or context sensitivity. That logic belongs to filters. Extractors should only describe all possible targets.

---

## 🧠 Coroutine Design

Like collectors, extractors are implemented as coroutines.

- The collector is resumed to yield an item
- The extractor processes the item and can `coroutine.yield()` one or more targets
- If the pipeline needs only one match, it stops early

This system minimizes overhead and makes SmartMotion fast, even on large files.

> [!IMPORTANT]
> One coroutine loop pulls from the collector, and one loop extracts all targets — and that’s it. No extra passes are needed.

---

## 📦 Built-in Extractors

| Name                       | Description                                                                      |
| -------------------------- | -------------------------------------------------------------------------------- |
| `lines`                    | Extracts whole-line targets                                                      |
| `words`                    | Extracts words using regex-based word boundaries                                 |
| `text_search_1_char`       | Extracts 1-character search matches (used for `f`/`F`-style motions)             |
| `text_search_1_char_until` | Same as `text_search_1_char` but sets `exclude_target = true` (for `t`/`T`)     |
| `text_search_2_char`       | Extracts 2-character search matches with prefix display                          |
| `live_search`              | Continuously updates search results as the user types, with backspace support    |
| `pass_through`             | Passes collector data through without any transformation                         |

> [!NOTE]
> All built-in extractors are registered using `register_many()` in the `extractors` registry. You can override or extend them.
>
> The `text_search_*` and `live_search` extractors use a `before_input_loop` hook (via `module_wrapper`) to read user input before each pipeline iteration. The `pass_through` extractor is used with collectors like `treesitter` and `diagnostics` that already yield fully-formed targets.

---

## 🧱 Example Usage

Used inside a pipeline:

```lua
pipeline = {
  collector = "lines",
  extractor = "words",
  visualizer = "hint_start",
}
```

This example extracts visible words from all lines in the buffer.

---

## ✨ Example: Custom Word Extractor

Here’s a simplified version of a custom `words` extractor that finds word matches using regex and yields them as targets. This version omits cursor and direction logic entirely — such filtering should be handled in the `filters` module.

```lua
---@type SmartMotionExtractorModuleEntry
local M = {}

function M.run(collector, opts)
  return coroutine.create(function(ctx, cfg, motion_state)
    while true do
      local ok, data_or_error = coroutine.resume(collector, ctx, cfg, motion_state)

      if not ok then
        log.error("Collector Coroutine Error: " .. tostring(data_or_error))
        break
      end

      if data_or_error == nil then
        break
      end

      local row = line_data.line_number
      local line = line_data.text

      for match_text, start_pos in line:gmatch("()%w+") do
        local end_pos = start_pos + #match_text - 1

        coroutine.yield({
          row = row,
          col = start_pos,
          text = match_text,
          start_pos = { row = row, col = start_pos },
          end_pos = { row = row, col = end_pos },
          type = "words",
        })
      end
    end
  end)
end

return M
```

---

## 🛠 Registering Your Extractor

```lua
local extractors = require("smart-motion.core.registries"):get().extractors
extractors.register("my_extractor", MyModule)
```

You can also provide metadata and `keys` to link extractors to motion keys if using `infer = true`.

---

## 📚 Advanced Example: Word Extractor

The built-in `words` extractor:

- Uses `vim.fn.matchstrpos` to find regex-based words
- Applies cursor logic and direction-specific filtering
- Reorders results for BEFORE_CURSOR

> [!NOTE]
> This behavior will be moved into filters in the future to better separate concerns.

---

## 🔗 Next Steps

Now that you're generating targets, it's time to:

- Visualize them with [`visualizers.md`](./visualizers.md)
- Define what happens when selected using [`actions.md`](./actions.md)
