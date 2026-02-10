# Debugging

Tips and techniques for troubleshooting SmartMotion.

---

## Enable Logging

SmartMotion has a built-in logging system:

```lua
vim.g.smart_motion_log_level = "debug"
```

**Levels:**
- `"off"`: No logging (default)
- `"error"`: Errors only
- `"warn"`: Warnings and errors
- `"info"`: Info, warnings, errors
- `"debug"`: Everything

View logs in `:messages`.

---

## Log Inside Modules

Add logging to any module:

```lua
local log = require("smart-motion.core.log")

function M.run(ctx, cfg, motion_state)
  log.debug("Targets found:", #motion_state.targets)
  log.debug("Selected target:", vim.inspect(motion_state.selected_jump_target))
end
```

---

## Inspect Motion State

The `motion_state` table contains everything about the current motion:

```lua
function M.run(ctx, cfg, motion_state)
  log.debug("Full motion state:", vim.inspect(motion_state))
end
```

Key fields to check:
- `motion_state.targets`: All collected targets
- `motion_state.selected_jump_target`: User's selection
- `motion_state.search_text`: Current search input
- `motion_state.multi_window`: Multi-window enabled?

---

## Common Issues

### Labels Not Appearing

**Check:**
1. Is the motion registered?
   ```lua
   :lua print(vim.inspect(require("smart-motion.core.registries"):get().motions.get_by_name("w")))
   ```

2. Are targets being collected?
   ```lua
   -- Add to your motion config temporarily
   action = function(ctx, cfg, motion_state)
     print("Targets:", #motion_state.targets)
   end
   ```

3. Is the filter too restrictive?
   - Try `filter = "default"` to see all targets

4. Are highlights visible?
   ```lua
   highlight = {
     hint = { fg = "#FFFFFF", bg = "#FF0000" },  -- high contrast
   }
   ```

### Motion Not Working

**Check:**
1. Is the keymap created?
   ```lua
   :nmap w
   ```

2. Is another plugin overriding it?
   - Load SmartMotion last, or
   - Use a different trigger key

3. Is the mode correct?
   - Check `modes = { "n", "v", "o" }` in config

### Wrong Targets Collected

**Check:**
1. Collector correct?
   - `"lines"` for text, `"treesitter"` for syntax

2. Extractor correct?
   - `"words"` vs `"lines"` vs `"live_search"`

3. Filter correct?
   - `"filter_words_after_cursor"` vs `"filter_visible"`

### Multi-Window Not Working

**Check:**
1. Is it enabled?
   ```lua
   metadata = {
     motion_state = {
       multi_window = true,
     },
   }
   ```

2. Are you in operator-pending mode?
   - Multi-window is disabled in `"o"` mode

3. Are windows visible?
   - Only non-floating windows are included

### Treesitter Not Finding Nodes

**Check:**
1. Is treesitter installed for the language?
   ```lua
   :TSInstall lua
   :TSInstall python
   ```

2. Is the parser loaded?
   ```lua
   :lua print(vim.treesitter.get_parser())
   ```

3. Are node types correct?
   ```lua
   -- View all nodes in current buffer
   :InspectTree
   ```

4. Cross-language compatibility?
   - Different languages use different node type names
   - Check treesitter playground for your language

---

## Debugging Techniques

### 1. Simplify the Pipeline

Replace components one at a time to isolate the issue:

```lua
-- Test with simplest config
{
  collector = "lines",
  extractor = "words",
  filter = "default",        -- no filtering
  visualizer = "hint_start",
  action = function(ctx, cfg, motion_state)
    print("Selected:", vim.inspect(motion_state.selected_jump_target))
  end,
}
```

### 2. Print Target Counts

```lua
action = function(ctx, cfg, motion_state)
  print("Total targets:", #motion_state.targets)
  print("First target:", vim.inspect(motion_state.targets[1]))
end
```

### 3. Check Context

```lua
action = function(ctx, cfg, motion_state)
  print("Buffer:", ctx.bufnr)
  print("Window:", ctx.winid)
  print("Cursor:", ctx.cursor_line, ctx.cursor_col)
  print("Mode:", ctx.mode)
end
```

### 4. Validate Modules

Check if a module is registered:

```lua
local registries = require("smart-motion.core.registries"):get()

-- Check collector
print(vim.inspect(registries.collectors.get_by_name("lines")))

-- Check filter
print(vim.inspect(registries.filters.get_by_name("filter_words_after_cursor")))
```

### 5. Test Coroutines

For collectors/extractors, test the coroutine directly:

```lua
local collector = require("smart-motion.collectors.lines")
local ctx = { bufnr = 0, winid = 0, cursor_line = 0, cursor_col = 0 }
local cfg = {}
local motion_state = {}

local co = collector.run(ctx, cfg, motion_state)
local ok, data = coroutine.resume(co, ctx, cfg, motion_state)
print("First yield:", vim.inspect(data))
```

---

## High-Contrast Debugging

Make everything super visible:

```lua
require("smart-motion").setup({
  highlight = {
    hint = { fg = "#FFFFFF", bg = "#FF0000", bold = true },
    two_char_hint = { fg = "#000000", bg = "#00FF00", bold = true },
    dim = { fg = "#333333" },
  },
  disable_dim_background = false,
})
```

---

## Check for Conflicts

### Plugin Load Order

Make sure SmartMotion loads after plugins that might override keys:

```lua
-- lazy.nvim
{
  "FluxxField/smart-motion.nvim",
  priority = 100,  -- load later
}
```

### Keymap Conflicts

Check what's mapped to a key:

```lua
:verbose nmap w
:verbose nmap s
```

### Which-Key

If using which-key, it might delay or intercept:

```lua
-- Exclude SmartMotion keys from which-key
require("which-key").setup({
  triggers_blacklist = {
    n = { "w", "b", "e", "s", "f", "d", "y", "c" },
  },
})
```

---

## Report Issues

If you find a bug:

1. Enable debug logging
2. Reproduce the issue
3. Copy `:messages` output
4. Note your Neovim version (`:version`)
5. Note your config
6. Open an issue: https://github.com/FluxxField/smart-motion.nvim/issues

Include:
- What you expected
- What happened
- Steps to reproduce
- Minimal config that reproduces the issue

---

## Development Mode

For plugin development, create a test config:

```lua
-- test_config.lua
vim.g.smart_motion_log_level = "debug"

require("smart-motion").setup({
  presets = {
    words = true,
  },
  highlight = {
    hint = { fg = "#FF0000", bg = "#FFFF00" },
  },
})

-- Test custom motion
require("smart-motion").register_motion("test", {
  collector = "lines",
  extractor = "words",
  filter = "default",
  visualizer = "hint_start",
  action = function(ctx, cfg, motion_state)
    print("Targets:", #motion_state.targets)
    print("Selected:", vim.inspect(motion_state.selected_jump_target))
  end,
  map = true,
  modes = { "n" },
  trigger = "<leader>t",
})
```

Run:
```bash
nvim -u test_config.lua somefile.lua
```

---

## Next Steps

→ **[Configuration](Configuration.md)**: All options

→ **[API Reference](API-Reference.md)**: Complete reference

→ **[Building Custom Motions](Building-Custom-Motions.md)**: Create your own
