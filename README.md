# SmartMotion.nvim - Home-row powered smart motions for Neovim

```
   _____                      __  __  ___      __  _                          _
  / ___/____ ___  ____ ______/ /_/  |/  /___  / /_(_)___  ____    ____ _   __(_)___ ___
  \__ \/ __ `__ \/ __ `/ ___/ __/ /|_/ / __ \/ __/ / __ \/ __ \  / __ \ | / / / __ `__ \
 ___/ / / / / / / /_/ / /  / /_/ /  / / /_/ / /_/ / /_/ / / / / / / / / |/ / / / / / / /
/____/_/ /_/ /_/\__,_/_/   \__/__/  /_/\____/\__/_/\____/_/ /_(_)__/ /_/|___/_/_/ /_/ /_/
```

## 🚀 What is SmartMotion?

`SmartMotion.nvim` is a **next-generation motion engine for Neovim**, unifying the fragmented ecosystem of motion plugins with one modular, extensible system.

Think of it as a foundation that can replicate:

- `hop.nvim`-style line jumps ✅
- `leap.nvim`-style double-char targeting ✅
- `flash.nvim`-style overlays ✅
- Visual `dt/ct` motions with feedback ✅

With SmartMotion, you build exactly what _you_ need - using composable modules, zero assumptions, and full control.

For deep dives into modules, flow state, action merging, or highlight customization, see the [docs folder](./docs).

> [!WARNING]
> **Early Stage Warning:** This plugin is under active development. Breaking changes are expected as it matures.

---

## Configuration

SmartMotion comes with no default mappings -- everything is opt-in. Here's a quick-start example with presets and highlight customization:

```lua
return {
  "FluxxField/smart-motion.nvim",
  opts = {
    presets = {
      words = true,
      search = true,
      delete = true,
    },
    highlight = {
      hint = { fg = "#FFD700", bg = "#222222" },
      dim = "Comment",
    },
    keys = "fjdksleirughtynm",
  },
}
```

To disable certain presets:

```lua
presets = {
  words = { "w", "b" }, -- disables "w" and "b" word motions
}
```

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

> [!NOTE]
> 📖 For a complete list of presets and highlight keys, see [presets.md](/docs/presets.md) and [advanced.md](/docs/advanced.md)

---

## 🌊 Flow State: Smarter Navigation

SmartMotion introduces **Flow State**, enabling native-feeling chains of motion without repeated hinting.

Press `w`, see labels  press `w` again quickly  jump immediately. You're in flow.

Pressing another motion like `b` during flow seamlessly switches motion types.

> [!NOTE]
> 📖 Learn more in the [advanced usage guide](./docs/advanced.md#-flow-state-behavior)

---

## 💡 Highlight Customization

Every part of the label system can be styled.

Whether you want high-contrast backgrounds, colors that match your theme, or to pull from existing highlight groups - it's all supported.

```lua
highlight = {
  hint = { fg = "#FFD700", bg = "#222222" },
  dim = "Comment",
}
```

Supports both string references and highlight tables.

> [!NOTE]
> 📖 See full customization options in [advanced.md → Highlight Customization](./docs/advanced.md#-highlight-customization)

---

## Modular System

Each motion is built from pluggable pieces:

- **Collectors** (e.g., lines, buffers)
- **Extractors** (e.g., words, chars)
- **Filters** (e.g., visible only, directional)
- **Visualizers** (e.g., hints, overlays)
- **Actions** (e.g., jump, yank, delete, or merged)
- **Wrappers** (e.g., live search or text input modes)

You can even inject targets manually or build entire pipelines from scratch.

> [!NOTE]
> 📖 Read about custom wrappers, module contribution, and action merging in [advanced.md](./docs/advanced.md)

---

## 🎯 Presets

Presets let you quickly enable SmartMotion behaviors like word navigation, search, or delete:

```lua
presets = {
  words = true,
  search = true,
  delete = true,
}
```

> [!NOTE]
> 📖 See all available presets and options in [presets.md](./docs/presets.md)

---

## 🔬 What a Basic Motion Looks Like

```lua
w = {
  pipeline = {
    collector = "lines",
    extractor = "words",
    visualizer = "hint_start",
    filter = "default",
  },
  action = "jump",
  modes = { "n", "v" },
}
```

You can define your own motions with full control. Even combine actions like `jump + yank` with:

```lua
action = merge({ "jump", "yank" })
```

---

## 🙏 Acknowledgments

This plugin is only made possible by standing on the shoulders of giants. Inspiration and foundational ideas come from the incredible projects like:

- [`hop.nvim`](https://github.com/phaazon/hop.nvim)
- [`flash.nvim`](https://github.com/folke/flash.nvim)
- [`lightspeed.nvim`](https://github.com/ggandor/lightspeed.nvim)
- [`leap.nvim`](https://github.com/ggandor/leap.nvim)
- [`mini.jump`](https://github.com/echasnovski/mini.nvim#mini.jump)

The original concepts are all theirs - my hope is to bring their brilliant ideas together into one cohesive, extensible system.

---

## 📜 License

Licensed under [GPL-3.0](https://www.gnu.org/licenses/gpl-3.0.html).

---

## 👤 Author

Built by [FluxxField](https://github.com/FluxxField)
Business inquiries: [keenanjj13@protonmail.com](mailto:keenanjj13@protonmail.com)

> [!IMPORTANT]
> ✨ Also builds premium websites: [SLP Custom Built](https://www.slpcustombuilt.com), [Cornerstone Homes](https://www.cornerstonehomesok.com)

---

For full documentation, visit the [docs/](./docs) directory. Includes guides for:

- [Configuration](./docs/config.md)
- [Preset Setup](./docs/presets.md)
- [Custom Motions](./docs/custom_motion.md)
- [Advanced Usage](./docs/advanced.md)  _Highly recommended!_
