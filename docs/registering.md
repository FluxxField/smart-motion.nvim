# Registering Motions and Presets

SmartMotion allows you to register new motions and actions using a flexible and powerful API. This file will walk you through:
	•	How motion registration works
	•	What options are available
	•	How to use is_action
	•	How to register multiple motions at once
	•	How presets work under the hood

⸻

## 🔧 Basic Motion Registration

To register a motion, use require("smart-motion").register_motion(key, opts).

Example:

require("smart-motion").register_motion("w", {
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
})



⸻

## ⚙️ Motion Options

Each motion supports the following fields:
	•	pipeline: defines the motion stages (collector, extractor, filter, visualizer)
	•	pipeline_wrapper: optional wrapper to control input/search behavior
	•	action: what to do when a target is selected (jump, delete, etc.)
	•	state: configuration like direction and hint positioning
	•	opts: extra data passed to extractors or wrappers (e.g. num_of_char)
	•	map: whether to create a keybinding for the motion
	•	modes: which modes the motion is active in (n, v, x, etc.)
	•	metadata: label and description for documentation/debugging

[!TIP]
Want to create a motion like dw? Use merge({ jump, delete }) as the action.

⸻

## 🧠 is_action and Smart Inference

If a motion is registered with is_action = true, it can act like d, y, or c in Vim. SmartMotion will:
	•	Infer the extractor from the next motion key (e.g., w, e, ))
	•	Run the selected motion as a child of the action

This allows you to do things like:

dw → delete to next word
ciw → change inner word

Without manually registering every combination.

⸻

## 🧵 Registering Multiple Motions

You can register a group of motions at once using:

require("smart-motion").register_many_motions({
  w = { ... },
  e = { ... },
  ge = { ... },
})

This is used internally by the presets system.

⸻

## 🧙 How Presets Work

Presets call register_many_motions() under the hood. Each preset (like words, search, or yank) defines a set of mappings that you can include, exclude, or override.

See presets.md for a full breakdown of each available preset.

⸻

For more advanced motion building, check out:
	•	custom_motion.md
	•	actions.md
	•	pipeline_wrappers.md