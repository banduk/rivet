# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What Is Rivet

Rivet is an open-source IDE and runtime for building AI agent pipelines via a visual graph editor. It ships as:
- A desktop application (`packages/app`) built with React + Tauri
- Embeddable libraries (`packages/core`, `packages/node`) for running graphs in Node.js or browser
- A CLI (`packages/cli`)
- A testing framework (`packages/trivet`)

## Commands

```bash
# Install dependencies (Yarn 4 PnP — no node_modules)
yarn

# Start the full desktop app (builds app-executor first, then launches Tauri dev)
yarn dev

# Build all packages in dependency order
yarn build

# Run tests (currently scoped to rivet-core)
yarn test

# Lint all packages
yarn lint

# Format all files
yarn prettier:fix

# Per-package commands (run from root via workspace filter)
yarn workspace @ironclad/rivet-core run build
yarn workspace @ironclad/rivet-core run test        # runs: tsx --test test/**/*.test.ts
yarn workspace @ironclad/rivet-core run watch       # tsc -b -w for incremental dev
yarn workspace @ironclad/rivet-app run dev          # Vite-only (no Tauri)
```

### Running a single test file
```bash
cd packages/core && npx tsx --test test/path/to/file.test.ts
```

Tests use the **Node.js native test runner** (`node:test` + `node:assert`) — not Jest or Vitest.

## Architecture

### Monorepo Layout

| Package | Purpose |
|---|---|
| `packages/core` | Graph execution engine, node definitions, plugin system — isomorphic (browser + Node) |
| `packages/node` | Node.js-specific runtime: file system, native APIs, MCP SDK integration |
| `packages/app` | Desktop UI: React 18 + Vite + Tauri (Rust shell) |
| `packages/app-executor` | Sidecar process spawned by the desktop app to run graphs in Node.js context |
| `packages/cli` | `rivet` CLI, uses Hono to serve/expose graphs |
| `packages/trivet` | Testing framework for asserting graph outputs |
| `packages/docs` | Docusaurus documentation site |
| `packages/community` | Next.js community portal (private, Vercel-hosted) |

### Core Execution Model (`packages/core`)

The central abstraction is a **graph of nodes** processed by `GraphProcessor`.

- **`NodeGraph`** — data structure: array of `ChartNode` + array of `NodeConnection`
- **`GraphProcessor`** — event-driven executor (uses `Emittery`); emits `nodeStart`, `partialOutput`, `nodeFinish`, `graphFinish`, `nodeError`, `userInput`, etc.
- **`NodeImpl<T>`** — base class for all node implementations; each node type has a static definition (`NodeDefinition`) and an instance impl that exposes `process()`, `getInputDefinitions()`, `getOutputDefinitions()`
- **`DataValue`** — tagged union that is the unit of data flowing between nodes: `{ type: 'string', value: '...' }`, `{ type: 'number[]', value: [...] }`, etc. Automatic coercion happens based on port type expectations.
- **`ProcessContext`** — passed to every node's `process()` call; holds integrations (LLM, embeddings, vector DB, MCP, etc.) and the `signal` for abort

All node types live in `packages/core/src/model/nodes/`. Each file exports both the static definition and the implementation class.

### Plugin System

`RivetPlugin` registers custom node types:
```ts
{
  id: 'my-plugin',
  name: 'My Plugin',
  register(registry) { registry.registerNodeType(MyCustomNode); },
  configSpec: { apiKey: { type: 'secret', label: 'API Key' } }
}
```
Built-in plugins (OpenAI, Anthropic, Google, HuggingFace, AssemblyAI, Pinecone, Gentrace, AutoEvals) live in `packages/core/src/integrations/`.

### Integration Provider Pattern

Capabilities like LLM calls, embeddings, vector DBs, code execution, and MCP are injected via the `ProcessContext` using provider interfaces:
- `LLMProvider`, `EmbeddingGenerator`, `VectorDatabase`, `AudioProvider`, `CodeRunner`, `DatasetProvider`, `MCPProvider`

This keeps core isomorphic — Node.js-specific implementations (file access, native net) are in `packages/node`.

### Desktop App State

The app uses **Jotai** (atoms) for React state throughout `packages/app/src/`. The Tauri shell enforces a strict allowlist of permissions (filesystem, shell, dialog) defined in `packages/app/src-tauri/tauri.conf.json`. The `app-executor` sidecar is what actually runs graphs in Node.js on behalf of the UI.

## Build System

- **ESM build**: `tsc -b` → `dist/esm/` + `dist/types/`
- **CJS build**: `esbuild` via `bundle.esbuild.ts` → `dist/cjs/bundle.cjs`
- All published packages (`core`, `node`, `trivet`, `cli`) ship dual ESM/CJS exports
- TypeScript strict mode is on everywhere; `verbatimModuleSyntax` is required (use `import type` for type-only imports)

## Code Conventions

- **ESM throughout**: all source uses `.js` extensions in imports even for `.ts` files (TS `moduleResolution: bundler` / `node16` convention)
- **`ts-pattern`** is used for exhaustive matching on discriminated unions (common in node processors)
- **`lodash-es`** (not `lodash`) in core for tree-shaking
- Prettier config: single quotes, trailing commas, 120-char line width
- ESLint v9 flat config; no circular imports enforced via `eslint-plugin-import`
- Node versions pinned via Volta: Node 20.4.0, Yarn 3.5.0 (root `volta` field)
