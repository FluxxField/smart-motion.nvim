# Debugging SmartMotion

This guide walks through tools, tips, and techniques for debugging motions, modules, and SmartMotion internals.

---

## 🪵 Logging Internals

SmartMotion provides an internal logger module:

```lua
local log = require("smart-motion.core.log")
```

### Logging Methods

- `log.debug(...)`
- `log.info(...)`
- `log.warn(...)`
- `log.error(...)`

By default, these are no-ops unless you enable logging.

### Enable Logging

```lua
vim.g.smart_motion_log_level = "debug"
```

Available levels: `"off"`, `"error"`, `"warn"`, `"info"`, `"debug"`

> [!TIP]
> Logs appear in `:messages` or can be written to file if you set an override.

---

## 🔍 Inspect Motion State

Each module receives `motion_state`:

```lua
function M.run(ctx, cfg, motion_state)
  log.debug(vim.inspect(motion_state))
end
```

This helps debug things like:

- Cursor position and target lists
- Flow state tracking
- Selected target metadata

---

## 🧪 Test Visualizer Behavior

If your labels or highlights aren’t showing:

- Set highlights to high contrast:
  ```lua
  highlight = {
    hint = { fg = "#FFFFFF", bg = "#000000" },
  }
  ```
- Use the `default` visualizer to isolate pipeline behavior
- Confirm your visualizer is registered properly

---

## 🔧 Validate Motion Structure

Use the built-in motion registry validation:

```lua
require("smart-motion.core.registry")("motions")._validate_motion_entry("my_motion", motion)
```

This checks for:

- Missing pipeline fields
- Invalid or unregistered module names

---

## 🛠 Overriding Components for Debugging

You can temporarily replace a module with a custom debug version:

```lua
require("smart-motion.core.registries")
  :get().actions.register("debug_action", DebugAction)
```

Use this to test:

- Target position logic
- Composite action sequences
- Wrapper behavior on edge cases

---

## 🧠 Advanced Debug Suggestions

- Use `:lua print(...)` in quick dev sessions
- Wrap functions in `pcall()` if you're testing unsafe code
- Add timestamps or `vim.fn.reltime()` to log calls
- Try a debug visualizer that shows label phases (e.g. before/after first keypress)

---

Next:

- [`config.md`](./config.md)
- [`actions.md`](./actions.md)
