# Advanced Recipes

These recipes assume you have read the **[Recipes guide](Recipes.md)** and understand how motions are assembled from pipeline parts. If terms like "collector", "extractor", or "filter" are unfamiliar, start there first.

This guide covers treesitter-powered motions, custom text objects, composable operators, and complex action composition.

---

## Custom Treesitter Motions

The `treesitter` collector walks the syntax tree and yields nodes matching `ts_node_types`. Combined with `pass_through` extractor (since treesitter already produces complete targets) and `filter_visible`, you can jump to any language construct.

### Jump to if/for/while Statements

```lua
require("smart-motion").register_motion("<leader>i", {
  collector = "treesitter",
  extractor = "pass_through",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n" },
  metadata = {
    motion_state = {
      ts_node_types = {
        "if_statement",
        "for_statement",
        "while_statement",
        "for_in_statement",
        "repeat_statement",
        "switch_statement",
        "match_expression",
      },
      multi_window = true,
    },
  },
})
```

**How it works:** The treesitter collector finds every node whose type matches the list. Labels appear on all visible control flow statements across every open window. Press a label to jump.

> **Tip:** Run `:InspectTree` in any buffer to see the exact node types your language's treesitter parser uses. Node names vary between languages.

### Jump to Function Names Only

```lua
require("smart-motion").register_motion("<leader>n", {
  collector = "treesitter",
  extractor = "pass_through",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n" },
  metadata = {
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
      ts_child_field = "name",
      multi_window = true,
    },
  },
})
```

**What's different:** The `ts_child_field = "name"` option tells the collector to yield only the `name` field of each matching node, not the entire function. So instead of labeling the full function declaration, you get a label on just the function's identifier. This is useful when you want to jump directly to function names for renaming or reference checking.

### Jump to Individual Function Parameters

```lua
require("smart-motion").register_motion("<leader>a", {
  collector = "treesitter",
  extractor = "pass_through",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n" },
  metadata = {
    motion_state = {
      ts_node_types = {
        "arguments",
        "argument_list",
        "parameters",
        "parameter_list",
        "formal_parameters",
      },
      ts_yield_children = true,
      multi_window = true,
    },
  },
})
```

**What's different:** The `ts_yield_children = true` option changes the collector's behavior. Instead of yielding the container node (the entire argument list), it yields each named child individually. So `foo(a, b, c)` produces three separate targets: one on `a`, one on `b`, and one on `c`.

### Jump to Parameters with Separator Awareness

If you want each parameter target to include its surrounding comma (useful for deletion or selection), add `ts_around_separator`:

```lua
metadata = {
  motion_state = {
    ts_node_types = { "arguments", "parameters", "formal_parameters" },
    ts_yield_children = true,
    ts_around_separator = true,
  },
},
```

**What's different:** With `ts_around_separator = true`, the range of each child target is expanded to include the adjacent comma and whitespace. Selecting or deleting a parameter will cleanly remove the separator too, preventing leftover commas.

---

## Practical Custom Motions

### Jump to TODO/FIXME Comments

```lua
require("smart-motion").register_motion("<leader>t", {
  collector = "lines",
  extractor = "words",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n" },
  metadata = {
    word_pattern = [[\v(TODO|FIXME|HACK|NOTE|XXX|WARN)]],
    motion_state = {
      multi_window = true,
    },
  },
})
```

**How it works:** The `words` extractor uses the custom `word_pattern` regex instead of the default (`\k\+\|\%(\k\@!\S\)\+` — keyword sequences or punctuation sequences). It matches only TODO-style comment tags. The `lines` collector feeds all visible buffer lines, and `multi_window = true` searches across every open split.

### Jump to Only Errors

```lua
require("smart-motion").register_motion("<leader>e", {
  collector = "diagnostics",
  extractor = "pass_through",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n" },
  metadata = {
    motion_state = {
      diagnostic_severity = vim.diagnostic.severity.ERROR,
    },
  },
})
```

**How it works:** The `diagnostics` collector gathers LSP diagnostics from the buffer. Setting `diagnostic_severity` to `ERROR` filters out warnings, hints, and info. Only error diagnostics get labels.

### Jump to Git Hunks Across All Splits

```lua
require("smart-motion").register_motion("<leader>g", {
  collector = "git_hunks",
  extractor = "pass_through",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n" },
  metadata = {
    motion_state = {
      multi_window = true,
    },
  },
})
```

