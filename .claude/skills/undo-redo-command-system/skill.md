---
name: undo-redo-command-system
description: Command pattern for graph undo/redo in the Rivet app
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/commands/*.ts`

Keywords: undo, redo, useCommand, CommandHistory, commandHistoryStack, redoStack

---

You are working on the **undo/redo command system** in `packages/app/src/commands/`.

## Key Files
- `packages/app/src/commands/Command.ts` — Core types, atoms, and `useCommand`/`useUndo`/`useRedo` hooks
- `packages/app/src/commands/editNodeCommand.ts` — Example with merge-within-window logic
- `packages/app/src/commands/addNodeCommand.ts` — Example with ID reuse on redo
- `packages/app/src/hooks/useCanvasHotkeys.ts` — Where `useUndo`/`useRedo` are wired to `Ctrl+Z`/`Ctrl+Y`

## Key Concepts
- **`Command<T, U>`**: Interface with `type: string`, `apply(data, appliedData, currentState): U`, `undo(data, appliedData, currentState): void`
- **`GraphCommandState`**: Snapshot of `nodes`, `connections`, `project`, `commandHistoryStack`, `graphId`, `editingNodeId` — populated at hook call time, not at execution time
- **Atoms**: `commandHistoryStackStatePerGraph` and `redoStackStatePerGraph` are both `Record<GraphId, CommandData<any,any>[]>`; keyed per graph
- **`useCommand(command)`**: Takes an inline command object, returns an executor `(data: T) => U`. Pushes to history and clears redo stack on each call
- **Redo reuses `appliedData`**: `apply()` receives non-undefined `appliedData` on redo — use it to restore stable IDs (e.g., `newNode.id = appliedData.id`)

## Critical Rules
- **`apply()` must return `U`** — this return value is stored as `appliedData` and handed to `undo()`. Missing or wrong return breaks undo
- **Commands call Jotai setters directly** (`useSetAtom` at hook level) — no dispatch/reducer pattern
- **`currentState` is stale by design**: it is captured when the React component renders, not when the command executes. Do not rely on it for up-to-date state inside setters; use the functional setter form `(prev) => ...` where freshness matters
- **Merge pattern** (see `editNodeCommand.ts:116-148`): to merge a new command with the previous one, `apply()` must manually pop the last entry from `commandHistoryStackStatePerGraph` before returning the merged `appliedData`; `useCommand` will then push the new entry
- **No-op when `graphId` is undefined** — all three atoms guard on `graphId`; commands silently do nothing if no graph is active

## References
- **Patterns:** `.claude/skills/packages/skill.md`

---
**Last Updated:** 2026-04-19
