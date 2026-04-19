---
name: auto-layout
description: Force-directed graph auto-layout algorithm and its wiring into the canvas
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/hooks/useAutoLayoutGraph.ts`
- `packages/app/src/components/NodeCanvas.tsx`
- `packages/app/src/hooks/useGraphBuilderContextMenuHandler.ts`
- `packages/app/src/hooks/useContextMenuConfiguration.ts`

Keywords: autoLayoutGraph, useAutoLayoutGraph, auto-layout, force-directed, layoutGraph

---

You are working on **auto-layout** in Rivet — a synchronous force-directed simulation that repositions all nodes in a graph.

## Key Files
- `packages/app/src/hooks/useAutoLayoutGraph.ts` — pure algorithm; returns a function `(graph: NodeGraph) => ChartNode[]` with final positions
- `packages/app/src/components/NodeCanvas.tsx:241-249` — calls `useAutoLayoutGraph`, stores trigger fn in `autoLayoutGraph` ref, calls `recalculatePortPositions` after applying
- `packages/app/src/hooks/useGraphBuilderContextMenuHandler.ts:93-95` — context-menu `'auto-layout'` id dispatches to `onAutoLayoutGraph()`
- `packages/app/src/hooks/useContextMenuConfiguration.ts:136` — registers `id: 'auto-layout'` menu item (`hiddenUntilSearched: true`)

## Key Concepts
- **Algorithm:** 300-iteration force-directed simulation (repulsion + spring attraction + center gravity + cooling). Runs fully synchronously — no streaming, no async.
- **Directional bias:** Output nodes are pushed LEFT of input nodes. `DIRECTIONAL_BIAS = 300`, `MIN_HORIZONTAL_DISTANCE = 400`. Violations trigger strong corrective forces (factor 0.8).
- **Node dimensions:** Width comes from `node.visualData.width || DEFAULT_NODE_WIDTH (200)`. Height is always fixed at `DEFAULT_NODE_HEIGHT = 200` — actual measured height is ignored.
- **Trigger pattern:** `NodeCanvas` exposes the layout fn via `autoLayoutGraph: MutableRefObject<() => void>` prop; `GraphBuilder` holds the ref and calls `.current()`.

## Critical Rules
- After applying positions via `setNodes(nodes)`, you **must** call `recalculatePortPositions()` — skipping it leaves port hitboxes misaligned.
- The algorithm mutates a local copy of nodes (immutable spreads); it does **not** write to Jotai atoms — the caller (`NodeCanvas`) does the `setNodes` call.
- Adding a new tunable constant: all physics params are module-level `const` at the top of `useAutoLayoutGraph.ts`. Do not inline magic numbers into the simulation loop.
- Context menu entry uses `hiddenUntilSearched: true` — it won't appear in the default right-click menu, only when the user searches.

## References
- **Patterns:** `.claude/skills/base/skill.md`

---
**Last Updated:** 2026-04-19
