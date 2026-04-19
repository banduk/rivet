---
name: factor-into-subgraph
description: Extract selected nodes into a new subgraph with auto-generated Graph Input/Output boundary nodes
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/hooks/useFactorIntoSubgraph.ts`
- `packages/app/src/hooks/useContextMenuConfiguration.ts`
- `packages/app/src/hooks/useGraphBuilderContextMenuHandler.ts`

Keywords: factor-into-subgraph, nodes-factor-into-subgraph, useFactorIntoSubgraph, Create Subgraph

---

You are working on **factor-into-subgraph** — the "Create Subgraph" context menu action that extracts selected nodes into a new `NodeGraph` and navigates to it.

## Key Files
- `packages/app/src/hooks/useFactorIntoSubgraph.ts` — all logic: boundary analysis, node copying, auto-generated input/output nodes, graph navigation
- `packages/app/src/hooks/useGraphBuilderContextMenuHandler.ts` — wires context menu id `'nodes-factor-into-subgraph'` to `useFactorIntoSubgraph()`
- `packages/app/src/hooks/useContextMenuConfiguration.ts` — declares the menu item; guarded by `conditional: () => selectedNodeIds.length > 0`
- `packages/app/src/hooks/useLoadGraph.ts` — called at the end to navigate to the new graph (saves current graph first)

## Key Concepts
- **Boundary detection:** A connection crosses the boundary when one endpoint is in `selectedNodeIds` and the other is not. Inputs = connections where `inputNodeId` is selected but `outputNodeId` is not. Outputs = reverse.
- **Dedup key:** `${outputNodeId}/${outputId}` — multiple connections from the same source port share one `GraphInputNode`. Tracked via `createdInputConnections` / `createdOutputConnections` Sets.
- **Name collision:** Input/output port names deduplicated by appending `_` until unique.
- **Node ID remapping:** Every copied node gets a new `nanoid()` id. `nodeIdLookup: Record<NodeId, NodeId>` maps old → new for reconnecting internal connections.
- **Port conventions:** `GraphInputNode` output port id = `'data'`; `GraphOutputNode` input port id = `'value'`. Hard-coded in the connection builder.
- **Visual placement:** Input nodes placed at `minX - 500`; output nodes at `maxX + 500`; stacked 200px apart vertically.
- **`getInputDefinitionsIncludingBuiltIn` / `getOutputDefinitions`:** Called via `globalRivetNodeRegistry.createDynamicImpl(node)` to resolve port types — required to determine `dataType` for boundary nodes.

## Critical Rules
- Call `loadGraph(newGraph)` (not `setGraph` directly) — it saves the current graph first and updates the navigation history stack.
- `emptyNodeGraph()` (from `@ironclad/rivet-core`) must be used to initialize the new graph — it sets a fresh `metadata.id` via `uuid`.
- `GraphInputNodeImpl.create()` / `GraphOutputNodeImpl.create()` are the only correct ways to instantiate boundary nodes; do not construct raw node objects.
- `uniqBy(allInputs, 'id')` runs before naming — always dedup before assigning names.
- The hook returns a `useStableCallback` — never call it conditionally or inline.

## References
- **Patterns:** `.claude/skills/base/skill.md`

---
**Last Updated:** 2026-04-19
