# SmartMotion Preset Reference

This reference documents all the motions included in the default SmartMotion presets and explains how to customize them.

---

## Preset: `words`

| Key  | Mode    | Description                         |
| ---- | ------- | ----------------------------------- |
| `w`  | n, v, o | Jump to Start of Word after cursor  |
| `b`  | n, v, o | Jump to Start of Word before cursor |
| `e`  | n, v, o | Jump to End of Word after cursor    |
| `ge` | n, v, o | Jump to End of Word before cursor   |

---

## Preset: `lines`

| Key | Mode    | Description                |
| --- | ------- | -------------------------- |
| `j` | n, v, o | Jump to Line after cursor  |
| `k` | n, v, o | Jump to Line before cursor |

---

## Preset: `search`

| Key  | Mode | Multi-window | Description                                          |
| ---- | ---- | ------------ | ---------------------------------------------------- |
| `s`  | n, o | yes          | Live search across all visible text with labels      |
| `S`  | n, o | yes          | Fuzzy search — type partial patterns to match words  |
| `f`  | n, o | yes          | 2 Character Find After Cursor                        |
| `F`  | n, o | yes          | 2 Character Find Before Cursor                       |
| `t`  | n, o | yes          | Till Character After Cursor (jump to just before)    |
| `T`  | n, o | yes          | Till Character Before Cursor (jump to just after)    |
| `;`  | n, v | yes          | Repeat last f/F/t/T motion (same direction)          |
| `,`  | n, v | yes          | Repeat last f/F/t/T motion (reversed direction)      |
| `gs` | n    | yes          | Visual select via labels — pick two words, enter visual mode |

> [!NOTE]
> `s` uses literal matching, `S` uses fuzzy matching (FZY algorithm with scoring for word boundaries, camelCase, consecutive matches). Both support label conflict avoidance — labels can't be valid search continuations.

> [!NOTE]
> `;` and `,` use literal matching and show labels across all visible windows. `gs` uses dual selection (pick start, then end) and works across windows.

---

## Preset: `delete`

| Key   | Description                                |
| ----- | ------------------------------------------ |
| `d`   | Delete (acts like a motion + delete)       |
| `dt`  | Delete Until (1-char search after cursor)  |
| `dT`  | Delete Until (1-char search before cursor) |
| `rdw` | Remote Delete Word                         |
| `rdl` | Remote Delete Line                         |

---

## Preset: `yank`

| Key   | Description                              |
| ----- | ---------------------------------------- |
| `y`   | Yank (acts like a motion + yank)         |
| `yt`  | Yank Until (1-char search after cursor)  |
| `yT`  | Yank Until (1-char search before cursor) |
| `ryw` | Remote Yank Word                         |
| `ryl` | Remote Yank Line                         |

---

## Preset: `change`

| Key  | Description                                   |
| ---- | --------------------------------------------- |
| `c`  | Change (acts like a motion + delete + insert) |
| `ct` | Change Until (1-char search after cursor)     |
| `cT` | Change Until (1-char search before cursor)    |

---

## Preset: `paste`

| Key | Description                                    |
| --- | ---------------------------------------------- |
| `p` | Paste after target (select word/line to paste) |
| `P` | Paste before target                            |

---

## Preset: `treesitter`

### Navigation

| Key  | Mode | Multi-window | Description                                          |
| ---- | ---- | ------------ | ---------------------------------------------------- |
| `]]` | n, o | yes          | Jump to next function definition after cursor        |
| `[[` | n, o | yes          | Jump to previous function definition before cursor   |
| `]c` | n, o | yes          | Jump to next class/struct definition after cursor    |
| `[c` | n, o | yes          | Jump to previous class/struct definition before cursor |
| `]b` | n, o | yes          | Jump to next block/scope (if, for, while, try, etc.) |
| `[b` | n, o | yes          | Jump to previous block/scope                         |

### Editing

| Key   | Mode | Description                                     |
| ----- | ---- | ----------------------------------------------- |
| `daa` | n    | Delete around argument (includes separator)     |
| `caa` | n    | Change around argument                          |
| `yaa` | n    | Yank around argument                            |
| `dfn` | n    | Delete function name                            |
| `cfn` | n    | Change function name (rename)                   |
| `yfn` | n    | Yank function name                              |
| `saa` | n    | Swap two arguments — pick two with labels, swap positions |

