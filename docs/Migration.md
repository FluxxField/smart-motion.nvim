# Migration Guide

Coming from another motion plugin? This guide maps familiar keybindings to their SmartMotion equivalents and highlights what's new.

---

## From flash.nvim

### Keybinding Map

| flash.nvim | SmartMotion | Notes |
|------------|-------------|-------|
| `s` (search) | `s` (live search) | Same key, same concept. SmartMotion adds label conflict avoidance. |
| `S` (treesitter search) | `R` (treesitter search) | SmartMotion uses two-phase selection: pick match, then pick scope. |
| `r` (remote) | `rdw`, `rdl`, `ryw`, `ryl` | SmartMotion has explicit remote operations for word/line delete/yank. |
| `f`/`F` | `f`/`F` | SmartMotion uses 2-char find (like leap) instead of 1-char. |
| `t`/`T` | `t`/`T` | SmartMotion uses 2-char till instead of 1-char. |
| `/` search labels | `/` search labels | Same. Toggle with `<C-s>` during search. |

### What's Different

**Operators.** Flash has partial operator support. SmartMotion infers the full matrix automatically. Enable `words`, `delete`, `yank`, `change`, and you get `dw`, `db`, `de`, `dge`, `yw`, `yb`, `cw`, `cb`, etc. without any explicit mappings.

**f/F/t/T.** Flash keeps these as native 1-character motions with labels. SmartMotion changes them to 2-character searches (like leap). This gives more precise targeting but requires an extra character. If you want 1-char f/F behavior, keep flash's f/F and disable SmartMotion's:

```lua
presets = {
  search = {
    f = false,
    F = false,
    t = false,
    T = false,
  },
}
```

**Treesitter search.** Flash labels all ancestor nodes of all matches at once. SmartMotion uses two phases: first pick which match, then pick the scope. With many matches, SmartMotion's approach avoids flooding the screen with labels. With few matches, Flash's single step can be faster.

**Text objects.** Flash doesn't have pipeline-based text objects. SmartMotion's `af`, `if`, `ac`, `ic`, `aa`, `ia` work with any vim operator (`daf`, `gqaf`, `=if`, `>ac`) and show labels so you can pick which function/class/argument to act on.

### Recommended Config for Flash Users

```lua
presets = {
  words = true,
  lines = true,
  search = true,
  delete = true,
  yank = true,
  change = true,
  paste = true,
  treesitter = true,
  diagnostics = true,
  misc = true,
}
```

This gives you everything flash offered plus composable operators, text objects, flow state, history, and pins.

---

## From leap.nvim

### Keybinding Map

| leap.nvim | SmartMotion | Notes |
|-----------|-------------|-------|
| `s` (2-char search forward) | `s` (live search) | SmartMotion's `s` is incremental: labels update as you type, not after 2 chars. |
| `S` (2-char search backward) | `s` handles both directions | SmartMotion shows matches in all directions. Use `S` for fuzzy search instead. |
| `gs` (cross-window) | `s` with multi-window | SmartMotion's search is multi-window by default. `gs` is visual range select. |
| `x`/`X` (operator-pending) | `ds`, `ys`, `cs` | SmartMotion uses operator + motion composition. |

### What's Different

**Search model.** Leap waits for exactly 2 characters, then shows labels. SmartMotion's `s` shows labels incrementally as you type. You can type 1, 2, 3, or more characters. Labels narrow down with each keystroke. Both approaches work. Leap is more predictable (always 2 chars). SmartMotion is more flexible.

**2-char search is still available.** SmartMotion's `f`/`F` work as 2-character find (forward/backward), similar to leap's `s`/`S` but line-constrained by default. To make them multi-line:

```lua
presets = {
  search = {
    f = { filter = "filter_words_after_cursor" },
    F = { filter = "filter_words_before_cursor" },
  },
}
```

**Operators.** Leap has `x`/`X` in operator-pending mode. SmartMotion infers operators automatically. `dw`, `ds`, `df`, `dj` all work from enabling `delete = true`. No separate operator-pending keys needed.

**Everything else is new.** Treesitter text objects, flow state, history/pins, fuzzy search, argument swap, incremental select, multi-cursor. These don't have leap equivalents.

### Recommended Config for Leap Users

