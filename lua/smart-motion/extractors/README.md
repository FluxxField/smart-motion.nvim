# Extractors - Finding Jump Targets

An extractor takes raw data from a collector and extracts jumpable targets from it.

## How It Works

1. It receives raw data from a collector (e.g., lines of text).
2. It finds words, function names, symbols, etc.
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

Finds words inside lines and turns them into jump targets.

---

## Example: `pass_through.lua` (Passing Collector Data Through)

```lua
function M.run(ctx, cfg, motion_state, data)
    return data
end
```

The `pass_through` extractor returns collector data unchanged. This is used when a collector already yields fully-formed targets (e.g., `treesitter` and `diagnostics` collectors).

---

## When to Use an Extractor?

| Use Case | Example Extractor |
| --- | --- |
| Extracting words from lines | `words` |
| Extracting whole lines | `lines` |
| 1-character search (f/F) | `text_search_1_char` |
| 1-character until search (t/T) | `text_search_1_char_until` |
| 2-character search | `text_search_2_char` |
| Live incremental search | `live_search` |
| Passing pre-formed targets through | `pass_through` |
