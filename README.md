```
   _____                      __  __  ___      __  _                          _         
  / ___/____ ___  ____ ______/ /_/  |/  /___  / /_(_)___  ____    ____ _   __(_)___ ___ 
  \__ \/ __ `__ \/ __ `/ ___/ __/ /|_/ / __ \/ __/ / __ \/ __ \  / __ \ | / / / __ `__ \
 ___/ / / / / / / /_/ / /  / /_/ /  / / /_/ / /_/ / /_/ / / / / / / / / |/ / / / / / / /
/____/_/ /_/ /_/\__,_/_/   \__/_/  /_/\____/\__/_/\____/_/ /_(_)_/ /_/|___/_/_/ /_/ /_/ 
                                                                                        
```

# SmartMotion.nvim - Home-row powered smart motions for Neovim

## 📖 What is SmartMotion?

`SmartMotion.nvim` is a motion plugin for Neovim that brings **intuitive, home-row driven navigation** to your code. Forget counting words or characters — SmartMotion instantly highlights jump targets **with dynamic, in-place labels**, allowing you to navigate faster and more naturally.

SmartMotion is part of my personal War on Counting. I believe motions in Neovim should be about intent, not arithmetic. Why count words, characters, or lines when your editor can show you the way? This philosophy drives not only word motions, but my future plans to enhance commands like dt and ct — so instead of typing dt; or dt) and mentally counting, you just jump directly to the desired target.

---

## 🚀 Why SmartMotion? (What Makes Us Different)

SmartMotion takes the **best ideas from plugins like Hop.nvim and EasyMotion**, and layers on:

- 🔦 **Smart Label Generation:** Dynamically chooses between single-character and double-character labels based on target density.
- 🔦 **Dynamic Highlight Feedback:** After selecting the first character in a double hint, SmartMotion dims the first and highlights the second.
- 🛠️ **Zero Default Mappings:** You control how and when SmartMotion activates — no keybinding conflicts.
- 🔄 **Expandable Architecture:** Currently being built to support future motions like `f`, `t`, paragraph, line, and operator motions.

---

## 📃 Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Exposed Methods](#exposed-methods)
- [Example Mappings](#example-mappings)
- [Roadmap](#roadmap)
- [Similar Plugins](#similar-plugins)
- [Other Plugins By Me](#other-plugins-by-me)
- [Shameless Plug](#shameless-plug)

---

## ✨ Features

- Home-row powered jump hints
- Single & double character label support
- Dynamic feedback highlighting
- Multi-line support
- No default mappings — you are in control
- Works with `w`, `b`, `e`, `ge` out of the box
- Smart label generation
- No dependencies — pure Lua

---

## 💳 Installation

### lazy.nvim

```lua
{
    "FluxxField/smart-motion.nvim",
    config = function()
        require("smart-motion").setup()
    end
}
```

---

## 🛠️ Configuration

```lua
require("smart-motion").setup({
    keys = "fjdksleirughtynm",
    highlight = {
        dim = "SmartMotionDim",
        hint = "SmartMotionHint",
        first_char = "SmartMotionFirstChar",
        second_char = "SmartMotionSecondChar",
        first_char_dim = "SmartMotionFirstCharDim",
    },
})
```

---

## 🔹 Important Callout: No Default Mappings

SmartMotion does not register any mappings by default. You must define your own. Example:

```lua
return {
  "FluxxField/smart-motion.nvim",
  lazy = false,
  config = function()
    local smart_motion = require "smart-motion"
    local DIRECTION = smart_motion.consts.DIRECTION
    local HINT_POSITION = smart_motion.consts.HINT_POSITION

    smart_motion.setup {
      mappings = {
        n = {
          w = {
            function() require("smart-motion").hint_words(DIRECTION.AFTER_CURSOR, HINT_POSITION.START, true) end,
            desc = "smart-motion forward word",
          },
          b = {
            function() require("smart-motion").hint_words(DIRECTION.BEFORE_CURSOR, HINT_POSITION.START, true) end,
            desc = "smart-motion backward word",
          },
          e = {
            function() require("smart-motion").hint_words(DIRECTION.AFTER_CURSOR, HINT_POSITION.END, true) end,
            desc = "smart-motion forward to word end",
          },
          ge = {
            function() require("smart-motion").hint_words(DIRECTION.BEFORE_CURSOR, HINT_POSITION.END, true) end,
            desc = "smart-motion backward to word end",
          },
        },
        v = {},
      },
    }
  end,
}
```

---

🎨 Important Callout: Flexible Highlight Configuration

You can configure how SmartMotion highlights its hints in two ways:

1️⃣ Reference Existing Highlight Groups (Default)

This is the easiest way — you can point to existing highlight groups (like SmartMotionHint).

```lua
highlight = {
    dim = "SmartMotionDim",
    hint = "SmartMotionHint",
    first_char = "SmartMotionFirstChar",
    second_char = "SmartMotionSecondChar",
    first_char_dim = "SmartMotionFirstCharDim",
}
```

2️⃣ Directly Define Colors (Power User Option)

You can also pass highlight definitions directly if you want full control.

```lua
highlight = {
    dim = { fg = "#5C6370", bg = "none" },
    hint = { fg = "#E06C75", bg = "none" },
    first_char = { fg = "#98C379", bg = "none" },
    second_char = { fg = "#61AFEF", bg = "none" },
    first_char_dim = { fg = "#6F8D57", bg = "none" },
}
```

This makes SmartMotion extremely flexible and allows it to seamlessly fit into any colorscheme.

---

## 🎮 Exposed Methods

| Method                            | Description                      |
| --------------------------------- | -------------------------------- |
| `hint_words(direction, position)` | Word jump motion                 |

---

## 🌆 Roadmap

- New methods for characters, lines and more
- Character motions (`f`, `t`, `F`, `T`)
- Operator support (`d`, `c`, `y`)
- Configurable timeout between double-char hints
- Paragraph & block motions
- Advanced label tuning

---

## 🔗 Similar Plugins

| Plugin                                            | Notes              |
| ------------------------------------------------- | ------------------ |
| [Hop.nvim](https://github.com/phaazon/hop.nvim)   | Big inspiration    |
| [leap.nvim](https://github.com/ggandor/leap.nvim) | 2-char quick jumps |

---

## 🛠️ Other Plugins By Me

| Plugin                                                                   | Description                   |
| ------------------------------------------------------------------------ | ----------------------------- |
| [bionic-reading.nvim](https://github.com/FluxxField/bionic-reading.nvim) | Syllable-based bionic reading |

---

## 💼 Shameless Plug

I also build custom websites for businesses, startups, and personal brands! If you want:

- Stunning design & performance
- Modern, SEO-optimized tech
- Built using Next.js, Astro, or tailored to your stack

Check out:

- [Cornerstone Homes](https://www.cornerstonehomesok.com)
- [SLP Custom Built](https://www.slpcustombuilt.com)

📧 Contact me at: [keenanjj13@protonmail.com](mailto:keenanjj13@protonmail.com)

---

## 🏆 License

GNU GENERAL PUBLIC LICENSE
Version 3, 29 June 2007

Copyright (C) 2025 FluxxField

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.

---

## ✨ Author

Built with ❤️ by [FluxxField](https://github.com/FluxxField)
