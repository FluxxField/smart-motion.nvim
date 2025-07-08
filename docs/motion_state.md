# `motion_state`: Full Reference

The `motion_state` table tracks the full state of a motion during execution. It is passed to all pipeline modules (collectors, extractors, filters, etc.) and evolves over time as new stages are processed. You can provide your own values when creating a motion or rely on SmartMotion’s defaults.

This page lists _all known properties_ of `motion_state`, including _required fields_, _optional fields_, and _motion-specific extensions_.

---

## 🔧 Core Motion Settings

| Field           | Type           | Description                                                                          |
| --------------- | -------------- | ------------------------------------------------------------------------------------ |
| `total_keys`    | `integer`      | Total number of hintable keys (usually 26 or 52 depending on upper/lowercase usage). |
| `max_lines`     | `integer`      | Maximum number of lines to consider (for collectors or filtering).                   |
| `max_labels`    | `integer`      | Maximum number of hint labels to generate.                                           |
| `direction`     | `Direction`    | One of `"before"` or `"after"`. Often used for filtering targets by cursor position. |
| `hint_position` | `HintPosition` | Controls where to place the hint (e.g., `"start"`, `"end"`, `"middle"`).             |
| `target_type`   | `TargetType`   | Indicates the kind of target (`"word"`, `"line"`, `"char"`, etc).                    |

---

## 🧠 Hint Labeling & Target Info

| Field                   | Type                       | Description                                                                   |
| ----------------------- | -------------------------- | ----------------------------------------------------------------------------- |
| `jump_target_count`     | `integer`                  | Number of valid targets discovered.                                           |
| `jump_targets`          | `JumpTarget[]`             | List of discovered targets. You can replace `any` with a stronger type later. |
| `selected_jump_target?` | `JumpTarget`               | The jump target the user selected.                                            |
| `hint_labels`           | `string[]`                 | Generated label strings (e.g., `["a", "b", "aa", "ab"]`).                     |
| `assigned_hint_labels`  | `table<string, HintEntry>` | Maps labels to metadata (position, style, etc).                               |
| `single_label_count`    | `integer`                  | Number of single-letter labels used.                                          |
| `double_label_count`    | `integer`                  | Number of double-letter labels used.                                          |
| `sacrificed_keys_count` | `integer`                  | Keys "sacrificed" to prevent conflicts or overflows.                          |

---

## 🕹️ Selection & Input State

| Field                   | Type            | Description                                                                           |
| ----------------------- | --------------- | ------------------------------------------------------------------------------------- |
| `selection_mode`        | `SelectionMode` | `"single"`, `"double"`, `"stepwise"`, etc.                                            |
| `selection_first_char?` | `string`        | First char of a 2-char label, if selected.                                            |
| `auto_select_target?`   | `boolean`       | Whether SmartMotion should jump automatically if only one target exists.              |
| `quick_action?`         | `boolean`       | If true, allows immediate execution on target under cursor without waiting for input. |

---

## 🔍 Search-Specific Fields

| Field                | Type      | Description                                                                            |
| -------------------- | --------- | -------------------------------------------------------------------------------------- |
| `is_searching_mode?` | `boolean` | Enables a search mode that updates `search_text` in real time.                         |
| `search_text?`       | `string`  | Current search text being typed.                                                       |
| `last_search_text?`  | `string`  | Last used search term, if any.                                                         |
| `num_of_char?`       | `number`  | Used in motions like `f`/`t` to restrict input length.                                 |
| `exclude_target?`    | `boolean` | If true, the hinted target will be excluded from the final range (like `dt` behavior). |

---

## 🎨 Rendering

| Field                 | Type                                              | Description                                                                             |
| --------------------- | ------------------------------------------------- | --------------------------------------------------------------------------------------- |
| `virt_text_pos?`      | `"eol" \| "overlay" \| "right_align" \| "inline"` | Controls hint rendering style/position.                                                 |
| `should_show_prefix?` | `boolean`                                         | Whether to show the motion key prefix in the hint label (for debugging or chaining UI). |

---

## 📋 Sorting and Weighting

| Field              | Type            | Description                                            |
| ------------------ | --------------- | ------------------------------------------------------ |
| `sort_by?`         | `"sort_weight"` | Indicates the sort metric (future expansion possible). |
| `sort_descending?` | `boolean`       | Whether to sort in descending order.                   |

---

## ✂️ Action and Paste Settings

| Field           | Type                         | Description                                                 |
| --------------- | ---------------------------- | ----------------------------------------------------------- |
| `paste_mode?`   | `"before" \| "after"`        | Used in paste-related motions to determine paste direction. |
| `word_pattern?` | `string`                     | Custom regex pattern to define what a "word" is.            |
| `keys?`         | `(motion_state) => string[]` | Optional function that returns available keys for hinting.  |

---

## 🏷️ Metadata

| Field          | Type     | Description                                                              |
| -------------- | -------- | ------------------------------------------------------------------------ |
| `name`         | `string` | Name of the motion.                                                      |
| `trigger_key?` | `string` | The key that triggered this motion, if known. Can be the same as `name`. |

---

## 🧩 Tips for Custom Motions

- Any field can be added to `motion_state` to pass custom data between pipeline steps.
- It's recommended to _namespace_ motion-specific keys (e.g., `my_module_temp_data`) to avoid clashes.
- You can also use wrapper modules to modify `motion_state` dynamically, inject default values, or transform behavior based on user input.
