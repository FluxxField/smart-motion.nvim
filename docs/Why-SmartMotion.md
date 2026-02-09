# Why SmartMotion?

You have choices. Hop, leap, flash, mini.jump. They're all excellent plugins. So why SmartMotion?

---

## Standing on the Shoulders of Giants

SmartMotion wouldn't exist without the plugins that came before it.

[hop.nvim](https://github.com/phaazon/hop.nvim) pioneered hint-based jumping in Neovim. It proved that label-driven navigation could be fast, intuitive, and a genuine improvement over counting lines or searching. Every motion plugin since, including SmartMotion, owes something to hop.

[leap.nvim](https://github.com/ggandor/leap.nvim) (and [lightspeed.nvim](https://github.com/ggandor/lightspeed.nvim) before it) introduced the elegant 2-character search pattern. The "clairvoyant" highlighting, the minimal keystrokes, the focus on getting you there in two characters. It's a beautifully refined experience.

[flash.nvim](https://github.com/folke/flash.nvim) raised the bar for what a motion plugin could be. Treesitter integration, search-based jumping, remote operations, multi-window support. Flash showed that motion plugins could be feature-rich without being overwhelming.

[mini.jump](https://github.com/echasnovski/mini.nvim#mini.jump) showed that minimalism can be a feature. Part of the excellent mini.nvim ecosystem, it does character jumping cleanly and fast.

**These are all great plugins.** If you're happy with any of them, that's a perfectly good choice. They're well-maintained, well-documented, and solve real problems well.

SmartMotion's goal is different: take the best ideas from all of them, unify them under one architecture, and then go further, into territory no motion plugin has explored.

---

## What SmartMotion Does Differently

### 1. Zero-Config Composability

This is SmartMotion's core insight. Operators and motions are separate concerns that compose automatically via the inference system.

Enable `words` and `delete` as presets. Now `dw`, `db`, `de`, `dge` all work, no mappings defined. Enable `yank` too. Now `yw`, `yb`, `ye`, `yge` also work. Enable `search`, and now `ds`, `dS`, `df`, `dt` all work too. Every motion preset **multiplies** with every operator preset.

```
Enable a motion → every operator can use it
Enable an operator → it works with every motion
The growth is multiplicative, not additive
```

11 composable motions × 5 operators = **55+ compositions from 16 keys**, all inferred automatically. No explicit mapping for any of them.

```lua
-- This is ALL you need.
presets = {
  words = true,    -- registers w, b, e, ge
  lines = true,    -- registers j, k
  search = true,   -- registers s, S, f, F, t, T
  delete = true,   -- d now works with ALL of the above
  yank = true,     -- y now works with ALL of the above
  change = true,   -- c now works with ALL of the above
}
-- Result: dw, db, de, dj, dk, ds, dS, df, dF, dt, dT,
--         yw, yb, ye, yj, yk, ys, yS, yf, yF, yt, yT,
--         cw, cb, ce, cj, ck, cs, cS, cf, cF, ct, cT, ...
```

And it extends automatically. If you build a custom composable motion, every operator can use it immediately. No additional config needed.

In other plugins, you either get limited operator support (flash supports some d/y/c but not the full matrix) or you have to map every combination explicitly.

### 2. Flow State

Select a target, then press any motion key within 300ms for instant movement, no labels. Hold `w` and it flows word-by-word like native Vim. Chain different motions: `w` → `j` → `b` → `w`, all without hints.

This solves a real problem: other motion plugins force a choice between precision (labels) and speed (native feel). You can't have both. SmartMotion gives you both: labels when you need to aim, instant movement when you're flowing through code.

The 300ms window resets on every motion, so you can chain indefinitely. And you can chain *different* motions: word jump into line jump into search, all without seeing hints.

No other motion plugin does this.

### 3. Pipeline-Based Text Objects

`af`, `if`, `ac`, `ic`, `aa`, `ia`, `fn` are real text objects registered in operator-pending and visual mode. They work with *any* vim operator, not just `d`/`y`/`c`, but `gq`, `=`, `>`, `gU`, `!`, `zf`, anything:

```
daf   → delete around function
=if   → auto-indent function body
>ac   → indent entire class
gqaf  → format a function
gUfn  → uppercase a function name
yaa   → yank argument with separator
vif   → visually select function body
```

No explicit mappings needed for any of these. The text objects are pipeline-based: they show labels on all matching treesitter nodes, you pick one, and the pending operator applies.

This goes beyond what nvim-treesitter-textobjects offers because SmartMotion's text objects let you pick *which* function to act on, not just the nearest one.

### 4. Multi-Char Motion Inference

Type `dfn` quickly and SmartMotion resolves `fn` as "function name." Type `df` and pause, and it falls through to find-char. The system uses `timeoutlen`-based resolution: after reading `f`, it checks if any longer composable motion starts with `f` (yes, `fn`). It waits for more input. If `n` arrives quickly, it resolves as `fn`. If nothing arrives, it resolves as `f`.

This means zero conflicts. `df` + char still works as find-char. `dfn` typed quickly selects function names. No ambiguity, no special modes.

### 5. Label Conflict Avoidance

When searching for "fu", SmartMotion won't assign "n" as a label if the match is followed by "n", because pressing "n" would be ambiguous (select this target, or continue typing "fun"?).

This sounds small, but it eliminates an entire class of frustrating misselections. Labels are always unambiguous. You never accidentally select a target when you meant to keep typing.

Applies to live search (`s`), fuzzy search (`S`), native search (`/`/`?`), and treesitter search (`R`).

### 6. A Full History System

`g.` opens a floating browser with frecency-ranked history, persistent pins (`gp`, like harpoon), `j`/`k` navigation with live preview, `/search` filtering, and remote action mode (`d`/`y`/`c` on any entry without navigating there). `g1`-`g9` jump instantly to pins. `gA`-`gZ` jump to cross-project global pins. History persists across sessions.

This isn't a basic "recent locations" list. It's a full navigation system:
- **Frecency** ranks by visit count × time decay (not just recency)
- **Pins** are harpoon-style bookmarks (up to 9 per project, 26 global)
- **Preview** shows context around each entry as you navigate
- **Action mode** lets you delete, yank, or change targets remotely from the browser
- **Session merging** means multiple Neovim instances share history safely

Other motion plugins don't touch this space at all. SmartMotion lets you replace harpoon entirely.

### 7. It's a Framework

Every built-in motion uses the same public API you do. The pipeline is open:

```
Collector (where to look)
    ↓
Extractor (what to find)
    ↓
Modifier (enrich with metadata)
    ↓
Filter (narrow down)
    ↓
Visualizer (show to user)
    ↓
Selection (user picks)
    ↓
Action (do something)
```

Each stage is a swappable module with a global registry. Register custom collectors, extractors, filters, actions. Build motions that don't exist yet:

```lua
-- This is literally how the built-in 'w' motion is defined
require("smart-motion").register_motion("w", {
  collector = "lines",
  extractor = "words",
  filter = "filter_words_after_cursor",
  visualizer = "hint_start",
  action = "jump_centered",
  modes = { "n", "v", "o" },
})
```

There's no hidden internal API. What SmartMotion uses, you can use.

Other plugins offer limited customization: change some options, maybe define a custom pattern. SmartMotion lets you build entirely new motion paradigms. The `treesitter` collector, the `live_search` extractor, the `textobject_select` action: they're all modules you could have written yourself and registered into the system.

---

## Detailed Comparison

### vs. hop.nvim

**Hop** pioneered the hint-based jumping pattern in Neovim. It's fast, reliable, and battle-tested. If you just need labels on words and lines, hop does that well with minimal complexity.

| Aspect | hop.nvim | SmartMotion |
|--------|----------|-------------|
| Word/line jumping | ✓ | ✓ |
| Pattern search | ✓ | ✓ |
| Treesitter integration | Limited | Full |
| Treesitter text objects | | ✓ |
| Composable operators | | ✓ |
| Multi-window | | ✓ |
| Flow state | | ✓ |
| Motion history + pins | | ✓ |
| Custom motion creation | Difficult | Built-in |
| Architecture | Monolithic | Modular pipeline |

**Where Hop wins**: Simplicity. Less surface area means less to learn and less to go wrong. If you only need word/line jumping, hop is a proven choice with years of stability behind it.

**Where SmartMotion wins**: Everything beyond basic jumping: treesitter, composable operators, flow state, history, extensibility.

---

### vs. leap.nvim

**Leap** introduced the elegant 2-character search pattern. Its search UX is laser-focused and beautifully refined. Type two characters and you're there.

| Aspect | leap.nvim | SmartMotion |
|--------|-----------|-------------|
| 2-char search | ✓ | ✓ |
| Multi-window | Via plugin | Built-in |
| Treesitter integration | Via plugin | Built-in |
| Treesitter text objects | | ✓ |
| Composable d/y/c | | ✓ |
| Live incremental search | | ✓ |
| Fuzzy search | | ✓ |
| Remote operations | | ✓ |
| Flow state | | ✓ |
| Motion history + pins | | ✓ |
| Custom motion creation | Limited | Full |

**Where Leap wins**: The 2-character search experience. Leap is focused on one interaction pattern and does it exceptionally. The "clairvoyant" highlighting, the minimal keystrokes, the feel of typing two characters and landing exactly where you want. It's hard to beat in terms of pure search polish. If 2-char search is your primary motion pattern, leap's refinement is worth considering.

**Where SmartMotion wins**: Breadth. SmartMotion has 2-char search (`f`/`F`) plus live search, fuzzy search, treesitter, composable operators, text objects, flow state, history, and full extensibility.

---

### vs. flash.nvim

**Flash** is the most feature-complete alternative. It has excellent treesitter integration, search-based jumping, remote operations, multi-window support, and a large, active community.

| Aspect | flash.nvim | SmartMotion |
|--------|------------|-------------|
| Search-based jumping | ✓ | ✓ |
| Treesitter integration | ✓ | ✓ |
| Treesitter text objects | | ✓ |
| Multi-window | ✓ | ✓ |
| Composable operators | Partial | Full |
| Remote operations | ✓ | ✓ |
| Fuzzy search | | ✓ |
| Label conflict avoidance | | ✓ |
| Flow state | | ✓ |
| Multi-cursor selection | | ✓ |
| Argument swap | | ✓ |
| Treesitter incremental select | | ✓ |
| Motion history + pins | | ✓ |
| Custom motion creation | Limited | Full pipeline |
| Plugin interop | Limited | Registry system |

**Where Flash wins**: Maturity and community. Flash is well-maintained, widely used, and has extensive documentation. Flash's treesitter search labels all ancestor nodes of all matches at once, a single-step approach that can be faster than SmartMotion's two-phase flow for simple cases with few matches. Flash also has broader ecosystem integration (telescope, fzf-lua, etc.).

**Treesitter Search difference**: Flash labels all ancestor nodes of all matches simultaneously. SmartMotion uses a two-phase approach: first pick which match you care about, then pick the ancestor scope. With many matches, Flash's single-step can flood the screen with labels, while SmartMotion narrows down first. The end result is identical (the operator applies to the full node), but the path differs. Neither is strictly better; it depends on the situation.

**Where SmartMotion wins**: Full composability (the inference system gives you 55+ compositions from 16 keys, vs Flash's more limited operator support), flow state, label conflict avoidance, pipeline-based text objects that work with any vim operator, fuzzy search, motion history with pins, and the ability to build entirely custom motions via the pipeline.

---

### vs. mini.jump

**mini.jump** is part of the excellent mini.nvim ecosystem. It's minimal, fast, and does character jumping cleanly.

| Aspect | mini.jump | SmartMotion |
|--------|-----------|-------------|
| Character jumping | ✓ | ✓ |
| Word jumping | Via mini.jump2d | ✓ |
| Treesitter integration | | ✓ |
| Composable operators | | ✓ |
| Multi-window | | ✓ |
| Flow state | | ✓ |
| Ecosystem integration | mini.nvim | Standalone |

**Where mini.jump wins**: If you're invested in the mini.nvim ecosystem, mini.jump fits naturally alongside mini.ai, mini.surround, mini.pairs, etc. It's lightweight and doesn't try to do too much. Sometimes that's exactly what you want.

**Where SmartMotion wins**: If you want a comprehensive standalone solution that covers jumping, searching, treesitter navigation, composable operators, text objects, history, pins, and extensibility in one plugin.

---

## What You Consolidate

With all presets enabled, SmartMotion can replace several plugins at once:

```
Before                                          After
──────                                          ─────
flash.nvim (motions + search)                   smart-motion.nvim
harpoon (file pins + quick navigation)            with one opts table
nvim-treesitter-textobjects (af/if/ac/ic)
mini.ai (around/inside text objects)
```

One plugin, one config, and everything composes with everything else. Your pin system knows about your motion history. Your text objects work with flow state. Your operators compose with motions you haven't even thought of yet.

This isn't about replacing good plugins for the sake of it. It's about the compound benefits you get when these features share an architecture. A motion recorded in history carries its full context: you can replay it, pin it, or act on it remotely. A text object uses the same labeling system as your search motions. An operator infers its pipeline from any composable motion, including ones you build yourself.

---

## The Philosophy

### 1. Everything is a Pipeline

A motion isn't a function. It's a data flow through composable stages. Each stage is independent. Swap the visualizer without touching the collector, add a modifier without changing the filter. **Separation of concerns, applied to motions.**

### 2. No Magic

The built-in `w` motion doesn't use special internal APIs. It's registered the same way you'd register a custom motion. **What SmartMotion uses internally, you can use too.**

### 3. Vim-Native Feel

SmartMotion doesn't fight Vim:

- Operator-pending mode works (`>w`, `gUj`, `=af`, `gqaf`)
- Text objects work in visual and operator-pending mode
- Repeat with `.` works
- Visual mode works
- Jumplist, marks, registers: all respected

If it feels like Vim, it's because SmartMotion respects Vim's model.

---

## When NOT to Choose SmartMotion

Be honest about what you need:

- **If you just need basic jumping:** hop or leap are simpler, proven, and have less surface area
- **If you never customize anything:** any motion plugin will work, and simpler ones have less to learn
- **If you want minimal footprint:** mini.jump is lighter and fits the mini.nvim ecosystem
- **If you're already happy:** flash is excellent and switching has a cost. Don't fix what isn't broken.

SmartMotion shines when you want **power and extensibility**: composable operators, treesitter text objects, flow state, motion history, and the ability to build custom motions. If you don't need that, simpler options exist, and that's fine.

---

## Ready to Try It?

→ **[Quick Start](Quick-Start.md)**: Get running in 60 seconds

→ **[Presets Guide](Presets.md)**: See all 100+ built-in keybindings

→ **[Build Your Own](Building-Custom-Motions.md)**: Create your first custom motion
