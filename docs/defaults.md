# Built-in Modules Reference

SmartMotion comes with a complete set of default modules — collectors, extractors, filters, visualizers, actions, wrappers, and presets — that give you powerful capabilities right out of the box.

---

## 📥 Collectors

### `lines`

- **Type:** Collector
- **Description:** Collects lines in the buffer forward or backward from the cursor.

---

## 🔍 Extractors

### `lines`

- Extracts whole lines as targets.

### `words`

- Extracts individual word targets using SmartMotion's internal word regex pattern.

### `text_search`

- Extracts matches for a search string (typically 1–2 characters).
- Used for `f`, `F`, `t`, `T`-style motions.

---

## 🧼 Filters

### `default`

- A no-op. Passes targets through without modification.

### `filter_visible_lines`

- Removes any target not within the current screen view.

---

## 👁 Visualizers

### `hint_start`

- Shows hint labels at the **start** of each target.

### `hint_end`

- Shows hint labels at the **end** of each target.

> [!NOTE]
> Visualizers can be used for much more than hinting — popups, floating windows, and Telescope integration are all possible.

---

## 🎬 Actions

| Name                       | Description                                             |
| -------------------------- | ------------------------------------------------------- |
| `jump`                     | Moves the cursor to the target                          |
| `delete`, `change`, `yank` | Performs the corresponding action from cursor to target |
| `*_jump`                   | First jumps to target, then runs the action             |
| `*_line`                   | Line-based versions of delete/yank/change               |
| `*_until`                  | Performs the action up to (not including) the target    |
| `remote_*`                 | Performs the action **without moving** the cursor       |
| `restore`                  | Restores the cursor to its original location            |

---

## 🧩 Pipeline Wrappers

| Name          | Description                                             |
| ------------- | ------------------------------------------------------- |
| `default`     | Runs the pipeline once without modification             |
| `text_search` | Prompts user for 1–2 characters before running pipeline |
| `live_search` | Re-runs the pipeline dynamically as user types input    |

---

## 📦 Presets

The following presets are available:

- `words`: Motions for `w`, `b`, `e`, `ge`
- `lines`: Motions for `j`, `k`
- `search`: Motions for `f`, `F`, `s`, `S`
- `delete`, `yank`, `change`: Actions plus motions like `dt)`, `yt)`, `ct)`

See [`presets.md`](./presets.md) for the full breakdown of mappings and behavior.

---

Next:

- [`custom_motion.md`](./custom_motion.md)
- [`visualizers.md`](./visualizers.md)
- [`actions.md`](./actions.md)
