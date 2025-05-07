# SmartMotion.nvim Overview

Welcome to the SmartMotion documentation! This plugin is built around the idea that motions should be smart, modular, and composable — allowing you to move through your codebase like a pro with a system you can fully customize.

Below is a high-level summary of what each document covers and how it fits into the ecosystem.

---

## 📦 registering.md

Learn how to register your own motions and presets.

Covers:
- How motion definitions work
- How to register single or multiple motions
- is_action behavior for supporting native-style operations (like dw, ciw)
- Metadata and mapping options

➡️ View [registering.md](registering.md)

---

## ⚙️ presets.md

A guide to the built-in presets and how to use or customize them.

Covers:
- Available preset categories (words, lines, search, delete, yank, change)
- Enabling or excluding mappings
- Linking to the Presets Reference

➡️ View [presets.md](presets.md)

---

## 🧱 collectors.md

Collectors define the search range for your motion targets.

Covers:
- What a collector is and does
- Built-in collector options like lines
- Future ideas (e.g., multi-buffer collection)

➡️ View [collectors.md](collectors.md)

---

## 🔎 extractors.md

Extractors determine what kind of target you’re looking for.

Covers:
- Built-in extractors like words, chars, text_search
- Example use cases

➡️ View [extractors.md](extractors.md)

---

## 🧹 filters.md

Filters narrow down the targets returned by extractors.

Covers:
- Pass-through vs conditional filters
- Built-ins like default and filter_visible_lines
- Future support for direction-based filtering (e.g., AFTER_CURSOR)

➡️ View [filters.md](filters.md)

---

## 🎨 visualizers.md

Visualizers control how targets appear in the UI.

Covers:
- How hint labels are applied
- Smart dimming behavior
- Customization options

➡️ View [visualizers.md](visualizers.md)

---

## 🧠 actions.md

Actions define what happens when a user selects a target.

Covers:
- Built-in actions: jump, yank, delete, change, restore
- Using merge() to combine actions
- Creating custom actions

➡️ View [actions.md](actions.md)

---

## 🧪 pipeline_wrappers.md

Pipeline wrappers add runtime behavior like live search.

Covers:
- The difference between default, live_search, and text_search
- When and why to use each
- How wrappers control user interaction and reactivity

➡️ View [pipeline_wrappers.md](pipeline_wrappers.md)

---

## ✨ custom_motion.md

Step-by-step guide to building a custom motion from scratch.

Covers:
- Choosing a collector, extractor, visualizer, and action
- Optional filters and wrappers
- Registering it all together

➡️ View [custom_motion.md](custom_motion.md)

---

## 🚀 advanced.md

Explore deeper features like flow state and motion chaining.

Covers:
- Flow state and how SmartMotion mimics native feel
- Multi-target actions
- History and chaining logic

➡️ View [advanced.md](advanced.md)

---

## ⚙️ config.md

Describes the options available in setup({}).

Covers:
- Global config like keys, highlight, presets
- How to override highlight groups or provide custom colors

➡️ View [config.md](config.md)

---

## 🐞 debugging.md

Tips for testing and debugging your custom motions.

Covers:
- Visualizer debugging
- Logging with core.log
- Inspecting motion state manually

➡️ View [debugging.md](debugging.md)

---

Happy motion building!
