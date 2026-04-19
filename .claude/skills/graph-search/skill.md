---
name: graph-search
description: Fuzzy node search within a single graph and cross-graph project search
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/hooks/useSearchGraph.ts`
- `packages/app/src/hooks/useSearchProject.ts`
- `packages/app/src/hooks/useFuseSearch.ts`
- `packages/app/src/components/NavigationBar.tsx`

Keywords: useFuseSearch, useSearchGraph, useSearchProject, searchingGraphState, goToSearchState, searchMatchingNodeIds

---

You are working on **graph-search** in Rivet — two separate search flows powered by Fuse.js.

## Key Files
- `packages/app/src/hooks/useFuseSearch.ts` — generic Fuse.js hook; all search goes through here
- `packages/app/src/hooks/useSearchGraph.ts` — in-graph search; writes matching IDs to `searchMatchingNodeIdsState`, then calls `useFocusOnNodes`
- `packages/app/src/hooks/useSearchProject.ts` — cross-graph "Go To" search; returns `SearchedItem[]` with `containerGraph: GraphId`
- `packages/app/src/state/graphBuilder.ts:75` — `searchingGraphState` `{ searching, query }` and `goToSearchState` `{ searching, query, selectedIndex, entries }`; `searchMatchingNodeIdsState: NodeId[]`
- `packages/app/src/components/NavigationBar.tsx` — renders search UI; owns `goToSearchState` writes and `GoToSearchResults` component

## Key Concepts
- **Two modes:** `searchingGraphState` drives in-canvas highlight (via `useSearchGraph` called in `NodeCanvas`). `goToSearchState` drives the "Go To" panel (via `useSearchProject` in `NavigationBar`).
- **`useFuseSearch` options:** `noInputEmptyList: true` means empty query returns `[]`, not all items. `enabled: false` bypasses Fuse entirely and returns all items (useful for narrowing lists). Default `threshold: 0.2`, `ignoreLocation: true`.
- **Searchable fields per node:** `title`, `description`, `joinedData` (all `node.data` values joined as strings), `nodeType` (display name via `globalRivetNodeRegistry.getDisplayName`). Unknown node types produce an empty `nodeType`.
- **`useDependsOnPlugins()`** must be called in any hook that uses `globalRivetNodeRegistry` display names — plugins extend the registry at runtime.

## Critical Rules
- `useSearchGraph` is invoked as a side-effect hook inside `NodeCanvas` — it must not return values; it writes to atoms directly.
- `useSearchProject` is a value-returning hook — callers own writing results to `goToSearchState.entries`.
- Never call `useFuseSearch` without memoizing the `list` argument — the hook uses `useEffect` on `list` reference equality to call `fuse.setCollection`.

## References
- **Patterns:** `.claude/skills/base/skill.md`

---
**Last Updated:** 2026-04-19
