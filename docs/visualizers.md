# Visualizers

Visualizers are the **fourth stage** of the SmartMotion pipeline. They are responsible for **rendering the targets to the user** — whether through hints, buffers, floating windows, or any custom UI.

> [!TIP]
> Visualizers decide **how your targets are displayed**. They are not limited to hint labels — they can open popups, buffer views, Telescope pickers, or more.

---

## ✅ What a Visualizer Does

A visualizer receives a list of targets and can:

- Assign and render in-place hint labels (default behavior)
- Open a floating window with selectable targets
- Populate Telescope with target results
- Display overlays, custom UI, or diagnostics views

The possibilities are completely open. Hints are just the default visual form.

---

## ✨ Dynamic Labeling (Hint Visualizer Example)

The built-in hint visualizer automatically decides whether to:

- Use 1-character or 2-character labels based on number of targets
- Brighten, dim, or fade label segments based on input

These hint labels are what most users start with, and they support advanced feedback states like flow transitions and partial input filtering.

---

## 📦 Built-in Visualizers

| Name         | Description                                    |
| ------------ | ---------------------------------------------- |
| `hint_start` | Applies hint labels to the start of the target |
| `hint_end`   | Applies hint labels to the end of the target   |

> [!NOTE]
> These are just two examples. You can build any kind of visualization system you want.

---

## 🧱 Example Usage

Defined in a pipeline:

```lua
pipeline = {
  collector = "lines",
  extractor = "words",
  visualizer = "hint_start",
}
```

With highlight overrides:

```lua
highlight = {
  hint = { fg = "#E06C75" },
  first_char = { fg = "#98C379" },
  second_char = { fg = "#61AFEF" },
  first_char_dim = { fg = "#6F8D57" },
}
```

---

## 🧠 Feedback Mechanics (Hints Only)

The default hint visualizers support dynamic feedback:

- Before any input: `first_char` is bright, `second_char` is dimmed
- After first character is pressed: `first_char` dims, `second_char` brightens

This makes chaining labels intuitive and clear.

> [!TIP]
> This feedback system is managed entirely by the visualizer.

---

## 🔧 Creating a Custom Visualizer

A visualizer implements a `run(ctx, cfg, motion_state)` method and can render the UI however you choose.

```lua
---@type SmartMotionVisualizerModule
local M = {}

function M.run(ctx, cfg, motion_state)
  local targets = motion_state.targets
  -- Show floating window, populate Telescope, assign labels, etc.
end

return M
```

Then register it:

```lua
require("smart-motion.core.registries")
  :get().visualizers.register("custom_visualizer", M)
```

---

## 🔮 Future Possibilities

Custom visualizers could:

- Populate Telescope pickers with motion targets
- Open side panels for jumping
- Show ghost overlays in virtual text
- Display diagnostic or LSP-aware UI
- Combine jump targets with semantic token overlays

> [!IMPORTANT]
> The visualizer system is intentionally unopinionated. You can use it to create entirely different interaction models.

---

Next:

- [`actions.md`](./actions.md)
