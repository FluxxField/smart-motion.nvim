# Collectors - Gathering Raw Data

A collector is responsible for gathering raw data that might contain potential jump targets. It does not process or filter anything-it just retrieves lines, functions, diagnostics, etc. for further processing.

## How It Works

1. A collector fetches raw data from the buffer (or other sources).
2. It yields this data as a generator.
3. The extractor will process it later.

---

## Example: `lines.lua` (Collecting Lines from Buffer)

```lua
function collect_lines(ctx, cfg, motion_state)
    return coroutine.wrap(function()
        local lines = vim.api.nvim_buf_get_lines(ctx.bufnr, 0, -1, false)
        for lnum, text in ipairs(lines) do
            coroutine.yield({ lnum = lnum, text = text })
        end
    end)
end
```

✅ Gathers lines from the buffer but does NOT extract words or targets.

---

## Example: `treesitter_functions.lua` (Collecting Function Definitions)

```lua
function collect_treesitter_functions(ctx, cfg, motion_state)
    return coroutine.wrap(function()
        local ts = vim.treesitter
        local parser = ts.get_parser(ctx.bufnr, "lua")
        local tree = parser:parse()[1]
        local root = tree:root()

        for node in root:iter_children() do
            if ts.query.node_is_function(node) then
                coroutine.yield({
                    bufnr = ctx.bufnr,
                    lnum = ts.get_node_start(node),
                    text = vim.treesitter.get_node_text(node, ctx.bufnr),
                })
            end
        end
    end)
end
```

✅ Finds function definitions using Treesitter but does NOT turn them into jump targets.

---

## When to Use a Collector?

| Use Case | Example Collector |
| --- | --- |
| Getting buffer lines | `collect_lines` |
| Getting function definitions | `collect_treesitter_functions` |
| Getting LSP diagnostics | `collect_lsp_diagnostics` |
| Getting TODO comments | `collect_todo_comments` |
