# Collectors - Gathering Raw Data

A collector is responsible for gathering raw data that might contain potential jump targets. It does not process or filter anything-it just retrieves lines, functions, diagnostics, etc. for further processing.

## How It Works

1. A collector fetches raw data from the buffer (or other sources).
2. It yields this data as a generator (coroutine).
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

Gathers lines from the buffer but does NOT extract words or targets.

---

## Example: `treesitter.lua` (Collecting Treesitter Nodes)

The treesitter collector supports 4 modes controlled by `motion_state` fields:

**Mode 1: Raw query** (`ts_query`) — Language-specific treesitter query string.

**Mode 2: Child field** (`ts_node_types` + `ts_child_field`) — Yields a specific named field from matched nodes (e.g., function `"name"`).

**Mode 3: Yield children** (`ts_node_types` + `ts_yield_children`) — Yields each named child of container nodes (e.g., individual arguments). Use `ts_around_separator = true` to include commas.

**Mode 4: Node types** (`ts_node_types` alone) — Plain node type matching.

```lua
-- Example: collect function definitions (Mode 4)
metadata = {
    motion_state = {
        ts_node_types = {
            "function_declaration",
            "function_definition",
            "arrow_function",
            "method_definition",
        },
    },
}
```

---

## Example: `diagnostics.lua` (Collecting LSP Diagnostics)

```lua
-- Collects all diagnostics; severity filtering via motion_state.diagnostic_severity
metadata = {
    motion_state = {
        diagnostic_severity = vim.diagnostic.severity.ERROR, -- optional
    },
}
```

Collects `vim.diagnostic.get()` results as targets with position, message, severity, and source metadata.

---

## When to Use a Collector?

| Use Case | Example Collector |
| --- | --- |
| Getting buffer lines | `lines` |
| Getting treesitter nodes (functions, classes, arguments) | `treesitter` |
| Getting LSP diagnostics | `diagnostics` |
| Getting jump history entries | `history` |
