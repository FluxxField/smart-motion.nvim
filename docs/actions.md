# Actions

Actions are the **final stage** of a SmartMotion pipeline. Once a user selects a target, the action defines **what happens** — like jumping, deleting, yanking, changing, or anything else you want.

> [!TIP]
> If extractors define _what_, filters define _which_, and visualizers show _how_ — actions define _why_. They are the result.

---

## ✅ What an Action Does

An action receives the final selected target and executes logic. This might be:

- Jumping the cursor to the target
- Deleting from the current cursor to the target
- Yanking or changing text
- Opening a floating window or performing diagnostics

Actions are **completely open-ended**. You control the behavior.

---

## 📦 Built-in Actions

| Name                 | Description                                                               |
| -------------------- | ------------------------------------------------------------------------- |
| `jump`               | Moves cursor to the target's position                                     |
| `jump_centered`      | Jumps to the target and centers the screen (`zz`)                         |
| `center`             | Centers the screen on the cursor                                          |
| `delete`             | Deletes the target text (uses `resolve_range`)                            |
| `delete_jump`        | Jumps to the target and deletes from there                                |
| `delete_until`       | Deletes up to (but not including) the target                              |
| `delete_line`        | Deletes the entire line at the target                                     |
| `yank`               | Yanks the target text (uses `resolve_range`)                              |
| `yank_jump`          | Jumps to the target and yanks from there                                  |
| `yank_until`         | Yanks up to (but not including) the target                                |
| `yank_line`          | Yanks the entire line at the target                                       |
| `change`             | Changes the target text and enters insert mode                            |
| `change_jump`        | Jumps to the target and starts a change                                   |
| `change_until`       | Changes up to (but not including) the target                              |
| `change_line`        | Changes the entire line at the target                                     |
| `paste`              | Pastes text at the target position                                        |
| `paste_jump`         | Jumps to the target and pastes                                            |
| `paste_line`         | Pastes the entire line at the target                                      |
| `remote_delete`      | Deletes the target without moving the cursor                              |
| `remote_delete_line` | Deletes the line at the target without moving the cursor                  |
| `remote_yank`        | Yanks the target without moving the cursor                                |
| `remote_yank_line`   | Yanks the line at the target without moving the cursor                    |
| `restore`            | Restores the cursor to its original location (used in remote actions)     |
| `run_motion`         | Re-runs a motion from history (used by `.` repeat)                        |

### Range-Based Actions

The `delete`, `yank`, and `change` actions use a shared `resolve_range()` helper from `actions/utils.lua` to determine their operation range:

- **When `exclude_target` is false** (default): operates on the target itself (`start_pos` to `end_pos`)
- **When `exclude_target` is true** ("until" mode): operates from the cursor to the target position

This means `delete` and `delete_until` share the same underlying action module — the behavior is controlled by whether `motion_state.exclude_target` is set (which is done by the `text_search_1_char_until` extractor).

---

## 🔀 Action Merging

SmartMotion includes a utility to **merge multiple actions** into a single one. This is how motions like `dw` are possible:

```lua
local merge = require("smart-motion.core.utils").action_utils.merge

local motion = {
  action = merge({ "jump", "delete" })
}
```

This will:

1. Move the cursor to the target (`jump`)
2. Then apply `delete` from the new position

You can merge any number of built-in or custom actions — they’ll execute in order.

> [!IMPORTANT]
> This is key for supporting native-feeling motions like `dw`, `ct)`, etc.

---

## ✨ Example: Jump Action

```lua
---@type SmartMotionActionModule
local M = {}

function M.run(ctx, cfg, motion_state)
  local jump_target = motion_state.selected_jump_target

  if type(jump_target) ~= "table" or not jump_target.row or not jump_target.col then
    return
  end

  -- Switch to the target's window (handles multi-window jumping)
  local winid = jump_target.metadata.winid
  local current_winid = vim.api.nvim_get_current_win()
  if winid and winid ~= current_winid then
    vim.api.nvim_set_current_win(winid)
  end

  local pos = { jump_target.row + 1, jump_target.col }
  local success, err = pcall(vim.api.nvim_win_set_cursor, winid or 0, pos)

  if not success then
    -- Log an error
  end
end

return M
```

Register it:

```lua
require("smart-motion.core.registries")
  :get().actions.register("my_jump", M)
```

---

## 🛠 Custom Actions Ideas

- Open diagnostics at the target location
- Refactor symbol under the cursor
- Copy to system clipboard
- Log to a side panel
- Center screen on target + reveal extra context

---

## 🔮 Future Possibilities

- Undo checkpoints before composite actions
- Named action chains with conditions
- Visual feedback preview on hover (via visualizer/action hybrid)

---

Next:

- [`pipeline_wrappers.md`](./pipeline_wrappers.md)
