# SmartMotion Tests

SmartMotion has two kinds of tests: an **automated test suite** run headlessly via [mini.test](https://github.com/echasnovski/mini.test), and **interactive playground files** for manual testing in Neovim.

---

## Automated Test Suite

548 tests across 43 files covering pipeline engine, registries, filters, config validation, history persistence, textobjects, pairs, surround, and more.

### Running Tests

```bash
# Run the full suite
make test

# Run a single test file
make test-file FILE=test_history.lua
```

Both commands launch Neovim in headless mode. Output shows `o` for pass and `x` for fail.

### Test Structure

Every test file follows the same pattern:

```lua
local MiniTest = require("mini_test")
local expect = MiniTest.expect
local helpers = require("tests.helpers")

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      helpers.setup_plugin()   -- fresh plugin state
    end,
    post_case = helpers.cleanup, -- wipe buffers, clear package.loaded
  },
})

T["group"]["test name"] = function()
  helpers.create_buf({ "hello world" })
  helpers.set_cursor(1, 0)

  -- test logic here
  expect.equality(actual, expected)
end

return T
```

### Test Helpers (`tests/helpers.lua`)

| Helper | Description |
|--------|-------------|
| `setup_plugin(overrides?)` | Calls `require("smart-motion").setup()` with a test config that disables timing-dependent features |
| `create_buf(lines)` | Creates a scratch buffer with the given lines and sets it as current |
| `set_cursor(row, col)` | Sets cursor position (1-indexed row, 0-indexed col) |
| `get_cursor()` | Returns current cursor position |
| `build_ctx(overrides?)` | Builds a minimal `SmartMotionContext` from the current window/buffer |
| `get_buf_lines()` | Returns all lines from the current buffer |
| `get_register(reg)` | Returns the contents of a vim register |
| `cleanup()` | Deletes all buffers and clears `package.loaded` for fresh state |

The default test config (`helpers.test_config`) sets `flow_state_timeout_ms = 0`, `native_search = false`, `dim_background = false`, and `presets = {}` to keep tests deterministic.

### Test Files

| File | What It Covers |
|------|---------------|
| `test_actions.lua` | Jump, yank, delete, change actions |
| `test_actions_extended.lua` | Action chain execution, operator-pending behavior |
| `test_auto_select.lua` | Single-target auto-selection |
| `test_char_repeat.lua` | `_find_matches`, `_filter_by_direction` for char repeat |
| `test_collectors.lua` | Patterns, quickfix, lines collectors |
| `test_composed_filters.lua` | Composed filter registration, direction metadata, behavioral tests |
| `test_config.lua` | Config validation, defaults, deprecated field handling |
| `test_consts.lua` | Constants integrity |
| `test_context.lua` | Context building and fields |
| `test_diagnostics_collector.lua` | LSP diagnostics collector, severity filtering |
| `test_engine_setup.lua` | `setup.run()`, motion loading, metadata merge, per-mode overrides |
| `test_exit_events.lua` | `throw`, `wrap`, `protect`, `safe` exit event system |
| `test_extractors.lua` | Words and lines extractors |
| `test_filetype_dispatch.lua` | Module swapping, motion_state merge, deep-copy safety |
| `test_filters.lua` | Primitive filters (cursor line, after/before cursor, visible) |
| `test_flow_state.lua` | Flow state timeout and chaining |
| `test_fuzzy.lua` | Fuzzy matching scoring |
| `test_highlight.lua` | Highlight application and cleanup |
| `test_highlight_setup.lua` | Highlight group creation, custom colors |
| `test_hints.lua` | Hint label assignment |
| `test_history.lua` | History add/last/clear, dedup, frecency, serialization, pins |
| `test_history_persistence.lua` | Disk save/load, merge-with-disk, global pins, version compat |
| `test_label_conflict.lua` | Label conflict resolution |
| `test_marks_collector.lua` | Vim marks collector, local-only filtering |
| `test_merge.lua` | `merge_actions`, `merge_filters` chain execution and metadata |
| `test_modifiers.lua` | Sort, proximity, reverse modifiers |
| `test_module_loader.lua` | Module resolution, fallback to default, infer action handling |
| `test_motions.lua` | Motion validation, registration, composable lookup |
| `test_pass_through_visualizer.lua` | Auto-select first target, early exit, metadata |
| `test_pipeline.lua` | Pipeline data flow, coroutine protocol |
| `test_pipeline_integration.lua` | Full `setup.run()` → `pipeline.run()`, engine loop, count_select |
| `test_plugin_api.lua` | Public API surface for all registries, custom registration |
| `test_presets.lua` | Preset loading, partial enable/disable |
| `test_registry.lua` | Registry CRUD operations, dedup |
| `test_search.lua` | Search pattern building |
| `test_selection_handlers.lua` | Selection handler dispatch |
| `test_state.lua` | Motion state management |
| `test_targets.lua` | Target creation and properties |
| `test_text_search.lua` | Literal match extraction, `\V` pattern, registry variants |
| `test_utils.lua` | Utility functions |
| `test_visual_select.lua` | `_collect_word_targets`, textobject visual selection |
| `test_textobjects.lua` | 44 tests for the textobject registry, key resolver, treesitter/pair textobjects, surround operators, backwards compatibility, infer integration |
| `test_pairs.lua` | 34 tests for pair definitions, pair collector, pair extractor, surround presets |

### Writing New Tests

1. Create `tests/test_<name>.lua` following the pattern above
2. Use `helpers.setup_plugin()` in `pre_case` and `helpers.cleanup` in `post_case`
3. For testing pipeline modules (collectors, extractors, filters), work with the raw `.run()` functions rather than the wrapped registry versions
4. Tests that need buffer content should use `helpers.create_buf()` and `helpers.set_cursor()`
5. For testing exit events, wrap calls with `require("smart-motion.core.events.exit").wrap(fn)` to catch thrown exits

The test runner (`tests/run_tests.lua`) automatically discovers all `tests/test_*.lua` files.

---

## Interactive Playground Files

Manual test files for trying SmartMotion presets interactively. Open them in Neovim with SmartMotion loaded and follow the comment instructions.

### Quick Start

```vim
" Open a test file
:e tests/words_lines.lua

" Test multi-window: open a second file in a vertical split
:vsplit tests/search.lua
```

### Files

| File | Presets Covered |
|------|----------------|
| `words_lines.lua` | `w`, `b`, `e`, `ge`, `j`, `k` |
| `search.lua` | `s`, `S`, `f`, `F`, `t`, `T`, `;`, `,`, `gs`, native `/` search |
| `operators.lua` | Composable operators (`d`, `y`, `c`, `p`, `P` + any motion), until (`dt`, `dT`, `yt`, `yT`, `ct`, `cT`), remote (`rdw`, `rdl`, `ryw`, `ryl`), operator-pending (`>w`, `gUw`, etc.) |
| `treesitter.lua` | `]]`, `[[`, `]c`, `[c`, `]b`, `[b`, `af`, `if`, `ac`, `ic`, `aa`, `ia`, `fn`, `saa`, `gS`, `R` |
| `diagnostics.lua` | `]d`, `[d`, `]e`, `[e` (requires LSP) |
| `misc.lua` | `.` (repeat), `gmd`, `gmy` |

### Multi-Window Testing

SmartMotion labels appear across all visible windows for search, treesitter, and diagnostic motions. To test:

1. Open two files side by side: `:vsplit tests/treesitter.lua`
2. Press `s` or `]]` — labels should appear in **both** windows
3. Select a label in the other window — cursor jumps across

Word and line motions (`w`, `b`, `j`, `k`) stay in the current window.

### Tips

- Files can be freely edited during testing — use `:e!` to reload the original
- Press `ESC` at any label prompt to cancel cleanly
- Use `:checkhealth` to verify treesitter parsers are installed
- `diagnostics.lua` requires `lua_ls` or another LSP server to generate real diagnostics