**How it works:** The `git_hunks` collector finds changed regions using gitsigns.nvim (or falls back to `git diff`). With `multi_window = true`, you can jump to any modified region in any visible split.

---

## Building Text Objects

SmartMotion's pipeline can create treesitter-powered text objects that work with every vim operator.

### A Minimal Text Object: Around Loop

```lua
require("smart-motion").register_motion("al", {
  collector = "treesitter",
  extractor = "pass_through",
  modifier = "weight_distance",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = "textobject_select",
  map = true,
  modes = { "x", "o" },
  metadata = {
    motion_state = {
      ts_node_types = {
        "for_statement",
        "while_statement",
        "for_in_statement",
        "repeat_statement",
      },
      is_textobject = true,
    },
  },
})
```

**Key parts:**

1. **`action = "textobject_select"`** -- This action sets a charwise visual selection spanning the entire target range, which the pending operator then applies to.
2. **`modes = { "x", "o" }`** -- Text objects must work in visual (`x`) and operator-pending (`o`) modes. They are not registered in normal mode.
3. **`is_textobject = true`** -- This flag tells the exit system to let the operator-pending selection complete naturally instead of overriding it with a jump.

Once registered, `al` works with every operator: `dal` (delete around loop), `yal` (yank around loop), `gqal` (format around loop), `>al` (indent around loop), and any other operator you can think of.

### Inner Text Object: Body Only

```lua
require("smart-motion").register_motion("il", {
  collector = "treesitter",
  extractor = "pass_through",
  modifier = "weight_distance",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = "textobject_select",
  map = true,
  modes = { "x", "o" },
  metadata = {
    motion_state = {
      ts_node_types = {
        "for_statement",
        "while_statement",
        "for_in_statement",
        "repeat_statement",
      },
      ts_inner_body = true,
      is_textobject = true,
    },
  },
})
```

**What's different:** Adding `ts_inner_body = true` makes the collector yield only the body content of the node. For brace-delimited languages, it trims the `{` and `}` delimiters, giving you just the inner content. `dil` deletes the loop body without touching the loop statement itself.

### Making a Text Object Composable

The built-in `fn` text object demonstrates how to make a text object work with the multi-char inference system:

```lua
require("smart-motion").register_motion("fn", {
  composable = true,
  collector = "treesitter",
  extractor = "pass_through",
  modifier = "weight_distance",
  filter = "filter_visible",
  visualizer = "hint_start",
  action = "textobject_select",
  map = true,
  modes = { "o" },
  metadata = {
    motion_state = {
      ts_node_types = {
        "function_declaration",
        "function_definition",
        "arrow_function",
        "method_definition",
        "function_item",
      },
      ts_child_field = "name",
      is_textobject = true,
    },
  },
})
```

**How it works:** The `composable = true` flag registers this text object with the multi-char inference system. When you type `dfn` quickly, the infer system reads `f`, sees that `fn` is a longer composable match, waits for `n`, and resolves to the function name text object. If you type `df` and pause, it falls through to the normal find-char motion. This multi-char resolution happens automatically for any composable motion with a multi-character key.

---

## Creating Composable Operators

A composable operator is a motion with `infer = true`. It reads a second key, looks up a composable motion, inherits that motion's pipeline, and runs with its own action.

### A "Highlight" Operator

This creates an operator `gh` that composes with every motion to jump and highlight the target:

```lua
-- Step 1: Register the operator motion
require("smart-motion").register_motion("gh", {
  infer = true,
  collector = "lines",
  filter = "filter_visible",
  visualizer = "hint_start",
  map = true,
  modes = { "n" },
})

-- Step 2: Register the action with keys = {"h"} so infer can find it
local registries = require("smart-motion.core.registries"):get()

registries.actions.register("highlight_jump", {
  keys = { "h" },
  run = function(ctx, cfg, motion_state)
    local target = motion_state.selected_jump_target
    if not target then return end

    -- Jump to the target first
    require("smart-motion.actions.jump").run(ctx, cfg, motion_state)

    -- Highlight the target range
    local ns = vim.api.nvim_create_namespace("custom_highlight")
    local bufnr = target.metadata.bufnr
    vim.api.nvim_buf_add_highlight(
      bufnr, ns, "Search",
      target.start_pos.row,
      target.start_pos.col,
      target.end_pos.col
    )

    -- Clear after 2 seconds
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
      end
    end, 2000)
  end,
})
```

