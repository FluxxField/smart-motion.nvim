# Actions - What Happens After Selecting a Target

An action defines what happens when you select a jump target.

## How It Works

1. The user selects a target.
2. The action decides what to do (jump, edit, paste, etc.).
3. It executes the action.

---

## Example: `jump.lua` (Jump to Target)

```lua
function jump_to_target(target)
    vim.api.nvim_win_set_cursor(0, { target.lnum, target.col })
end
```

Moves the cursor to the selected target.

---

## Example: `paste.lua` (Paste at Target)

```lua
function M.run(ctx, cfg, motion_state)
    local target = motion_state.selected_jump_target
    local row = target.end_pos.row
    local col = target.end_pos.col
    local paste_mode = motion_state.paste_mode or "after"

    vim.api.nvim_win_set_cursor(0, { row + 1, col })
    vim.cmd("normal! " .. (paste_mode == "before" and "P" or "p"))
end
```

Pastes text at the target position. The `paste_mode` field in `motion_state` controls whether to paste before or after.

---

## Range-Based Actions

The `delete`, `yank`, and `change` actions use `resolve_range()` from `actions/utils.lua`:

- Default: operates on the target itself (`start_pos` to `end_pos`)
- With `exclude_target = true`: operates from cursor to target ("until" mode)

This means `delete` and `delete_until` share the same module — behavior is controlled by `motion_state.exclude_target`.

---

## Action Variants

Actions follow a naming pattern:

| Pattern | What it does | Example Use |
| --- | --- | --- |
| `delete`, `yank`, `change` | Operate on target text, no cursor movement | Explicit presets (`dt`) |
| `delete_jump`, `yank_jump`, `change_jump` | Jump to target first, then operate | Composable operators (`dw`, `yw`, `cj`) |
| `remote_delete`, `remote_yank` | Jump, operate, restore cursor | Remote presets (`rdw`, `ryw`) |
| `*_line` | Line-wise variant | Double-tap (`dd`, `yy`, `cc`) |

The `*_jump` variants have `keys` registered in the action registry (e.g., `delete_jump` has `keys = { "d" }`). This is how the infer system resolves the correct action when composable operators look up their action by key.

## When to Use an Action?

| Use Case | Example Action |
| --- | --- |
| Jump to a target | `jump`, `jump_centered` |
| Jump and delete/yank/change | `delete_jump`, `yank_jump`, `change_jump` |
| Delete/yank/change without moving | `delete`, `yank`, `change` |
| Paste at a target | `paste_jump`, `paste_line` |
| Remote operations | `remote_delete`, `remote_yank` |
| Repeat a motion | `run_motion` |
