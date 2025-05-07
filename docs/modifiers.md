# Modifiers

Modifiers are pipeline modules that extend or enrich each target _after filtering but before visualization._ They are used to add _additional metadata_ to targets, which can influence how they are displayed, prioritized, or acted on.

Unlike filters (which include or exclude targets), modifiers _do not remove any targets_ -- they simply attach more data to them.

---

## When are Modifiers Used?

Modifiers are typically used:

- After collectors, extractors, and filters have finalized the raw target list.
- To compute or attach fields like distance, syntax info, weights, or context.
- Before visualizers run, so that visual display logic (like hint label ordering) can make smarter decisions

> [!NOTE]
> If you add new modifiers, you will have to expand the visualizers to be able to handle this new info.

---

## Built-in Modifier: `distance_metadata`

The `distance_metadata` modifier adds a `sort_weight` field to each target's `metadata`, based on it's _Manhattan distance_ from the current cursor position.

```lua
---@type SmartMotionModifierModuleEntry
local M = {}

function M.run(input_gen)
	return coroutine.create(function(ctx, cfg, motion_state)
		local cursor_row, cursor_col = ctx.cursor_line, ctx.cursor_col

		while true do
			local ok, target = coroutine.resume(input_gen, ctx, cfg, motion_state)
			if not ok or not target then break end

			local target_row = target.start_pos.row
			local target_col = target.start_pos.col

			local dist = math.abs(target_row - cursor_row) + math.abs(target_col - cursor_col)
			target.metadata = target.metadata or {}
			target.metadata.sort_weight = dist

			coroutine.yield(target)
		end
	end)
end

M.metadata = {
	label = "Distance Metadata",
	description = "Adds a `sort_weight` field to each target's metadata based on Manhattan distance from the cursor.",
	motion_state = {
		sort_by = "sort_weight", -- Used to specify what metadata key we sorting by
		sort_descending = false, -- Used to reverse the sort order of targets
	},
}

return M
```

---

## Using Metadata in the Visualizer

You can configure the visualizer to _sort targets by metadata fields_ by setting the following in your motion state:

```lua
motion_state.sort_by = "sort_weight"
```

> [!TIP]
> When you register a modifier, the `motion_state` set in the `metadata` will be used to populate the motions `motion_state` on initiation

This tells the visualizer to sort the targets by `target.metadata.sort_weight` before assigning hint labels.

If `sort_by` is not set, targets are used in their original order.

You can also control the _sort direction_ by setting `motion_state.sort_descending = true`. This reverses the sort so that targets with higher values appear first (e.g., furthest-form-cursor targets if sorting by distance).

Below is how the hint visualizer uses `sort_by` and `sort_descending` to order targets

```lua
if motion_state.sort_by then
	local sort_by_key = motion_state.sort_by
	local descending = motion_state.sort_descending == true

	table.sort(targets, function(a, b)
		local a_weight = a.metadata and a.metadata[sort_by_key] or math.huge
		local b_weight = b.metadata and b.metadata[sort_by_key] or math.huge

		if descending then
			return a_val > b_val
		else
			return a_weight < b_weight
		end
	end)
end
```

---

## Summary

- Modifiers enrich targets with _metadata_ (they do not filter)
- `distance_metadata` adds a `sort_weight` for proximity-based sorting
- To sort by metadata, set `motion_state.sort_by` to the metadata key
- To reverse the sort direction, use `motion_state.sort_descending = true`.
- Modifiers allow SmartMotion pipelines to adapt intelligently to context, UI, and motion history
