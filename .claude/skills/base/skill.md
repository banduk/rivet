---
name: base
description: Core conventions, tech stack, and project structure for rivet
---

## Activation

This is a **base skill** that always loads when working in this repository.

---

You are working in **rivet** — an open-source visual IDE and runtime for AI agent pipelines.

## Tech Stack
TypeScript (strict, ESM) | React 18 + Jotai + Vite + Tauri | Yarn 4 PnP | Node.js native test runner

## Commands
- `yarn` — install (Yarn 4 PnP — no `node_modules` dir)
- `yarn dev` — build app-executor then launch Tauri desktop app
- `yarn workspace @ironclad/rivet-app run dev` — Vite-only UI (no Tauri)
- `yarn build` — build all packages in dependency order
- `yarn test` — runs `@ironclad/rivet-core` tests only
- `yarn lint` — lint all packages
- `yarn prettier:fix` — format all files
- `yarn workspace @ironclad/rivet-core run test` — core tests via tsx
- `cd packages/core && npx tsx --test test/path/to/file.test.ts` — single test file

## Structure
- `packages/core/` — graph execution engine, all node types, plugin system (isomorphic)
- `packages/node/` — Node.js-specific runtime, MCP SDK, file system providers
- `packages/app/` — React+Tauri desktop UI; state via Jotai atoms
- `packages/app-executor/` — sidecar Node.js process that runs graphs for the UI via IPC
- `packages/cli/` — `rivet` CLI using Hono
- `packages/trivet/` — test framework for asserting graph outputs
- `packages/community/` — Next.js community template platform (GitHub OAuth, Vercel KV/Blob)
- `packages/core/src/model/nodes/` — all built-in node type implementations

## Critical Conventions
- **`.js` extensions in all imports** even when importing `.ts` files — `moduleResolution: bundler`/`node16` requirement; missing `.js` breaks the build
- **`import type`** for type-only imports — `verbatimModuleSyntax` is enforced; omitting causes compile errors
- **`lodash-es`** not `lodash` in core — isomorphic bundle requires tree-shaking; CJS build aliases at bundle time
- **`ts-pattern`** for exhaustive matching on discriminated unions in node processors
- **Tests use `node:test` + `node:assert`** — not Jest or Vitest
- **No circular imports** — enforced by ESLint `eslint-plugin-import`; violating causes ESM runtime failures
- Prettier: single quotes, trailing commas, 120-char line width

## Node Type Pattern
Each node file in `packages/core/src/model/nodes/` exports:
1. A `ChartNode<'type', DataType>` type alias
2. A `NodeImpl<T>` subclass with `static create()`, `getInputDefinitions()`, `getOutputDefinitions()`, `process()`, `getEditors()`, `getBody()`, `static getUIData()`
3. A `nodeDefinition(ImplClass, 'DisplayName')` call as default export

Built-in nodes access node data via `this.data`; plugin nodes use `PluginNodeImpl<T>` where `data` is the first arg. Register new node types in `packages/core/src/model/Nodes.ts`.

## Jotai State Pattern
- `graphState` (`atomWithStorage`) is the source of truth for the current graph
- `nodesState`, `connectionsState`, `graphMetadataState` are **bi-directional derived atoms** — use their setters, never mutate `graphState` directly
- Any atom reading `nodeInstancesState` must also `get(pluginRefreshCounterState)` to invalidate on plugin reload
- `ioDefinitionsState` wraps per-node errors and returns `[]`; IO definitions can always be absent

## Command Pattern
All graph mutations go through `useCommand()` hook — direct Jotai mutations bypass undo/redo history. `appliedData` is `undefined` on first apply; **cache all generated IDs in the return value** or redo creates duplicate IDs.

## DataValue System
Tagged union: `{ type: 'string', value: string }`. Call `unwrapDataValue()` before using in `process()` — function-typed values are lazy and must be called.

---
**Last Updated:** 2026-04-19
