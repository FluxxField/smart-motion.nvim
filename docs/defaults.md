# Built-in Modules Reference

SmartMotion comes with a complete set of default modules — collectors, extractors, filters, visualizers, actions, wrappers, and presets — that give you powerful capabilities right out of the box.

---

## Collectors

| Name          | Description                                              |
| ------------- | -------------------------------------------------------- |
| `lines`       | Collects lines in the buffer forward or backward         |
| `treesitter`  | Collects targets from treesitter nodes (4 modes)         |
| `diagnostics` | Collects LSP diagnostics as targets                      |
| `history`     | Collects entries from the smart-motion jump history      |

---

## Extractors

| Name                       | Description                                                  |
| -------------------------- | ------------------------------------------------------------ |
| `lines`                    | Extracts whole lines as targets                              |
| `words`                    | Extracts individual word targets using word regex pattern    |
| `text_search_1_char`       | Extracts 1-character search matches (used for `f`/`F`)      |
| `text_search_1_char_until` | Same as above but sets `exclude_target` (used for `t`/`T`)  |
| `text_search_2_char`       | Extracts 2-character search matches                          |
| `live_search`              | Continuously updates search results as the user types        |
| `pass_through`             | Passes collector data through without modification           |

---

## Filters

| Name                                       | Description                                              |
| ------------------------------------------ | -------------------------------------------------------- |
| `default`                                  | No-op — passes all targets through unchanged             |
| `filter_visible`                           | Keeps only targets visible in the current window         |
| `filter_cursor_line_only`                  | Keeps only targets on the cursor line                    |
| `filter_lines_after_cursor`                | Visible lines after the cursor                           |
| `filter_lines_before_cursor`               | Visible lines before the cursor                          |
| `filter_lines_around_cursor`               | Visible lines before and after the cursor                |
| `filter_words_after_cursor`                | Visible words after the cursor                           |
| `filter_words_before_cursor`               | Visible words before the cursor                          |
| `filter_words_around_cursor`               | Visible words before and after the cursor                |
| `filter_words_on_cursor_line_after_cursor`  | Words on the cursor line after the cursor               |
| `filter_words_on_cursor_line_before_cursor` | Words on the cursor line before the cursor              |
| `first_target`                             | Keeps only the first target                              |

---

## Visualizers

### `hint_start`

- Shows hint labels at the **start** of each target.

### `hint_end`

- Shows hint labels at the **end** of each target.

> [!NOTE]
> Visualizers can be used for much more than hinting — popups, floating windows, and Telescope integration are all possible.

---

## Actions

| Name                 | Description                                                 |
| -------------------- | ----------------------------------------------------------- |
| `jump`               | Moves the cursor to the target                              |
| `jump_centered`      | Jumps to the target and centers the screen                  |
| `center`             | Centers the screen on the cursor                            |
| `delete`             | Deletes the target text                                     |
| `delete_jump`        | Jumps to the target and deletes it                          |
| `delete_line`        | Deletes the entire line at the target                       |
| `change`             | Changes the target text and enters insert mode              |
| `change_until`       | Changes from cursor up to (not including) the target        |
| `change_jump`        | Jumps to the target and starts a change                     |
| `change_line`        | Changes the entire line at the target                       |
| `yank`               | Yanks (copies) the target text                              |
| `yank_until`         | Yanks from cursor up to (not including) the target          |
| `yank_jump`          | Jumps to the target and yanks it                            |
| `yank_line`          | Yanks the entire line at the target                         |
| `paste`              | Pastes text at the target position                          |
| `paste_jump`         | Jumps to the target and pastes                              |
| `paste_line`         | Pastes the entire line at the target                        |
| `remote_delete`      | Deletes the target without moving the cursor                |
| `remote_delete_line` | Deletes the line at the target without moving the cursor    |
| `remote_yank`        | Yanks the target without moving the cursor                  |
| `remote_yank_line`   | Yanks the line at the target without moving the cursor      |
| `restore`            | Restores the cursor to its original location                |
| `run_motion`         | Re-runs a motion from history                               |

---

## Pipeline Wrappers

| Name          | Description                                             |
| ------------- | ------------------------------------------------------- |
| `default`     | Runs the pipeline once without modification             |
| `text_search` | Prompts user for 1–2 characters before running pipeline |
| `live_search` | Re-runs the pipeline dynamically as user types input    |

---

## Presets

The following presets are available:

| Preset        | Description                                              |
| ------------- | -------------------------------------------------------- |
| `words`       | Motions for `w`, `b`, `e`, `ge`                          |
| `lines`       | Motions for `j`, `k`                                     |
| `search`      | Motions for `f`, `F`, `s`, `S`                           |
| `delete`      | Delete motions: `d`, `dt`, `dT`, `rdw`, `rdl`           |
| `yank`        | Yank motions: `y`, `yt`, `yT`, `ryw`, `ryl`             |
| `change`      | Change motions: `c`, `ct`, `cT`                          |
| `paste`       | Paste motions: `p`, `P`                                  |
| `treesitter`  | Navigation (`]]`, `[[`, `]c`, `[c`) and editing (`daa`, `caa`, `yaa`, `dfn`, `cfn`, `yfn`) |
| `diagnostics` | Diagnostic jumping: `]d`, `[d`, `]e`, `[e`              |
| `misc`        | Repeat previous motion with `.`                          |

See [`presets.md`](./presets.md) for the full breakdown of mappings and behavior.

---

Next:

- [`custom_motion.md`](./custom_motion.md)
- [`visualizers.md`](./visualizers.md)
- [`actions.md`](./actions.md)
