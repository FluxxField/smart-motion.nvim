# SmartMotion Roadmap

## Phase 1: Solidify `hint_words` (v0.1.0)

### Goals
- Convert to streaming generator pipeline.
- Add flow state for basic chaining.
- Ensure performance is solid.

### Key Tasks
- Refactor `get_targets` into `target_collector`.
- Refactor `get_labels` into `label_generator`.
- Apply labels immediately in a streaming loop.
- Add basic `flow_state` to track first target.
- Test edge cases: wrapped words, punctuation, buffer edges.

---

## Phase 2: Add Full Flow State (v0.2.0)

### Goals
- Expand `flow_state` to store all jumps across motions.
- Add `:SmartMotionHistory` to review jump history.
- Add `replay()` to jump directly to any past target.
- Make chaining work across different motions.

---

## Phase 3: Core Motions (v0.3.0)

### Goals
- Add `hint_lines` and `hint_chars`.
- Ensure all core motions support chaining and spam detection.

---

## Phase 4: Framework Refactor (v1.0.0)

### Goals
- Convert all motions to registered motions.
- Add `register_motion()` for custom motions.
- Split into modular folders (collectors, labels, display, actions).
- Document the SmartMotion DSL.

---

## Phase 5: Telescope Integration (v1.1.0)

### Goals
- Add Telescope collectors & display handlers.
- Enable file, buffer, symbol jumping via Telescope.
- SmartMotion powers Telescope selections via labels.

---

## Phase 6: Advanced Motions (v1.2.0+)

### Completed
- ✅ Treesitter-aware motions (function/class navigation, argument editing, function name editing)
- ✅ Jump to LSP Diagnostics (with severity filtering)
- ✅ Paste motions
- ✅ Range-based actions (`resolve_range` for delete/yank/change/until variants)

### Ideas (Remaining)
- Jump to Git Conflicts.
- Search & Replace with Hints.
- History review with labels.
