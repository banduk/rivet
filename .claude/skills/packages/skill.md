---
name: packages
description: Node implementations, Command pattern, state atoms, DataValue system, and dual ESM/CJS build for rivet packages
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/model/nodes/*.ts`
- `packages/core/src/model/NodeImpl.ts`
- `packages/core/src/model/DataValue.ts`
- `packages/app/src/commands/*.ts`
- `packages/app/src/state/*.ts`
- `packages/core/bundle.esbuild.ts`

Keywords: NodeImpl, nodeDefinition, DataValue, ChartNode, GraphProcessor, useCommand, atomWithStorage, nodesState

---

## Node Implementation Pattern (`packages/core`)

Each node: one file in `src/model/nodes/`, default export via `nodeDefinition(ImplClass, 'DisplayName')`.

**Built-in nodes** extend `NodeImpl<T>` (abstract class). Methods access node data via `this.data`:
- `static create()`, `static getUIData()` — required statics
- `getInputDefinitions(connections, nodes, project, referencedProjects)` — 4 args, no `data`
- `getOutputDefinitions(connections, nodes, project, referencedProjects)`
- `process(inputData, context): Promise<Outputs>` — `Outputs = Record<portId, DataValue>`

**Plugin nodes** use `PluginNodeImpl<T>` interface instead — methods receive `data` as first arg.

- `getInputDefinitions()` is **data-driven** — TextNode parses `{{variable}}` from its text to emit ports dynamically. Port `id` must match extracted name exactly or UI ports break.
- `getEditors()` `dataKey` must exactly match keys in the node's data struct or editor mutations silently fail.
- Register new node types in `packages/core/src/model/Nodes.ts` (import + `export *`) and call `.register()` on the global registry.

## DataValue System (`packages/core/src/model/DataValue.ts`)

Tagged union: `{ type: 'string', value: string }`. Array types append `[]` (`'string[]'`); function types prefix `fn<>` (`'fn<string>'`).

- Call `unwrapDataValue()` before using a value in `process()` — function-typed values must be called.
- `arrayizeDataValue()` normalizes scalar or array to array.
- Adding new scalar types requires entries in **both** `dataTypes` exhaustive tuple and `scalarDefaults` map or defaults return `undefined`.

## Command Pattern (`packages/app/src/commands/`)

`Command<T, U>` interface: `apply(data, appliedData | undefined, currentState): U`; `undo(data, appliedData, currentState): void`.

- `appliedData` is `undefined` on first apply, populated on redo — **cache all generated IDs in the return value** (e.g. `newNode.id = appliedData.id` on redo) or redo creates duplicate IDs.
- Read current graph state from `currentState` (GraphCommandState), not stale closures.
- Always go through `useCommand()` hook; direct Jotai mutations bypass undo history.

## App State — Jotai Atoms (`packages/app/src/state/`)

- `graphState` (`atomWithStorage`) is the source of truth. `nodesState`, `connectionsState`, `graphMetadataState` are **bi-directional derived atoms** — use their setters, never mutate `graphState` directly.
- `nodeInstancesState` reads `pluginRefreshCounterState` to invalidate on plugin reload — custom atoms depending on node instances must also read it.
- `ioDefinitionsState` wraps per-node errors and returns empty arrays; don't assume IO is always populated.

## Dual ESM/CJS Build (`packages/core/bundle.esbuild.ts`)

- ESM: `tsc -b` → `dist/esm/` (unbundled) + `dist/types/`.
- CJS: esbuild → `dist/cjs/bundle.cjs`. Uses `packages: 'external'` plus **module aliases**: `lodash-es→lodash`, `p-queue→p-queue-6`, `emittery→emittery-0-13`, `p-retry→p-retry-4`. Both old and new versions must be in `dependencies`.
- Build order: ESM first (generates types), then CJS. `files` in `package.json` must include all three `dist/` folders.

## References
- **Patterns:** `.claude/guidelines/packages/patterns.md`

---
**Last Updated:** 2026-04-19
