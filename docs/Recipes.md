# Recipes & Cookbook

Every motion in SmartMotion flows through the same pipeline:

**Collector -> Extractor -> Filter -> Visualizer -> Action**

Each stage is a swappable module. By changing one part, you get a completely different motion. This guide teaches you to think in pipeline terms so you can build exactly the motion you want.

---

## Anatomy of a Motion

Let's start with `w` (jump to the next word) and transform it, one piece at a time, into completely different motions.

### Starting point: forward word jump

```lua
require("smart-motion").motions.register("gw", {
    collector = "lines",
    extractor = "words",
    filter = "filter_words_after_cursor",
    visualizer = "hint_start",
    action = "jump_centered",
    map = true,
    modes = { "n", "v", "o" },
    metadata = {
        label = "Jump to Word after cursor",
    },
})
```

This collects visible lines, extracts word boundaries, filters to only those after the cursor, shows labels at the start of each word, and jumps when you pick one.

### Step 1: Swap the filter -- you just built `b`

```lua
require("smart-motion").motions.register("gb", {
    collector = "lines",
    extractor = "words",
    filter = "filter_words_before_cursor",  -- <- changed
    visualizer = "hint_start",
    action = "jump_centered",
    map = true,
    modes = { "n", "v", "o" },
    metadata = {
        label = "Jump to Word before cursor",
    },
})
```

One filter change. Everything else is identical. Forward became backward.

### Step 2: Swap the filter again -- bidirectional

```lua
require("smart-motion").motions.register("gw", {
    collector = "lines",
    extractor = "words",
    filter = "filter_words_around_cursor",  -- <- changed
    visualizer = "hint_start",
    action = "jump_centered",
    map = true,
    modes = { "n", "v", "o" },
    metadata = {
        label = "Jump to Word in either direction",
    },
})
```

Now labels appear on words both above and below the cursor.

### Step 3: Swap the extractor -- you just built `j`

```lua
require("smart-motion").motions.register("gj", {
    collector = "lines",
    extractor = "lines",                     -- <- changed
    filter = "filter_lines_after_cursor",    -- <- changed
    visualizer = "hint_start",
    action = "jump_centered",
    map = true,
    modes = { "n", "v", "o" },
    metadata = {
        label = "Jump to Line after cursor",
    },
})
```

Swap `words` for `lines` in the extractor, match the filter to line-based, and you jump to lines instead of words.

### Step 4: Swap the action -- now it deletes

```lua
require("smart-motion").motions.register("gd", {
    collector = "lines",
    extractor = "words",
    filter = "filter_words_after_cursor",
    visualizer = "hint_start",
    action = "delete",                       -- <- changed
    map = true,
    modes = { "n" },
    metadata = {
        label = "Delete to Word",
    },
})
```

Same targets, same labels. But instead of jumping, it deletes from cursor to the selected word.

### Step 5: Swap the extractor to live search -- search-and-destroy

```lua
require("smart-motion").motions.register("gx", {
    collector = "lines",
    extractor = "live_search",               -- <- changed
    filter = "filter_visible",               -- <- changed
    visualizer = "hint_start",
    action = "delete",
    map = true,
    modes = { "n" },
    metadata = {
        label = "Search and Delete",
    },
})
```

Type characters to narrow down matches, then pick a label to delete from cursor to that match.

### Step 6: Add multi-window -- cross-window search-and-destroy

```lua
require("smart-motion").motions.register("gx", {
    collector = "lines",
    extractor = "live_search",
    filter = "filter_visible",
    visualizer = "hint_start",
    action = "delete",
    map = true,
    modes = { "n" },
    metadata = {
        label = "Cross-window Search and Delete",
        motion_state = {
            multi_window = true,             -- <- added
        },
    },
})
```

One metadata flag. Now targets appear across every visible window.

### The takeaway

Six steps. We started with a forward word jump and ended with a cross-window search-and-delete. Every transformation was a single-field swap. That is the power of the pipeline: you don't write motion logic, you assemble it from parts.

