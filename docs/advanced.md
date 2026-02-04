# Advanced Usage

This section explores advanced SmartMotion concepts, best practices, and techniques for building custom motion ecosystems.

---

## 🚀 Flow State Behavior

Flow state allows users to **chain motions rapidly** without showing hints every time.

### How It Works

- When you trigger a motion (like `w`) and select a target fast enough, SmartMotion enters flow.
- If you press another valid motion key (like `w`, `b`, etc.) within a short time (e.g., 300ms), the motion skips hinting and jumps to the next target.
- This creates a seamless, native-like experience.

### Why It Matters

- Feels like traditional Vim navigation.
- Dramatically improves speed and usability when repeating motions.

> [!NOTE] > `flow_timeout` will be configurable in the future and accessible via `cfg`.

---

## ⚙️ Operator-Pending Mode

SmartMotion jump motions register in operator-pending mode (`"o"`), making them work with any native vim operator:

```
>w    — indent from cursor to labeled word
gUw   — uppercase from cursor to labeled word
=j    — auto-indent from cursor to labeled line
gq]]  — format from cursor to labeled function
```

### How It Works

1. `ctx.mode` is captured via `vim.fn.mode(true)` when the motion starts. In operator-pending mode this returns `"no"`.
2. When `ctx.mode` contains `"o"`, the pipeline forces a plain jump action (no centering via `zz`), since centering would disrupt the operator.
3. Multi-window collection is disabled in operator-pending mode — vim operators expect cursor movement within the same buffer.

### Which motions support it?

All jump-only motions: `w`, `b`, `e`, `ge`, `j`, `k`, `s`, `f`, `F`, `t`, `T`, `]]`, `[[`, `]c`, `[c`, `]b`, `[b`, `]d`, `[d`, `]e`, `[e`.

SmartMotion's own operators (`d`, `y`, `c`, `p`, `P`) and composites (`dt`, `yt`, `ct`, `daa`, `cfn`, etc.) are **not** registered in `"o"` mode — they handle operations internally via the inference system.

---

## 🪟 Multi-Window Jumping

Search, treesitter navigation, and diagnostic motions collect targets from all visible (non-floating) windows in the current tabpage.

### How It Works

1. When `motion_state.multi_window` is true and multiple windows are visible, the pipeline wraps the collector to iterate all windows.
2. For each window, a fresh collector coroutine runs with a per-window sub-context. Each yielded item gets `metadata.bufnr` and `metadata.winid` injected.
3. The current window is listed first in `ctx.windows`, so its targets get label priority — nearby targets get single-character labels.
4. Directional filters pass through all cross-window targets. Visibility filters use each target's own `winid`.
5. Highlight extmarks are placed in each target's buffer. `motion_state.affected_buffers` tracks all touched buffers for cleanup.
6. The jump action calls `nvim_set_current_win()` to switch windows instead of `nvim_set_current_buf()`.

### Custom motions with multi-window

Add `multi_window = true` to your motion's `metadata.motion_state`:

```lua
sm.motions.register("my_search", {
  collector = "lines",
  extractor = "live_search",
  filter = "filter_words_after_cursor",
  visualizer = "hint_start",
  action = "jump_centered",
  map = true,
  modes = { "n" },
  metadata = {
    motion_state = {
      multi_window = true,
    },
  },
  trigger = "<leader>s",
})
```

---

## 🎯 Till Motions & Char Repeat

### t/T — Till Character

`t` and `T` are single-character "till" motions. They prompt for one character, then label all matches — but the jump lands just **before** (for `t`) or just **after** (for `T`) the matched character rather than on it.

- `t` → forward: cursor lands at `col - 1` of the match
- `T` → backward: cursor lands at `col + 1` of the match

Both work in normal and operator-pending mode. In operator-pending mode, `dt` deletes from cursor to just before the character — matching native vim behavior.

### ;/, — Repeat Last Char Motion

After any `f`/`F`/`t`/`T` motion, the last search state (text, direction, exclude_target) is saved. Press `;` to repeat in the same direction, `,` to repeat in the reversed direction.

Both `;` and `,` show labels across all visible windows for selection — they don't just jump to the next match like native vim. This gives you full control over which match to jump to.

---

## 🔎 Native Search Labels

When `native_search` is enabled (default), SmartMotion enhances vim's built-in `/` search:

1. Press `/` and start typing — incremental match highlights appear in real-time
2. Press Enter to close the search prompt
3. Labels appear on all visible matches — pick one to jump there instantly
4. Press `<C-s>` during search to toggle the label overlay on/off

This is disabled in operator-pending mode (since operators need native search behavior). Configure via:

```lua
opts = {
  native_search = true,  -- default: enabled
}
```

---

## 🌳 Scope-Aware Motions

`]b` and `[b` jump to block/scope boundaries — control flow, loops, exception handling, and closures:

- **Control flow**: `if`, `switch`, `match`, `case`, `else`, `elif`
- **Loops**: `for`, `while`, `do`, `repeat`, `loop`
- **Exception handling**: `try`, `catch`, `except`, `finally`
- **Blocks/closures**: `block`, `lambda`, `closure`, `with`, `do_block`

These work across all languages with treesitter support. Labels appear in all visible windows. Available in both normal and operator-pending mode.

---

## 👁️ Visual Range Selection

`gs` lets you pick two word targets and enters visual mode spanning the range:

1. Press `gs` — labels appear on all visible words (across windows)
2. Pick the first target — it highlights while labels re-render for the second pick
3. Pick the second target — visual mode activates from the first to the second position

If the two targets are in different order, they're automatically sorted so the selection goes from earlier to later. If the first target is in a different window, the cursor switches to that window.

---

## 🔄 Argument Swap

`saa` picks two treesitter arguments and swaps their text:

1. Press `saa` — labels appear on all function/method arguments in the current buffer
2. Pick the first argument — it highlights while labels re-render
3. Pick the second argument — both arguments swap positions

The swap replaces the later position first to avoid offset corruption. Works with any language that has treesitter support for argument/parameter lists.

---

## ✏️ Multi-Cursor Edit

`gmd` (delete) and `gmy` (yank) provide toggle-based multi-selection:

1. Press `gmd` or `gmy` — labels appear on all visible words
2. Press label keys to **toggle** targets on/off — selected targets turn green (`SmartMotionSelected`)
3. Press **Enter** to confirm, **ESC** to cancel
4. Action executes on all selected targets:
   - `gmd`: deletes each selected word (processed bottom-to-top for position stability)
   - `gmy`: yanks all selected words into the `"` register (newline-separated, in document order)

Double-character labels work too — press the first character, then the second to toggle that target.

---

## 🔂 Action Composition

Instead of writing new actions for every combination (like `dw`, `ct)`), SmartMotion supports **action merging**:

```lua
action = merge({ "jump", "delete" })
```

This behaves like a normal motion + operator combo.

You can even register pre-combined actions like `delete_jump` or `change_jump` if needed.

---

## 🪝 Module Interoperability

SmartMotion’s **registry system** means any plugin or config can contribute:

- Custom extractors
- New actions
- Visualizers that open Telescope, float windows, etc.

These are globally available. If a plugin registers `telescope_visualizer`, you can use it in your pipeline with:

```lua
visualizer = "telescope_visualizer"
```

---

## 🔁 Manual Target Injection

You can dynamically build and assign targets to `motion_state.targets` and skip the pipeline entirely.
This is useful for:

- Manual label systems
- Search results
- LSP symbol queries

---

## Highlight Customization

SmartMotion allows full control over highlight groups. You can change foreground colors, add backgrounds, or even point to existing highlight groups in your colorscheme.

### Available Groups

| Key               | Default Group            | Description                          |
| ----------------- | ------------------------ | ------------------------------------ |
| `hint`            | SmartMotionHint          | Standard hint label                  |
| `hint_dim`        | SmartMotionHintDim       | Dimmed hint label                    |
| `first_char`      | SmartMotionFirstChar     | Brighter first label character       |
| `first_char_dim`  | SmartMotionFirstCharDim  | Dimmed first label character         |
| `second_char`     | SmartMotionSecondChar    | Brighter second label character      |
| `second_char_dim` | SmartMotionSecondCharDim | Dimmed second label character        |
| `dim`             | SmartMotionDim           | Background dim when not in selection |
| `selected`        | SmartMotionSelected      | Multi-cursor selected target (green) |

### Setting Custom Highlights

You can pass a `highlight` table in your config:

```lua
require("smart-motion").setup({
  highlight = {
    hint = { fg = "#FFD700", bg = "#222222", bold = true },
    first_char = "Type", -- use an existing highlight group
    dim = "Comment",
  },
})
```

SmartMotion supports both:

- **Tables** with `fg`, `bg`, `bold`, `italic`, `underline`.
- **Strings** referring to existing highlight groups.

If a string group is invalid, it will fall back to the default.

### Reacts to ColorScheme

If your colorscheme changes, SmartMotion will reapply your highlights automatically to ensure consistency.

---

## 🧪 Custom Wrapper Flows

Want a 3-character search? Want to ask the user twice? Want a modal search interface?
Wrappers give you complete control over how and when `run_pipeline()` is invoked.

---

## 🧰 Debug Tips

- Use `log.debug(...)` inside any module to output motion data
- Temporarily swap in the `default` visualizer to simplify feedback
- Set highlights to high-contrast colors to ensure visualizer output is visible

---

Next:

- [`config.md`](./config.md)
- [`custom_motion.md`](./custom_motion.md)