**How it works:**

1. You press `gh` -- the operator is triggered, `infer = true` causes it to wait for another key.
2. You press `w` -- the infer system reads the key and looks up the composable `w` motion.
3. The `w` motion's pipeline (words extractor, after-cursor filter) overrides the operator's defaults.
4. The pipeline runs: labels appear on words, you press a label to select a target.
5. The infer system finds `highlight_jump` via `keys = {"h"}` (matching the operator's action key) and executes it.

Now `ghw`, `ghj`, `ghs`, `ghf`, and every other composable motion automatically works as a highlight operation.

### Action Key Decoupling

If you want a custom trigger key that doesn't match the action key, use `trigger_key` and let the registration name serve as the action key:

```lua
require("smart-motion").register_motion("d", {
  infer = true,
  trigger_key = "<leader>m",
  -- action_key defaults to "d" (the first argument / registration name)
  collector = "lines",
  filter = "filter_visible",
  visualizer = "hint_start",
  map = true,
  modes = { "n" },
})
```

**How it works:** The `trigger_key` is the actual keymap that gets created (`<leader>m`). The `action_key` (which defaults to the registration name, `"d"`) is what the infer system uses to look up the action (`delete_jump` has `keys = {"d"}`). This lets you bind `<leader>m` + `w` to delete-word, `<leader>m` + `j` to delete-line, and so on, while reusing the existing `delete_jump` action. Double-tap detection also uses `action_key`: pressing `<leader>m` then `d` triggers delete-line.

---

## Complex Action Composition

The `merge` utility combines multiple actions into a single sequential action. Import it from the core utils module.

### Jump and Yank

```lua
local merge = require("smart-motion.core.utils").action_utils.merge

require("smart-motion").register_motion("gy", {
  collector = "lines",
  extractor = "words",
  filter = "filter_words_after_cursor",
  visualizer = "hint_start",
  action = merge({ "jump", "yank" }),
  map = true,
  modes = { "n" },
  metadata = {
    label = "Jump and Yank Word",
  },
})
```

**How it works:** When you select a target, `merge` runs each action in order: first `jump` moves the cursor to the target, then `yank` yanks the word at the new position. Actions share the same `motion_state`, so the selected target is available to every action in the chain.

### Remote Yank (Yank Without Moving)

```lua
action = merge({ "yank", "restore" })
```

**How it works:** The `yank` action yanks text at the target, then `restore` returns the cursor to its original position. The result is a yank that does not move the cursor.

### Jump, Yank, and Center

```lua
action = merge({ "jump", "yank", "center" })
```

**How it works:** Three actions in sequence: jump to the target, yank the word, then center the screen on the new cursor position. You can chain as many actions as you need.

---

## Tips

1. **Use `:InspectTree` to find node types.** Open a buffer in the language you are targeting and run `:InspectTree`. This shows the full treesitter AST with every node type. Copy the exact type names into your `ts_node_types` list.

2. **Node types are cross-language.** Most recipes list node types from multiple languages (Lua, Python, JavaScript, Rust, Go, etc.). Types that do not exist in a particular language are safely ignored, so you can keep broad lists without errors.

3. **Test with a new key first.** When building a custom motion, bind it to an unused key like `<leader>x` so it does not interfere with existing motions. Move it to your preferred key once it works.

4. **Debug with logging.** If a motion is not producing the targets you expect, enable debug logging: `vim.g.smart_motion_log_level = "debug"`. This prints each pipeline stage's input and output so you can see where targets are being lost.

5. **Chain recipes from both guides.** The [Recipes guide](Recipes.md) covers filter swaps, extractor changes, and preset overrides. Everything there composes with the techniques in this guide. For example, you can take a treesitter motion from this page and make it bidirectional by applying a filter swap from the Recipes page.

---

## Next Steps

-> **[Recipes](Recipes.md)**: Pipeline basics, filter swaps, and preset overrides

-> **[Building Custom Motions](Building-Custom-Motions.md)**: Register your own pipeline stages from scratch

-> **[Pipeline Architecture](Pipeline-Architecture.md)**: Deep dive into how each pipeline stage works internally

-> **[API Reference](API-Reference.md)**: Complete reference for all registries, modules, and motion_state fields
