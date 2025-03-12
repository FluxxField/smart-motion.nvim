# Actions – What Happens After Selecting a Target

An action defines what happens when you select a jump target.

##How It Works

1. The user selects a target.
2. The action decides what to do (jump, edit, open menu).
3. It executes the action.

---

## Example: `jump.lua` (Jump to Target)

```lua
function jump_to_target(target)
    vim.api.nvim_win_set_cursor(0, { target.lnum, target.col })
end
```

✅ Moves the cursor to the selected target.

---

## Example: `open_definition.lua` (LSP Go-To Definition)

```lua
function open_lsp_definition(target)
    vim.lsp.buf.definition()
end
```

✅ Jumps to the LSP definition of a selected function.

---

## When to Use an Action?

| Use Case |	Example Action |
| Jump to a target |	`jump_to_target` |
| Open LSP definition |	`open_lsp_definition` |
| Open Telescope for fuzzy finding |	`open_telescope_list` |
