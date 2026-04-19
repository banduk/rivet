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
- `yarn build` — build all packages in dependency order
- `yarn test` — runs `@ironclad/rivet-core` tests only
- `yarn lint` — lint all packages
- `yarn prettier:fix` — format all files
- `yarn workspace @ironclad/rivet-core run test` — run core tests
- `cd packages/core && npx tsx --test test/path/to/file.test.ts` — single test file
- `yarn workspace @ironclad/rivet-app run dev` — Vite-only (no Tauri)

## Structure
- `packages/core/` — graph execution engine, all node types, plugin system (isomorphic)
- `packages/node/` — Node.js-specific runtime, MCP SDK integration
- `packages/app/` — React+Tauri desktop UI; state via Jotai atoms
- `packages/app-executor/` — sidecar process that actually runs graphs for the UI
- `packages/cli/` — `rivet` CLI using Hono
- `packages/trivet/` — test framework for asserting graph outputs
- `packages/community/` — Next.js app for community templates (GitHub auth via next-auth, Vercel KV/Blob)
- `packages/docs/` — Docusaurus documentation site
- `packages/core/src/model/nodes/` — all built-in node type implementations

## Critical Conventions
- **`.js` extensions in all imports**, even when importing `.ts` files — `moduleResolution: bundler`/`node16` requirement
- **`import type`** for type-only imports — `verbatimModuleSyntax` is enforced
- **`lodash-es`** not `lodash` in core (tree-shaking for isomorphic bundle)
- **`ts-pattern`** for exhaustive matching on discriminated unions in node processors
- **Tests use `node:test` + `node:assert`** — not Jest or Vitest
- **No circular imports** — enforced by ESLint `eslint-plugin-import`
- Prettier: single quotes, trailing commas, 120-char line width

## Node Type Pattern
Each node file in `packages/core/src/model/nodes/` exports:
1. A `ChartNode<'type', DataType>` type alias
2. A `NodeImpl<T>` subclass with `static create()`, `getInputDefinitions()`, `getOutputDefinitions()`, `process()`, `getEditors()`, `getBody()`, `static getUIData()`
3. A `nodeDefinition(ImplClass, 'DisplayName')` call as the default export

`DataValue` is the unit of data: `{ type: 'string', value: '...' }` tagged unions. Use `coerceTypeOptional()` to convert between types in `process()`.

## Build System
- ESM: `tsc -b` → `dist/esm/` + `dist/types/`
- CJS: `esbuild` via `bundle.esbuild.ts` → `dist/cjs/bundle.cjs`
- All published packages (`core`, `node`, `trivet`, `cli`) ship dual ESM/CJS

---
**Last Updated:** 2026-04-19
