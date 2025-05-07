# Registering Motions and Presets

SmartMotion allows you to register new motions and actions using a flexible and powerful API. This file will walk you through:

- How motion registration works
- What options are available
- How to use `is_action`
- How to register multiple motions at once
- How presets work under the hood
- How module registries work and why they're powerful

---

## 🔧 Basic Motion Registration

To register a motion, use:

```lua
require("smart-motion").register_motion("w", {
  pipeline = {
    collector = "lines",
    extractor = "words",
    visualizer = "hint_start",
    filter = "default",
  },
  pipeline_wrapper = "default",
  action = "jump",
  map = true,
  modes = { "n", "v" },
  metadata = {
    label = "Jump to Start of Word after cursor",
    description = "Jumps to the start of a visible word target using labels after the cursor",
  },
})
```

> [!NOTE]
> Notice how no trigger_key is provided. Because of this the name, "w", is used as the trigger key. A name does not have to be a single key, it can even be: "hint_words_after_cursor", but then you would need to provide a trigger_key

---

## ⚙️ Motion Options

Each motion supports the following fields:

- `trigger_key`: the key that the motion is mapped to. If no trigger_key is provided the name is used.
- `pipeline`: defines the motion stages (collector, extractor, filter, visualizer)
- `pipeline_wrapper`: optional wrapper to control input/search behavior
- `action`: what to do when a target is selected (`jump`, `delete`, etc.)
- `map`: whether to create a keybinding for the motion
- `modes`: which modes the motion is active in (`n`, `v`, `x`, etc.)
- `metadata`: label and description for documentation/debugging

> [!TIP]
> Want to create a motion like `dw`? Use `merge({ jump, delete })` as the action.

---

## 🔁 `is_action` and Trigger Behavior

When registering a motion, the `is_action` flag controls how the dispatcher interprets the first keypress:

- If `is_action = false` (default), the motion key **is the motion**.
- If `is_action = true`, the key is treated as a **trigger for an action**, and the **next key** determines the motion to apply it to.

This is how SmartMotion mimics `dw`, `ct)`, etc. without you needing to define every combo.

```lua
-- `d` is registered as an action:
require("smart-motion").register_motion("d", {
  is_action = true,
  action = "delete",
})
```

```
dw   → delete to next word
dt)  → delete until `)`
```

> [!IMPORTANT]
> The trigger key looks up a registered action, and the second key maps to a registered motion (and from there, its extractor).

> [!NOTE]
> This only works when the second key has a valid registered motion. It's a powerful system, but future updates may improve the flexibility of this inference.

---

## 🧵 Registering Multiple Motions

You can register a group of motions at once:

```lua
require("smart-motion").register_many_motions({
  w = { ... },
  e = { ... },
  ge = { ... },
})
```

Used internally by presets, this is great for bundling a motion family.

---

## 🎯 How Presets Work

Presets call `register_many_motions()` internally.
Each preset (like `words`, `search`, or `yank`) includes default mappings you can override or exclude.

See [`presets.md`](./presets.md) for a full reference.

---

## 🗂 Module Registries

SmartMotion includes **registries** for every type of module:

- `collectors`
- `extractors`
- `filters`
- `visualizers`
- `actions`
- `wrappers`

Each registry supports:

- `register(name, module)` — add a module
- `get_by_name(name)` — look up a module by string
- `get_by_key(key)` — lookup by motion key (used for inference in `is_action` behavior)

This system is what powers:

- Mapping trigger keys (like `d`) to actions
- Mapping motion keys (like `w`) to extractors
- Letting users compose motions without duplicating logic

### 🔌 Plugin Interoperability

Because registries are shared globally:

- Any plugin can register a new extractor or action
- You can use that extractor in your own motion
- **Just installing a plugin gives you access to its modules**

This makes SmartMotion a **motion framework**, not just a plugin — the registry system ensures modularity, reuse, and integration.

---

## ➕ What’s Next?

Check out:

- [`custom_motion.md`](./custom_motion.md)
- [`actions.md`](./actions.md)
- [`pipeline_wrappers.md`](./pipeline_wrappers.md)
