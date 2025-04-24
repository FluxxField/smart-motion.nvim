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



---

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

---

# 🧠 is_action and Trigger Behavior

When registering a motion, the is_action flag controls how the dispatcher interprets the first keypress:
	•	If is_action = false (default), the motion key is the motion itself.
	•	If is_action = true, the key is treated as a trigger for an action, and the next key determines the motion to apply the action to.

This distinction is handled by the dispatcher:
	•	A trigger motion runs a complete motion pipeline directly
	•	A trigger action captures the next motion key, resolves it, then runs the pipeline and applies the action on top

Example:

-- `d` is registered as an action:
require("smart-motion").register_motion("d", {
  is_action = true,
  action = "delete",
})

Now:

dw → means "delete to the next word"
dt) → means "delete until ')'"

SmartMotion will:
	1.	Capture the w or t motion based on the next key
	2.	Resolve its motion definition
	3.	Run the pipeline for that motion
	4.	Apply the action (delete) on the result

[!IMPORTANT]
When is_action is enabled, SmartMotion uses internal lookup to resolve the next motion. This enables native-like operator behavior without requiring you to register dw, de, d) manually.

[!NOTE]
Under the hood, the first key (the trigger) looks up a registered action, and the second key (the motion key) is used to look up the corresponding extractor.

However, this logic assumes the second key is a valid motion key — which is not always guaranteed. The methodology may evolve to support more flexible parsing.

---

## 🧵 Registering Multiple Motions

You can register a group of motions at once using:

require("smart-motion").register_many_motions({
  w = { ... },
  e = { ... },
  ge = { ... },
})

This is used internally by the presets system.

---

## 🧙 How Presets Work

Presets call register_many_motions() under the hood. Each preset (like words, search, or yank) defines a set of mappings that you can include, exclude, or override.

See presets.md for a full breakdown of each available preset.

---

For more advanced motion building, check out:
	•	custom_motion.md
	•	actions.md
	•	pipeline_wrappers.md