### Selection

| Key  | Mode    | Description                                                   |
| ---- | ------- | ------------------------------------------------------------- |
| `gS` | n, x    | Treesitter incremental select — `;` to expand, `,` to shrink  |
| `R`  | n, x, o | Treesitter search — search text, select surrounding TS node   |

> [!NOTE]
> `gS` starts with the smallest named node at cursor, then use `;` to expand to parent nodes and `,` to shrink to child nodes. Shows node type in echo area. Press Enter to confirm, ESC to cancel.

> [!NOTE]
> `R` works in operator-pending mode: `dR` deletes the node containing search text, `yR` yanks it, `cR` changes it. In normal/visual mode, it enters visual selection on the node.

> [!NOTE]
> Treesitter presets use broad node type lists that work across many languages (Lua, Python, JavaScript, TypeScript, Rust, Go, C/C++, Java, Ruby). Non-matching types are safely ignored.

> [!NOTE]
> `saa` (swap) uses dual selection: press to see labels on all arguments, pick the first argument, labels re-render for the second pick, then both arguments swap positions. The later position is replaced first for buffer stability.

---

## Preset: `diagnostics`

| Key  | Mode | Multi-window | Description                                     |
| ---- | ---- | ------------ | ----------------------------------------------- |
| `]d` | n, o | yes          | Jump to next diagnostic after cursor            |
| `[d` | n, o | yes          | Jump to previous diagnostic before cursor       |
| `]e` | n, o | yes          | Jump to next error diagnostic after cursor      |
| `[e` | n, o | yes          | Jump to previous error diagnostic before cursor |

---

## Preset: `git`

| Key  | Mode | Multi-window | Description                                     |
| ---- | ---- | ------------ | ----------------------------------------------- |
| `]g` | n, o | yes          | Jump to next git hunk (changed region) after cursor  |
| `[g` | n, o | yes          | Jump to previous git hunk before cursor              |

> [!NOTE]
> Git hunk motions work best with [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) installed. SmartMotion uses gitsigns' API for accurate hunk detection. Without gitsigns, it falls back to parsing `git diff` output directly.

> [!NOTE]
> A "hunk" is a contiguous region of changed lines in git. This includes added lines, deleted lines, and modified lines. The metadata includes `hunk_type` ("add", "delete", or "change") for potential custom actions.

---

## Preset: `quickfix`

| Key  | Mode | Multi-window | Description                                     |
| ---- | ---- | ------------ | ----------------------------------------------- |
| `]q` | n, o | yes          | Jump to next quickfix entry after cursor        |
| `[q` | n, o | yes          | Jump to previous quickfix entry before cursor   |
| `]l` | n, o | yes          | Jump to next location list entry after cursor   |
| `[l` | n, o | yes          | Jump to previous location list entry before cursor |

> [!NOTE]
> Quickfix entries come from `:vimgrep`, `:make`, `:grep`, LSP diagnostics, and other sources. The location list (`]l`/`[l`) is window-local — each window can have its own list.

> [!NOTE]
> The collector includes metadata like `entry_type` (E/W/I/N/H for error/warning/info/note/hint), `filename`, `qf_idx` (position in list), and `entry_text` for potential custom filtering or actions.

---

## Preset: `marks`

| Key  | Mode | Multi-window | Description                                     |
| ---- | ---- | ------------ | ----------------------------------------------- |
| `g'` | n, o | yes          | Show labels on all marks, jump to selected one  |
| `gm` | n    | yes          | Set mark at labeled target (prompts for mark name) |

> [!NOTE]
> `g'` displays labels on all vim marks (a-z local, A-Z global). This is faster than typing `'a`, `'b`, etc. when you have many marks. Global marks (A-Z) from other visible buffers are also shown in multi-window mode.

> [!NOTE]
> `gm` shows labels on word targets. After selecting a target, type a mark name (a-z for buffer-local, A-Z for global). The mark is set at that location without moving your cursor — great for bookmarking a location you want to return to later.

---

## Preset: `misc`

