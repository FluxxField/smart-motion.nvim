```
   _____                      __  __  ___      __  _                          _         
  / ___/____ ___  ____ ______/ /_/  |/  /___  / /_(_)___  ____    ____ _   __(_)___ ___ 
  \__ \/ __ `__ \/ __ `/ ___/ __/ /|_/ / __ \/ __/ / __ \/ __ \  / __ \ | / / / __ `__ \
 ___/ / / / / / / /_/ / /  / /_/ /  / / /_/ / /_/ / /_/ / / / / / / / / |/ / / / / / / /
/____/_/ /_/ /_/\__,_/_/   \__/_/  /_/\____/\__/_/\____/_/ /_(_)_/ /_/|___/_/_/ /_/ /_/ 
                                                                                        
```

# SmartMotion.nvim - Home-row powered smart motions for Neovim

## 📚 What is SmartMotion?

`SmartMotion.nvim` brings **intuitive, home-row driven navigation** to Neovim. Forget counting words or characters — SmartMotion instantly highlights jump targets **with dynamic, in-place labels**, letting you move faster and more intuitively.

SmartMotion exists to end what I call the **War on Counting**. Why count words or characters when your editor can show you exactly where to jump? This philosophy drives not only word motions, but future plans for commands like `dt`, `ct`, and others.

---

## 🚀 Why SmartMotion?

Other motion plugins (like Hop and EasyMotion) are great but often:

- Replace core motions entirely, breaking muscle memory.
- Make you choose between 'normal' and 'smart' motions.
- Feel sluggish when you just want to spam `w`, `e`, or `b`.

SmartMotion fixes all of that with **Flow-State Chaining**.

---

## 🔗 Credits & Inspiration

SmartMotion builds on the great work from:

- [Hop.nvim](https://github.com/phaazon/hop.nvim) — original home-row hints.
- [EasyMotion](https://github.com/easymotion/vim-easymotion) — fast jump pioneer.

---

## 🔆 Features

🔢 Home-row powered hints  
🔢 Single & double character labels (adaptive)  
🔢 Dynamic feedback highlighting  
🔢 Multi-line support  
🔢 Works seamlessly with `w`, `b`, `e`, `ge`  
🔢 Smart label generation  
🔢 No default mappings (full control)  
🔢 Pure Lua, no dependencies  
🔢 Flow-state chaining preserves natural spamming

---

# 🔥 Flow-State & Motion Chaining — SmartMotion's Superpower

SmartMotion is the first motion plugin with **true flow-state chaining**:

- Remap `w`, `b`, `e`, `ge` to SmartMotion.
- Get smart hints when you pause.
- Keep native fast-repeat spamming if you hold the key.

This makes SmartMotion feel like a natural upgrade instead of a takeover.

---

## 🗃 Installation

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
    multi_line = true,
    mappings = {
        n = {},
        v = {}
    },
})
```

---

## 📌 Example Mappings (Flow-State in Action)

```lua
local smart_motion = require "smart-motion"
local DIRECTION = smart_motion.consts.DIRECTION
local HINT_POSITION = smart_motion.consts.HINT_POSITION

require("smart-motion").setup {
    mappings = {
        n = {
            w = { function() smart_motion.hint_words(DIRECTION.AFTER_CURSOR, HINT_POSITION.START) end },
            b = { function() smart_motion.hint_words(DIRECTION.BEFORE_CURSOR, HINT_POSITION.START) end },
            e = { function() smart_motion.hint_words(DIRECTION.AFTER_CURSOR, HINT_POSITION.END) end },
            ge = { function() smart_motion.hint_words(DIRECTION.BEFORE_CURSOR, HINT_POSITION.END) end },
        },
    }
}
```

---

## 🌟 Exposed Methods

| Method                            | Description                      |
| --------------------------------- | -------------------------------- |
| `hint_words(direction, position)` | Word jump motion                 |

---

## 🔄 Roadmap

- Character motions (`f`, `t`, etc.)
- Operator support (`d`, `c`, `y`)
- Timeout tuning for double-char hints
- Paragraph & block motions
- Advanced label customization

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