---

## How to Use These Recipes

There are two ways to apply a recipe.

### Option 1: Preset override (recommended)

The simplest approach. Pass a table to the preset in your `setup()` call. Each key you provide is deep-merged into the default motion config:

```lua
require("smart-motion").setup({
    presets = {
        words = {
            w = {
                filter = "filter_words_around_cursor",
            },
        },
        search = true,
        lines = true,
    },
})
```

This keeps the default `w` config but overrides its filter to be bidirectional. You only specify what changes.

### Option 2: register_motion (full control)

Use `register_motion` after setup for completely custom motions:

```lua
require("smart-motion").motions.register("gw", {
    collector = "lines",
    extractor = "words",
    filter = "filter_words_around_cursor",
    visualizer = "hint_start",
    action = "jump_centered",
    map = true,
    modes = { "n", "v", "o" },
    metadata = {
        label = "Bidirectional Word Jump",
    },
})
```

This registers a brand-new motion on the `gw` key. Use this when you want a motion that doesn't correspond to any existing preset.

---

## Quick Reference: What Each Part Controls

### Extractors

Extractors determine *what kind of targets* appear.

| Name | What it finds |
|------|---------------|
| `words` | Word boundaries (respects `word_pattern` metadata) |
| `lines` | Line starts (non-blank lines) |
| `text_search_1_char` | Matches after typing 1 character |
| `text_search_2_char` | Matches after typing 2 characters (inclusive) |
| `text_search_2_char_until` | Matches after typing 2 characters (exclusive/till) |
| `live_search` | Incremental literal search (labels update as you type) |
| `fuzzy_search` | Incremental fuzzy search (scored by match quality) |
| `pass_through` | No extraction; passes collector output directly |

### Filters

Filters determine *which targets survive* to be labeled.

| Name | What it keeps |
|------|---------------|
| `filter_words_after_cursor` | Words after the cursor position |
| `filter_words_before_cursor` | Words before the cursor position |
| `filter_words_around_cursor` | Words in both directions |
| `filter_lines_after_cursor` | Lines below the cursor |
| `filter_lines_before_cursor` | Lines above the cursor |
| `filter_lines_around_cursor` | Lines in both directions |
| `filter_words_on_cursor_line_after_cursor` | Words on the current line, after cursor |
| `filter_words_on_cursor_line_before_cursor` | Words on the current line, before cursor |
| `filter_cursor_line_only` | All words on the current line |
| `filter_visible` | Everything in the visible viewport |
| `first_target` | Only the single closest target |

### Visualizers

Visualizers determine *where the label appears* on each target.

| Name | Label placement |
|------|-----------------|
| `hint_start` | At the start of the target text |
| `hint_end` | At the end of the target text |

### Actions

Actions determine *what happens* when you pick a target.

| Name | What it does |
|------|-------------|
| `jump` | Moves cursor to the target |
| `jump_centered` | Moves cursor to the target and centers the screen |
| `delete` | Deletes from cursor to the target |
| `yank` | Yanks from cursor to the target |
| `remote_delete` | Deletes the target word/line without moving cursor |
| `remote_yank` | Yanks the target word/line without moving cursor |
| `merge({ "jump", "yank" })` | Runs multiple actions in sequence (e.g., jump then yank) |

### Collectors

Collectors determine *where targets come from*.

| Name | Source |
|------|--------|
| `lines` | Visible buffer lines (default for most motions) |
| `treesitter` | Treesitter AST nodes |
| `diagnostics` | LSP diagnostics |
| `git_hunks` | Git changed regions |
| `quickfix` | Quickfix or location list entries |
| `marks` | Vim marks |

---

## f/t Recipes

### Make f single-char

By default, `f` requires 2 characters (like vim-sneak). To make it behave like native `f` with just 1 character:

```lua
presets = {
    search = {
        f = { extractor = "text_search_1_char" },
        F = { extractor = "text_search_1_char" },
    },
}
```

