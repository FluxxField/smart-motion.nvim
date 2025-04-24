# SmartMotion.nvim - Home-row powered smart motions for Neovim

```
   _____                      __  __  ___      __  _                          _
  / ___/____ ___  ____ ______/ /_/  |/  /___  / /_(_)___  ____    ____ _   __(_)___ ___
  \__ \/ __ `__ \/ __ `/ ___/ __/ /|_/ / __ \/ __/ / __ \/ __ \  / __ \ | / / / __ `__ \
 ___/ / / / / / / /_/ / /  / /_/ /  / / /_/ / /_/ / /_/ / / / / / / / / |/ / / / / / / /
/____/_/ /_/ /_/\__,_/_/   \__/_/  /_/\____/\__/_/\____/_/ /_(_)__/ /_/|___/_/_/ /_/ /_/

```

## ?? What is SmartMotion?

`SmartMotion.nvim` is a **next-generation motion engine for Neovim**, designed to unify the fragmented ecosystem of motion plugins under one **modular, powerful, and extensible system**.

Forget juggling multiple plugins like `hop.nvim`, `leap.nvim`, `flash.nvim`, `pounce.nvim`, and `sneak.nvim` - SmartMotion is designed to **replace them all**.

- Want hop-style line jumps? ?
- Want leap-style double character targeting? ?
- Want flash-style search overlays? ?
- Want dt/ct motions with visual jump targeting? ?

With SmartMotion, you build what _you_ need.

It includes intelligent label generation, dynamic feedback, and no default mappings - you get presets, not assumptions.

> [!WARNING]
> SmartMotion is still evolving. Some modules and behaviors are subject to change as we refine the system. Expect breaking changes during early versions.

---

## ?? Flow State: Native Feel, Smarter Feedback

SmartMotion introduces **Flow State**, a game-changing concept:

Flow can only be entered **during the target selection stage** of a motion.
Here's how it works:

- On the **first motion keypress** (e.g., `w`), SmartMotion shows labels.
- If **another key is pressed within 300ms**, even if that key is itself a valid label, SmartMotion **skips label selection** and executes the motion's action on the **first target**.
- You are now in **flow**.
- While in flow, subsequent SmartMotion invocations of the same type (e.g., `w`, `b`, `e`) **skip label display entirely** and act immediately on the next valid target.

### Example:

```
w     show labels
ww    jump to first target (within 300ms)
www   jump to second target (still in flow)
wwb   switch motion mid-flow (now use 'b' type)
```

This gives you a **native Vim feel** when moving fast, and **precision when you need it**. No other motion plugin does this - it's SmartMotion's killer feature.

> [!NOTE]
> When we say "jump" we mean "run the action on the next target". That could be a jump, delete, yank, change, etc.

---

## ?? Why SmartMotion?

SmartMotion stands out because it:

- ?? **Unifies the Motion Ecosystem:** Replace 5+ plugins with a single, well-designed system.
- ?? **Smart Label Generation:** Auto-detects density and selects optimal label size (1 or 2 chars).
- ?? **Dynamic Highlight Feedback:** Visually reacts as you interact - dims background, changes hint intensity.
- ?? **Composable Pipelines:** Collectors, extractors, filters, visualizers, and actions can be composed and reused.
- ?? **Flow-State Friendly:** Chain motions naturally, like native word hopping (`w`, `b`, `e`) but with label feedback.
- ?? **Zero Default Mappings:** No keybinding conflicts. Presets are opt-in, fully overridable.
- ?? **Register Anything:** Want `dw` with smart labels? `ciw`? `yap`? Build it with `action = merge({ jump, delete })`.

---

## ?? How It Works

SmartMotion revolves around modular **pipelines**. Each motion consists of:

- A **collector**: defines the _broad scope_ of content. For example, `lines` collects all lines in the buffer. Future collectors could include things like `multi_buffer_lines`.
- An **extractor**: finds individual targets (e.g., words, characters, symbols) from the collected text. Current extractors include `words`, `chars`, `lines`, and `text_search`.
- A **filter**: narrows results. Right now we offer:
  - `default` (pass-through)
  - `filter_visible_lines` (only show what's visible)

> [!TIP]
> In the future, direction (e.g., `AFTER_CURSOR`, `BEFORE_CURSOR`) will be implemented using filters, making them easier to customize.

- A **visualizer**: how targets are displayed. Currently we offer a `hint` visualizer with dynamic dimming and label positioning.
- An **action**: what happens when you pick a target. Jump, yank, delete, change - or merge them.
- A **pipeline wrapper**: lets you create behaviors like `live_search` or 2-char search input. Wrappers rerun the pipeline as the user types.
  - `default`: pass-through
  - `live_search`: reruns pipeline on text input
  - `text_search`: waits for input then runs

### ?? Presets in Your Config

Presets are fully configurable:

```lua
return {
  "FluxxField/smart-motion.nvim",
  opts = {
    presets = {
      words = true,
      lines = true,
      search = true,
      delete = true,
      yank = true,
      change = true,
    },
  },
}
```

To disable a preset or specific mappings:

```lua
presets = {
  words = { "w", "b" }, -- disables "w" and "b" word motions
}
```

Or for the default config structure:

```lua
return {
  "FluxxField/smart-motion.nvim",
  opts = {},
}
```

> [!NOTE]
> This does not turn on presets or mappings. You need to manually turn them on yourself

Default values:

```lua
M.defaults = {
  keys = "fjdksleirughtynm",
  highlight = {
    hint = "SmartMotionHint",
    hint_dim = "SmartMotionHintFaded",
    first_char = "SmartMotionFirstChar",
    first_char_dim = "SmartMotionFirstCharDim",
    second_char = "SmartMotionSecondChar",
    second_char_dim = "SmartMotionSecondCharDim",
    dim = "SmartMotionDim",
  },
  presets = {},
}
```

---

## ?? What a Basic Motion Looks Like

```lua
w = {
  pipeline = {
    collector = "lines",
    extractor = "words",
    visualizer = "hint_start",
    filter = "default",
  },
  pipeline_wrapper = "default",
  action = "jump",
  state = {
    direction = DIRECTION.AFTER_CURSOR,
    hint_position = HINT_POSITION.START,
  },
  map = true,
  modes = { "n", "v" },
  metadata = {
    label = "Jump to Start of Word after cursor",
    description = "Jumps to the start of a visible word target using labels after the cursor",
  },
}
```

This shows the anatomy of a full motion declaration using SmartMotion's modular system. You can register your own motions with full control over behavior, visuals, and context.

---

## 📂 License

Licensed under [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html).

---

## ✨ Author

Built with ❤️ by [FluxxField](https://github.com/FluxxField)

I also build custom websites for businesses and brands using Next.js, React, Tailwindcss, Motion, and more. Check out:

- [Cornerstone Homes](https://www.cornerstonehomesok.com)  
- [SLP Custom Built](https://www.slpcustombuilt.com)

📧 [keenanjj13@protonmail.com](mailto:keenanjj13@protonmail.com)

---

For full documentation and how to create your own modules or motion presets, check out the [docs/](./docs) directory.