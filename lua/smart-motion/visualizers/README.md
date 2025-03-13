# Visualizers – Displaying Jump Hints

A visualizer takes jump targets and displays hints for them.
The goal is to make targets discoverable.

## How It Works

1. It receives structured jump targets.
2. It renders hints, either as inline text, floating windows, or telescope lists.
3. It passes the selected target to the action.

---

## Example: `inline_hints.lua` (Rendering Virtual Text Hints)

```lua
function visualize_inline_hints(targets)
    for i, target in ipairs(targets) do
        vim.api.nvim_buf_set_extmark(target.bufnr, ns_id, target.lnum - 1, target.col, {
            virt_text = { { i, "WarningMsg" } },
            hl_mode = "combine",
        })
    end
end
```

✅ Displays inline hints for jump targets using virtual text.

---

## Example: `telescope_picker.lua` (Rendering Targets in a Floating List)

```lua

function visualize_telescope_picker(targets)
    local entries = {}
    for _, target in ipairs(targets) do
        table.insert(entries, { target.text, target.lnum, target.col })
    end

    require("telescope.pickers").new({}, {
        prompt_title = "Jump Targets",
        finder = require("telescope.finders").new_table({
            results = entries,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry[1] .. " (line " .. entry[2] .. ")",
                    ordinal = entry[1],
                }
            end,
        }),
        sorter = require("telescope.config").values.generic_sorter(),
    }):find()
end
```

✅ Displays targets in a Telescope list instead of inline hints.

---

## When to Use a Visualizer?

| Use Case |	Example Visualizer |
| --- | --- |
| Inline hints over words |	inline_hints | 
| Floating window list |	floating_list |
| Telescope fuzzy finder |	telescope_picker |
