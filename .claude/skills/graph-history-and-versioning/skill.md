---
name: graph-history-and-versioning
description: Undo/redo command history, git-based graph revisions, and graph navigation history in Rivet
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/commands/*.ts`
- `packages/app/src/hooks/useGraphRevisions.ts`
- `packages/app/src/hooks/useGraphHistoryNavigation.ts`
- `packages/app/src/hooks/useChooseHistoricalGraph.ts`
- `packages/app/src/hooks/useHistoricalNodeChangeInfo.ts`
- `packages/app/src/utils/ProjectRevisionCalculator.ts`
- `packages/app/src/components/GraphRevisionList.tsx`
- `packages/app/src/components/NodeChangesModal.tsx`

Keywords: historicalGraphState, commandHistoryStackStatePerGraph, useUndo, useRedo, useCommand, CalculatedRevision, viewingNodeChangesState, graphNavigationStackState

---

You are working on **graph history and versioning** in Rivet — three separate systems: command undo/redo, git-based revision history, and graph navigation history.

## Key Files
- `packages/app/src/commands/Command.ts` — `Command<T, U>` interface, `useCommand`, `useUndo`, `useRedo`, per-graph stacks
- `packages/app/src/state/graph.ts` — `historicalGraphState` (`CalculatedRevision | null`), `historicalChangedNodesState`, `isReadOnlyGraphState`
- `packages/app/src/state/graphBuilder.ts` — `viewingNodeChangesState` (NodeId for NodeChangesModal), `graphNavigationStackState`
- `packages/app/src/utils/ProjectRevisionCalculator.ts` — git-based `CalculatedRevision` with `projectBeforeRevision`, `projectAtRevision`, `changedGraphs`
- `packages/app/src/hooks/useGraphRevisions.ts` — `useGraphRevisions()`, `useProjectRevisions()`, `useHasGitHistory()`
- `packages/app/src/hooks/useChooseHistoricalGraph.ts` — loads a revision into view, sets `historicalGraphState` + `isReadOnlyGraphState`
- `packages/app/src/hooks/useHistoricalNodeChangeInfo.ts` — returns `{ changed: false } | { changed: true; before, after }` for a node

## Key Concepts
- **Command<T, U>:** Must implement `apply(data, appliedData, currentState)` returning `U` and `undo(data, appliedData, currentState)`. `appliedData` (return value of `apply`) is stored and passed back to `undo` — use it to stash IDs or prior values.
- **Per-graph undo stacks:** `commandHistoryStackStatePerGraph` and `redoStackStatePerGraph` are `Record<GraphId, CommandData[]>`. Adding a new command clears the redo stack for that graph.
- **Rapid edit merging:** Commands with the same type and target within a 5-second window are merged (overwrite `appliedData`), preventing undo explosion on slider/text edits.
- **Historical view is read-only:** Setting `historicalGraphState` automatically makes the graph read-only via `isReadOnlyGraphState`. Clear both to return to current.
- **`CalculatedRevision` combines adjacent git states:** `projectBeforeRevision` is the project before the commit, `projectAtRevision` is after. `useChooseHistoricalGraph` merges nodes from both so deleted nodes remain visible with change markers.

## Critical Rules
- New commands must go in `packages/app/src/commands/` and follow `Command<T, U>` — don't mutate graph state directly outside the Command pattern or undo breaks.
- `apply` must return a `U` that fully describes what changed (used verbatim by `undo`) — don't rely on current state being stable during undo.
- Never set `historicalGraphState` without also setting `isReadOnlyGraphState(true)` — the UI won't block edits otherwise.
- `viewingNodeChangesState` takes a `NodeId`, not a node object — the modal reads node data from `historicalGraphState`.

## References
- **Patterns:** `.claude/guidelines/graph-history-and-versioning/patterns.md`

---
**Last Updated:** 2026-04-19
