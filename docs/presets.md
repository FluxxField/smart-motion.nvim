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

| Key | Mode | Multi-window | Description                                     |
| --- | ---- | ------------ | ----------------------------------------------- |
| `s` | n, o | yes          | Live search across all visible text with labels |
| `f` | n, o | yes          | 2 Character Find After Cursor                   |
| `F` | n, o | yes          | 2 Character Find Before Cursor                  |

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

### Editing

| Key   | Mode | Description                                     |
| ----- | ---- | ----------------------------------------------- |
| `daa` | n    | Delete around argument (includes separator)     |
| `caa` | n    | Change around argument                          |
| `yaa` | n    | Yank around argument                            |
| `dfn` | n    | Delete function name                            |
| `cfn` | n    | Change function name (rename)                   |
| `yfn` | n    | Yank function name                              |

> [!NOTE]
> Treesitter presets use broad node type lists that work across many languages (Lua, Python, JavaScript, TypeScript, Rust, Go, C/C++, Java, Ruby). Non-matching types are safely ignored.

---

## Preset: `diagnostics`

| Key  | Mode | Multi-window | Description                                     |
| ---- | ---- | ------------ | ----------------------------------------------- |
| `]d` | n, o | yes          | Jump to next diagnostic after cursor            |
| `[d` | n, o | yes          | Jump to previous diagnostic before cursor       |
| `]e` | n, o | yes          | Jump to next error diagnostic after cursor      |
| `[e` | n, o | yes          | Jump to previous error diagnostic before cursor |

---

## Preset: `misc`

| Key | Description                |
| --- | -------------------------- |
| `.` | Repeat the previous motion |

---

---

## Mode Reference

| Mode | Description |
| ---- | ----------- |
| `n`  | Normal mode |
| `v`  | Visual mode |
| `o`  | Operator-pending mode — works with any vim operator (`>`, `<`, `gU`, `gu`, `=`, `gq`, `!`, `zf`, etc.) |

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
