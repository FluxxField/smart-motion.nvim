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