**What changed:** The extractor was swapped from `text_search_2_char` to `text_search_1_char`, so it prompts for one character instead of two.

### Make f multiline

By default, `f` is line-constrained. To let it find matches across the entire visible buffer:

```lua
presets = {
    search = {
        f = { filter = "filter_words_after_cursor" },
        F = { filter = "filter_words_before_cursor" },
    },
}
```

**What changed:** The filter was swapped from `filter_words_on_cursor_line_after_cursor` to `filter_words_after_cursor`, which includes all lines instead of just the current one.

### Make f multiline AND single-char

Combine both changes for a single-character, full-buffer find:

```lua
presets = {
    search = {
        f = {
            extractor = "text_search_1_char",
            filter = "filter_words_after_cursor",
        },
        F = {
            extractor = "text_search_1_char",
            filter = "filter_words_before_cursor",
        },
    },
}
```

**What changed:** Both the extractor (1-char input) and the filter (full buffer range) were overridden at the same time.

### Make f a live search

Turn `f` into an incremental search that updates labels as you type, instead of waiting for a fixed number of characters:

```lua
presets = {
    search = {
        f = {
            extractor = "live_search",
            filter = "filter_words_after_cursor",
        },
        F = {
            extractor = "live_search",
            filter = "filter_words_before_cursor",
        },
    },
}
```

**What changed:** The extractor was swapped to `live_search`, which shows and refines labels with each keystroke. The filter was expanded to the full buffer since live search works best with more targets.

### Make f cross-window

Find characters across all visible windows, not just the current one:

```lua
presets = {
    search = {
        f = {
            filter = "filter_words_after_cursor",
            metadata = {
                motion_state = { multi_window = true },
            },
        },
        F = {
            filter = "filter_words_before_cursor",
            metadata = {
                motion_state = { multi_window = true },
            },
        },
    },
}
```

**What changed:** The filter was expanded beyond the current line, and `multi_window = true` was added to metadata so the collector gathers targets from every visible window.

### Make t inclusive

By default, `t` jumps to just *before* the match (exclusive, like native vim `t`). To make it jump *onto* the match (inclusive, like `f`):

```lua
presets = {
    search = {
        t = { extractor = "text_search_2_char" },
        T = { extractor = "text_search_2_char" },
    },
}
```

**What changed:** The extractor was swapped from `text_search_2_char_until` (exclusive) to `text_search_2_char` (inclusive), making `t` behave like `f` while keeping its own keybinding.

---

## Word Motion Recipes

### Custom word pattern / camelCase boundaries

Override the word pattern to match camelCase segments, individual number groups, or any pattern you want:

```lua
presets = {
    words = {
        w = {
            metadata = {
                word_pattern = [[\v(\u\l+|\l+|\u+|\d+)]],
            },
        },
        b = {
            metadata = {
                word_pattern = [[\v(\u\l+|\l+|\u+|\d+)]],
            },
        },
    },
}
```

**What changed:** The `word_pattern` metadata tells the `words` extractor to use a custom regex. This pattern splits `camelCaseWord` into `camel`, `Case`, and `Word` as separate targets.

### Bidirectional words

Show word targets both above and below the cursor:

```lua
presets = {
    words = {
        w = { filter = "filter_words_around_cursor" },
    },
}
```

**What changed:** The filter was swapped from `filter_words_after_cursor` to `filter_words_around_cursor`, so labels appear in both directions.

### Multi-window words

Jump to words in any visible window:

```lua
presets = {
    words = {
        w = {
            filter = "filter_visible",
            metadata = {
                motion_state = { multi_window = true },
            },
        },
    },
}
```

**What changed:** The filter was widened to `filter_visible` (all viewport targets), and `multi_window = true` tells the collector to gather targets from every visible window.

### Jump to word ends

Show labels at the end of each word instead of the start (like `e` but for any direction):

```lua
presets = {
    words = {
        w = { visualizer = "hint_end" },
    },
}
```

