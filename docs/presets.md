# SmartMotion Preset Reference

This reference documents all the motions included in the default SmartMotion presets.

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

You can enable or exclude any of these using the `presets` config table.

```lua
opts = {
  presets = {
    words = true, -- enable all
    lines = { "j" }, -- enable all except "j"
    delete = false, -- disable entirely
  },
}
```
