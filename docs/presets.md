# SmartMotion Preset Reference

This reference documents all the motions included in the default SmartMotion presets and explains how to customize them.

---

## Preset: `words`

| Key  | Description                         |
| ---- | ----------------------------------- |
| `w`  | Jump to Start of Word after cursor  |
| `b`  | Jump to Start of Word before cursor |
| `e`  | Jump to End of Word after cursor    |
| `ge` | Jump to End of Word before cursor   |

---

## Preset: `lines`

| Key | Description                |
| --- | -------------------------- |
| `j` | Jump to Line after cursor  |
| `k` | Jump to Line before cursor |

---

## Preset: `search`

| Key | Description                    |
| --- | ------------------------------ |
| `s` | Live Search Jump After Cursor  |
| `S` | Live Search Jump Before Cursor |
| `f` | 2 Character Find After Cursor  |
| `F` | 2 Character Find Before Cursor |

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

## Preset: `misc`

| Key | Description                |
| --- | -------------------------- |
| `.` | Repeat the previous motion |

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
