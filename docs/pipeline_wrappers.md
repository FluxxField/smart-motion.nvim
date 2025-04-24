# Pipeline Wrappers

Pipeline wrappers are a powerful optional layer in SmartMotion that allow you to **intercept and customize how a motion's pipeline is run**.

> [!TIP]
> Wrappers are how SmartMotion supports things like **live search**, **2-character find**, or **interactive filtering**. They let you re-run or mutate the pipeline flow dynamically.

---

## ✅ What a Wrapper Does

A wrapper receives the motion’s `run_pipeline()` function and takes full control of how and when it runs. It can:

- Call the pipeline once with default input
- Prompt the user for characters and run it again (e.g. `text_search`)
- Re-run the motion pipeline every time a new character is typed (e.g. `live_search`)

This gives you **complete control over pipeline timing, re-execution, or cancellation.**

---

## 📦 Built-in Pipeline Wrappers

| Name          | Description                                             |
| ------------- | ------------------------------------------------------- |
| `default`     | Runs the pipeline once without modification             |
| `text_search` | Prompts user for 1-2 characters before running pipeline |
| `live_search` | Lets user type live search input and re-runs pipeline   |

---

## 🧱 Example Usage

In a motion preset:

```lua
pipeline_wrapper = "text_search"
```

This runs the pipeline after asking the user for `opts.num_of_char` characters.

Another example:

```lua
pipeline_wrapper = "live_search"
```

This lets you interactively type a search term, and the wrapper re-runs the motion pipeline on every input.

---

## ✨ Building a Custom Wrapper

A wrapper receives a function to run the pipeline and full access to context and state:

```lua
---@type SmartMotionPipelineWrapperModule
local M = {}

function M.run(run_pipeline, ctx, cfg, motion_state, opts)
  -- optionally gather input or mutate state
  -- then call the pipeline
  run_pipeline(ctx, cfg, motion_state, opts)
end

return M
```

Register it:

```lua
require("smart-motion.core.registries")
  :get().pipeline_wrappers.register("my_wrapper", M)
```

---

## 🧠 Why Use a Wrapper?

Wrappers are ideal for:

- Multi-character inputs (like `f/2`)
- Search box integrations
- Modal flows like Telescope or LSP query
- Any interaction where the user provides dynamic input

> [!NOTE]
> Wrappers don’t change pipeline **modules** — they change how and when the pipeline is **invoked**.

---

## 🔮 Future Ideas

- Scroll-aware wrappers for visual modes
- Keymap recording for macro support
- In-buffer interactive menus for selecting targets

---

Next:

- [`custom_motion.md`](./custom_motion.md)