**What changed:** The visualizer was swapped from `hint_start` to `hint_end`, placing the label at the last character of each word.

---

## Search Recipes

### Make s single-window

By default, `s` searches across all visible windows. To restrict it to the current window:

```lua
presets = {
    search = {
        s = {
            metadata = {
                motion_state = { multi_window = false },
            },
        },
    },
}
```

**What changed:** Setting `multi_window = false` in metadata overrides the default `true`, limiting the search to the current window.

### Make s line-constrained

Restrict the live search to only matches on the current line (useful for precise edits):

```lua
presets = {
    search = {
        s = {
            filter = "filter_words_on_cursor_line_after_cursor",
            metadata = {
                motion_state = { multi_window = false },
            },
        },
    },
}
```

**What changed:** The filter was narrowed to `filter_words_on_cursor_line_after_cursor` and multi-window was disabled, turning `s` into a line-scoped search.

### Swap s and S behavior

If you prefer fuzzy search on `s` and literal search on `S`:

```lua
presets = {
    search = {
        s = { extractor = "fuzzy_search" },
        S = { extractor = "live_search" },
    },
}
```

**What changed:** The extractors were swapped. `s` now uses `fuzzy_search` (scoring by match quality) and `S` uses `live_search` (exact literal matching).

---

## Line Motion Recipes

### Bidirectional lines

Show line targets both above and below the cursor:

```lua
presets = {
    lines = {
        j = { filter = "filter_lines_around_cursor" },
    },
}
```

**What changed:** The filter was swapped from `filter_lines_after_cursor` to `filter_lines_around_cursor`, so labels appear on lines in both directions.

---

## General Patterns

These patterns work with any motion. They show the principle, then you apply it to whichever key you want.

### Make any forward motion go backward

Swap an `after` filter for a `before` filter:

```lua
-- Example: make w go backward
presets = {
    words = {
        w = { filter = "filter_words_before_cursor" },
    },
}
```

**What changed:** Any `filter_*_after_cursor` can be replaced with its `filter_*_before_cursor` counterpart to reverse direction.

### Make any motion bidirectional

Swap any directional filter for its `around` variant:

```lua
-- Example: make j bidirectional
presets = {
    lines = {
        j = { filter = "filter_lines_around_cursor" },
    },
}
```

**What changed:** Replace `filter_lines_after_cursor` with `filter_lines_around_cursor` (or `filter_words_after_cursor` with `filter_words_around_cursor` for word motions).

### Make any jump center the screen

Swap the action from `jump` to `jump_centered`:

```lua
-- Example: a custom motion that centers after jumping
require("smart-motion").motions.register("gw", {
    collector = "lines",
    extractor = "words",
    filter = "filter_words_after_cursor",
    visualizer = "hint_start",
    action = "jump_centered",
    map = true,
    modes = { "n" },
    metadata = { label = "Jump to Word (centered)" },
})
```

**What changed:** The action `jump_centered` centers the viewport on the target line after jumping. The default presets already use `jump_centered`, but if you register custom motions with `jump`, switching to `jump_centered` adds the centering behavior.

### Make any motion auto-jump to the closest target

Use the `first_target` filter to skip label selection entirely and jump to the nearest match:

```lua
-- Example: auto-jump to the next word
presets = {
    words = {
        w = { filter = "first_target" },
    },
}
```

**What changed:** The `first_target` filter keeps only the single closest target, so the action executes immediately without showing labels. This turns a labeled motion into an instant one.

---

## Next Steps

-> **[Advanced Recipes](Advanced-Recipes.md)**: Treesitter text objects, remote operations, multi-cursor, and more

-> **[Building Custom Motions](Building-Custom-Motions.md)**: Register your own pipeline stages from scratch

-> **[Pipeline Architecture](Pipeline-Architecture.md)**: Deep dive into how the pipeline works internally

-> **[API Reference](API-Reference.md)**: Complete reference for all registries, modules, and functions