| Key   | Description                                                        |
| ----- | ------------------------------------------------------------------ |
| `.`   | Repeat the previous motion                                         |
| `gmd` | Multi-cursor delete — toggle-select multiple words, Enter to delete |
| `gmy` | Multi-cursor yank — toggle-select multiple words, Enter to yank     |

> [!NOTE]
> `gmd` and `gmy` use multi-selection mode: labels appear on all visible words. Press a label key to toggle it on/off (selected targets highlight green). Press Enter to confirm, ESC to cancel. Targets are processed in reverse position order for safe sequential editing.

---

---

## Mode Reference

| Mode | Description |
| ---- | ----------- |
| `n`  | Normal mode |
| `v`  | Visual mode |
| `o`  | Operator-pending mode — works with any vim operator (`>`, `<`, `gU`, `gu`, `=`, `gq`, `!`, `zf`, etc.). Available for all jump motions including `t`/`T` and `]b`/`[b`. |

> [!NOTE]
> In operator-pending mode, SmartMotion performs a plain jump (no centering) so the operator receives the cursor movement correctly. Multi-window is disabled in operator-pending mode since vim operators expect movement within the same buffer.

## Multi-Window Support

Motions marked with **Multi-window: yes** collect targets from all visible (non-floating) windows in the current tabpage. Labels from the current window get priority — nearby targets get single-character labels. Selecting a label in another window switches to that window.

Word and line motions (`w`, `b`, `e`, `ge`, `j`, `k`) stay single-window because directional motions within one window are the natural UX.

---

# Configuring Presets

You can enable, disable, or customize presets during setup using the `presets` field.

Each preset supports three options:

| Option     | Behavior                                |
| ---------- | --------------------------------------- |
| `true`     | Enable all motions in the preset        |
| `false`    | Disable the entire preset               |
| `{}` table | Customize or exclude individual motions |

---

# Customizing Specific Motions

You can selectively **override** motion settings, **disable** individual motions, or **disable** an entire preset.

```lua
opts = {
  presets = {
    words = {
      -- Note: "w" and "b" are the motion names. If no trigger_key is provided. The name is used
      -- In all the presets, no trigger_key is provided so the name becomes the trigger key
      w = {
        map = false, -- Override: Do not automatically map 'w'
      },
      b = false, -- Disable the 'b' motion completely
    },
    lines = true, -- Enable all motions in 'lines'
    delete = false, -- Disable all motions in 'delete'
  },
}
```

### Behavior of this example:

- `words.w` is registered but won't be automatically mapped.
- `words.b` is **excluded**.
- `lines` preset is registered normally.
- `delete` preset is **disabled completely**.

---

# Why Would You Set `map = false`?

Setting `map = false` allows you to **register a motion without automatically mapping it** to the default key.

You might want this if:

- You want to **use a different keybinding** for the motion.
- You want to **map it manually later**.
- You want to **use a `trigger_key` override**.

For example, if you override a motion to have a different `trigger_key`, the original key mapping (`w`, `b`, etc.) might not make sense anymore. Setting `map = false` ensures the motion is **registered** and **available** but **not mapped** incorrectly.

Example:

```lua
presets = {
  words = {
    w = {
      map = false,
      trigger_key = "W", -- manually mapped to 'W' later
    },
  },
}
```

In this example:

- The motion logic is tied to `w` internally.
- It is mapped to `W` instead of `w` manually by you.

SmartMotion provides a helper util to map registered motions to their trigger_key later on if needed. All you need to do is provide the name the motion was registered to.

```lua
require("smart-motion").map_motion("w")
```

---

# Full Example

```lua
require("smart-motion").setup({
  presets = {
    words = {
      w = { map = false },
      b = false,
    },
    lines = true,
    search = {
      s = { map = false },
      S = { map = false },
    },
    delete = false,
    yank = true,
    change = false,
    paste = true,
    treesitter = true,
    diagnostics = true,
    misc = true,
  },
})
```

---

# Notes

- Motion overrides use `vim.tbl_deep_extend("force", default, user_override)` internally, so **you only need to provide the fields you want to change**.
- If you pass `false` to a motion key, it will **not register** that motion.
- If you pass `false` to a preset name, the **entire preset is skipped**.
- You can even add **brand new motions** inside a preset by providing a full motion config.

---

# 🌟 Enjoy your fully customized SmartMotions!