```lua
presets = {
  words = true,
  lines = true,
  search = true,
  delete = true,
  yank = true,
  change = true,
  treesitter = true,
  misc = true,
}
```

---

## From hop.nvim

### Keybinding Map

| hop.nvim | SmartMotion | Notes |
|----------|-------------|-------|
| `HopWord` | `w` (forward), `b` (backward) | SmartMotion splits by direction. |
| `HopLine` | `j` (down), `k` (up) | SmartMotion splits by direction. |
| `HopChar1` | `f`/`F` | SmartMotion uses 2-char find instead of 1-char. |
| `HopChar2` | `f`/`F` | Same concept, 2-char forward/backward find. |
| `HopPattern` | `s` | SmartMotion's live search with incremental labels. |
| `HopAnywhere` | `s` with multi-window | `s` searches across all visible windows by default. |

### What's Different

**Direction.** Hop shows labels in all directions for word/line jumping. SmartMotion uses separate keys: `w`/`e` forward, `b`/`ge` backward, `j` down, `k` up. This matches native vim semantics and means fewer labels to scan.

**Everything is opt-in.** Hop overrides specific keys. SmartMotion uses a preset system. Enable `words = true` and you get `w`, `b`, `e`, `ge`. Don't want `e` overridden? `words = { e = false }`.

**Operators.** Hop doesn't have composable operators. SmartMotion gives you `dw`, `yw`, `cw`, `ds`, `df`, and 50+ more compositions from a handful of preset toggles.

**The rest is new.** Treesitter, text objects, flow state, fuzzy search, history/pins, multi-cursor. None of these exist in hop.

### Recommended Config for Hop Users

```lua
presets = {
  words = true,
  lines = true,
  search = true,
  treesitter = true,
  diagnostics = true,
  misc = true,
}
```

Start without operators (`delete`, `yank`, `change`) if you want to ease in. Add them when you're comfortable.

---

## From mini.jump / mini.jump2d

### Keybinding Map

| mini.jump | SmartMotion | Notes |
|-----------|-------------|-------|
| `f`/`F`/`t`/`T` (enhanced) | `f`/`F`/`t`/`T` | SmartMotion uses 2-char versions with labels. |
| `MiniJump2d.start()` | `w`, `s`, `]]`, etc. | SmartMotion has purpose-built motions instead of one generic entry point. |

### What's Different

**Scope.** mini.jump enhances native f/F/t/T. mini.jump2d adds label jumping. SmartMotion replaces both and adds treesitter, operators, text objects, history, and more.

**Ecosystem.** If you use mini.ai for text objects, SmartMotion's `af`/`if`/`ac`/`ic`/`aa`/`ia` can replace it. If you use mini.surround, that's orthogonal and works fine alongside SmartMotion.

### Recommended Config for mini.jump Users

```lua
presets = {
  words = true,
  lines = true,
  search = true,
  treesitter = true,
  misc = true,
}
```

---

## General Tips

### Start Small

You don't have to enable everything at once. A good starting point:

```lua
presets = {
  search = true,       -- s, S, f, F, t, T
  treesitter = true,   -- ]], [[, af, if, etc.
}
```

Add more presets as you get comfortable.

### Keep Native Keys You Like

Disable specific keys within a preset:

```lua
presets = {
  words = {
    e = false,   -- keep native e
    ge = false,  -- keep native ge
  },
  search = {
    s = false,   -- keep native s (substitute)
  },
}
```

### Operator Composition

The biggest mental shift: you don't map `dw` explicitly. You enable `delete = true` and `words = true`, and `dw` works. Same for `yw`, `cw`, `dj`, `ds`, `df`, and every other combination. The inference system handles it.

Unknown keys fall through to native vim. `d$`, `d0`, `dG`, `daw` all still work.

### Flow State

After any motion, press another motion key within 300ms for instant movement without labels. This is the killer feature for navigating code quickly. It replaces repeated `w w w w` with a smooth flow.

---

## Next Steps

-> **[Quick Start](Quick-Start.md)**: Installation and first use

-> **[Presets Guide](Presets.md)**: Full keybinding reference

-> **[Advanced Features](Advanced-Features.md)**: Flow state, multi-window, operator-pending mode
