---
name: graph-execution-ui
description: Graph execution state, node status display, run controls, and output rendering in the Rivet UI
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/state/dataFlow.ts`
- `packages/app/src/state/execution.ts`
- `packages/app/src/hooks/useGraphExecutor.ts`
- `packages/app/src/hooks/useLocalExecutor.ts`
- `packages/app/src/hooks/useRemoteExecutor.ts`
- `packages/app/src/hooks/useCurrentExecution.ts`
- `packages/app/src/components/ActionBar.tsx`
- `packages/app/src/components/NodeOutput.tsx`
- `packages/app/src/components/GraphExecutionSelectorBar.tsx`
- `packages/app/src/components/VisualNode.tsx`

Keywords: graphRunningState, lastRunDataByNodeState, useGraphExecutor, useLocalExecutor, useCurrentExecution, ProcessDataForNode, splitOutputData, selectedProcessPage

---

You are working on **graph execution UI** in Rivet — the system that runs graphs, tracks per-node execution state, and renders results.

## Key Files
- `packages/app/src/state/dataFlow.ts` — all execution state atoms (`graphRunningState`, `graphPausedState`, `lastRunDataByNodeState`, `runningGraphsState`, `rootGraphState`, `selectedProcessPageNodesState`)
- `packages/app/src/hooks/useCurrentExecution.ts` — processes all `GraphProcessor` events into state atoms; single source of truth for transitions
- `packages/app/src/hooks/useGraphExecutor.ts` — routes to `useLocalExecutor` or `useRemoteExecutor` based on `selectedExecutorState`
- `packages/app/src/hooks/useLocalExecutor.ts` — attaches `GraphProcessor` event listeners; implements run-to-node, run-from-node
- `packages/app/src/hooks/useRemoteExecutor.ts` — mirrors local API but sends WebSocket messages to remote debugger
- `packages/app/src/components/ActionBar.tsx` — play/pause/stop controls; reads `graphRunningState`+`graphPausedState`
- `packages/app/src/components/NodeOutput.tsx` — renders output data; includes process page picker for history navigation
- `packages/app/src/components/GraphExecutionSelectorBar.tsx` — navigates between execution runs globally

## Key Concepts
- **`ProcessDataForNode[]`:** Each node stores an array of runs (multiple executions accumulate). Status is `'ok' | 'error' | 'running' | 'interrupted' | 'notRan'`.
- **`selectedProcessPageNodesState`:** `Record<NodeId, number | 'latest'>` — controls which run index the UI shows per node; "latest" always tracks newest.
- **Split-run nodes:** `splitOutputData` is indexed by execution index (set via `onPartialOutput`), not a single output object.
- **Memory optimization:** Large binary values (images, audio) are converted to refs via `convertToRef()` and stored in a global ref store — only refs live in Jotai atoms.
- **Nested graphs:** `runningGraphsState` is an array (stack); `graphStart`/`graphFinish` push/pop. `rootGraphState` is always the top-level graph.

## Critical Rules
- `onStart` clears ALL previous `lastRunDataByNodeState` — each graph run completely replaces history (except during Trivet test runs).
- Do NOT read `lastRunDataByNodeState` directly for a single node — use the `lastRunDataState` atomFamily instead: `lastRunDataState(nodeId)`.
- `useGraphExecutor` returns `{ tryRunGraph, tryAbortGraph, tryPauseGraph, tryResumeGraph, tryRunTests }` — always use these, never call the processor directly from components.
- Node CSS classes in `VisualNode.tsx` derive from status: `success` → ok, `error` → error, `running` → running, `not-ran` → notRan. Don't add new status values without updating both the atom type and CSS.
- `previousDataPerNodeToKeepState` controls history depth — don't assume unlimited history exists.

## References
- **Patterns:** `.claude/skills/packages/skill.md`

---
**Last Updated:** 2026-04-19
