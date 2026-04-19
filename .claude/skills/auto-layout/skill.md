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
- `packages/app/src/hooks/useAiGraphBuilder.ts:59` — second call site: calls `autoLayout(workingGraph)` directly then `setGraph`/`centerView` — no ref, no `recalculatePortPositions`

## Key Concepts
- **Algorithm:** 300-iteration force-directed simulation (repulsion + spring attraction + center gravity + cooling). Runs fully synchronously — no streaming, no async.
- **Initial placement:** BFS assigns nodes to layers before simulation; layer × `DIRECTIONAL_BIAS (300)` seeds x-position. Source nodes (no incoming edges) go to layer 0.
- **Directional bias:** Output nodes are pushed LEFT of input nodes. `DIRECTIONAL_BIAS = 300`, `MIN_HORIZONTAL_DISTANCE = 400`. Violations trigger strong corrective forces (factor 0.8).
- **Node dimensions:** Width comes from `node.visualData.width || DEFAULT_NODE_WIDTH (200)`. Height is always fixed at `DEFAULT_NODE_HEIGHT = 200` — actual measured height is ignored.
- **Trigger pattern (manual):** `NodeCanvas` exposes the layout fn via `autoLayoutGraph: MutableRefObject<() => void>` prop; `GraphBuilder` holds the ref and calls `.current()` from the context-menu handler.
- **Trigger pattern (AI builder):** `useAiGraphBuilder` calls `useAutoLayoutGraph()` directly and applies positions inline — bypasses the ref and `recalculatePortPositions`.

## Critical Rules
- After `setNodes(nodes)` in `NodeCanvas`, you **must** call `recalculatePortPositions()` — skipping it leaves port hitboxes misaligned. (The AI builder path skips this intentionally — centerView triggers a re-render that recalculates.)
- The algorithm returns a new array of nodes (immutable spreads); it does **not** write to Jotai atoms — the caller does the `setNodes`/`setGraph` call.
- All physics params are module-level `const` at the top of `useAutoLayoutGraph.ts`. Never inline magic numbers into the simulation loop.
- Context menu entry uses `hiddenUntilSearched: true` — it only appears when the user types in the right-click search box, not in the default menu.

## References
- **Patterns:** `.claude/skills/base/skill.md`

---
**Last Updated:** 2026-04-19
