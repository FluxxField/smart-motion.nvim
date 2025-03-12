# Extractors - Finding Jump Targets

An extractor takes raw data from a collector and extracts jumpable targets from it.

## How It Works

1. It receives raw data from a collector (e.g., lines of text).
2. It finds words, function names, symbols, etc..
3. It yields structured jump targets.

---

## Example: `words.lua` (Extracting Words from Lines)

```lua
function extract_words(ctx, line_data)
    return coroutine.wrap(function()
        local lnum, text = line_data.lnum, line_data.text
        for start_pos, word in text:gmatch("()(%w+)") do
            coroutine.yield({
                bufnr = ctx.bufnr,
                lnum = lnum,
                col = start_pos - 1,
                text = word,
            })
        end
    end)
end
```

✅ Finds words inside lines and turns them into jump targets.

---

## Example: `diagnostics.lua` (Extracting Errors from LSP Diagnostics)

```lua
function extract_diagnostics(ctx, diagnostics)
    return coroutine.wrap(function()
        for _, diag in ipairs(diagnostics) do
            coroutine.yield({
                bufnr = ctx.bufnr,
                lnum = diag.lnum,
                col = diag.col,
                text = diag.message,
                type = "error",
            })
        end
    end)
end
```

✅ Finds error locations from LSP and turns them into jump targets.

---

## When to Use an Extractor?

| Use Case |	Example Extractor |
| Extracting words from lines |	`extract_words` |
| Extracting function names from Treesitter |	`extract_function_names` |
| Extracting LSP diagnostics |	`extract_diagnostics` |
