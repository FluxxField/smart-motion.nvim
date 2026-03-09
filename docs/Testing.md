# Testing

SmartMotion uses [mini.test](https://github.com/echasnovski/mini.test) for automated testing. The test suite runs headlessly and requires no extra dependencies beyond Neovim.

---

## Running Tests

```bash
# Full suite (470 tests)
make test

# Single file
make test-file FILE=test_history.lua
```

Both commands run `nvim --headless -u tests/run_tests.lua`. Output shows `o` for pass and `x` for fail.

---

## What's Tested

The suite covers the non-interactive core of the plugin:

| Area | Tests Cover |
|------|-------------|
| **Pipeline engine** | `setup.run()` → collector → extractor → modifier → filter → targets flow |
| **Registry system** | Registration, lookup, dedup for all 7 registry types |
| **Motion registration** | Validation, `register_motion`, composable prefix matching |
| **Filters** | Primitive filters, composed filters, direction metadata |
| **Config** | Field validation, defaults, deprecated field handling |
| **Exit events** | `throw`, `wrap`, `protect`, `safe` flow control |
| **History** | Add/dedup/frecency, serialization, disk persistence, merge-with-disk, global pins |
| **Merge utilities** | `merge_actions`, `merge_filters` chain execution |
| **Module loader** | Resolution, default fallback, infer action handling |
| **Filetype dispatch** | Module swapping, metadata deep-copy |
| **Extractors** | Words, text search coroutine yielding |
| **Collectors** | Lines, patterns, marks, quickfix, diagnostics |
| **Public API** | All registry interfaces, consts, custom registration |

Interactive functions (visualizer label selection, `getchar()`-based input, operator inference) are tested manually using the [playground files](https://github.com/FluxxField/smart-motion.nvim/tree/dev/tests#interactive-playground-files).

---

## Writing Tests

### File Structure

Create `tests/test_<name>.lua`:

```lua
local MiniTest = require("mini_test")
local expect = MiniTest.expect
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      helpers.setup_plugin()
    end,
    post_case = helpers.cleanup,
  },
})

T["group"]["describes the behavior"] = function()
  helpers.create_buf({ "hello world" })
  helpers.set_cursor(1, 0)

  local result = some_function()
  expect.equality(result, expected)
end

return T
```

The runner auto-discovers all `tests/test_*.lua` files.

### Key Helpers

```lua
helpers.setup_plugin(overrides?)  -- fresh plugin with test config
helpers.create_buf(lines)         -- scratch buffer with content
helpers.set_cursor(row, col)      -- 1-indexed row, 0-indexed col
helpers.build_ctx()               -- minimal SmartMotionContext
helpers.cleanup()                 -- wipe buffers, clear modules
```

The test config disables timing (`flow_state_timeout_ms = 0`), search UI (`native_search = false`), and background dimming to keep tests deterministic.

### Testing Pipeline Modules

For collectors, extractors, and filters, test the raw `.run()` function directly rather than the wrapped registry version:

```lua
-- Testing a collector
local collector = require("smart-motion.collectors.marks")
local co = collector.run()
local ok, val = coroutine.resume(co, ctx, cfg, ms)

-- Testing a filter
local filter = require("smart-motion.filters.filter_words_after_cursor")
local result = filter.run(ctx, nil, ms, target)

-- Testing an extractor
local extractor = require("smart-motion.extractors.words")
local co = extractor.run(nil, nil, ms, data)
```

### Testing Exit Events

Wrap calls that may throw exit events:

```lua
local exit = require("smart-motion.core.events.exit")

local exit_type = exit.wrap(function()
  -- code that may throw AUTO_SELECT, EARLY_EXIT, etc.
end)

expect.equality(exit_type, "auto_select")
```

### Testing Disk I/O

Override filepath functions to use temp directories:

```lua
local history = require("smart-motion.core.history")
local tmpdir = vim.fn.tempname()
vim.fn.mkdir(tmpdir, "p")

local orig = history._get_history_filepath
history._get_history_filepath = function()
  return tmpdir .. "/test.json"
end

-- ... test save/load ...

history._get_history_filepath = orig
os.remove(tmpdir .. "/test.json")
```

---

## CI

Tests run on GitHub Actions for Neovim `v0.10.4`, `stable`, and `nightly` on every push to `master`/`dev` and on pull requests.

```yaml
# .github/workflows/test.yml
- uses: rhysd/action-setup-vim@v1
  with:
    neovim: true
    version: ${{ matrix.nvim-version }}
- run: make test
```

---

## Next Steps

> **[Debugging](Debugging.md)**: Logging, inspecting motion state, troubleshooting

> **[Pipeline Architecture](Pipeline-Architecture.md)**: How modules connect

> **[API Reference](API-Reference.md)**: Complete module reference
