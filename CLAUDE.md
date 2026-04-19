# CLAUDE.md

Rivet is an open-source IDE and runtime for building AI agent pipelines via a visual graph editor.

**Stack:** TypeScript, React 18, Tauri (Rust), Vite, Jotai, Yarn 4 PnP (no node_modules)

## Skills

- `.claude/skills/base/skill.md` — Core conventions, tech stack, project structure
- `.claude/skills/packages/skill.md` — Node implementations, Command pattern, state atoms, DataValue system, dual ESM/CJS build

## Commands

```bash
yarn                  # install deps
yarn dev              # full desktop app (Tauri)
yarn build            # build all packages
yarn test             # tests (rivet-core only)
yarn lint             # lint all packages
yarn prettier:fix     # format all files

yarn workspace @ironclad/rivet-core run build
yarn workspace @ironclad/rivet-core run test   # tsx --test test/**/*.test.ts
yarn workspace @ironclad/rivet-core run watch  # tsc -b -w
yarn workspace @ironclad/rivet-app run dev     # Vite-only (no Tauri)

# Single test file
cd packages/core && npx tsx --test test/path/to/file.test.ts
```

Tests use **Node.js native test runner** (`node:test` + `node:assert`) — not Jest or Vitest.

## Packages

| Package | Purpose |
|---|---|
| `packages/core` | Graph execution engine, node definitions, plugin system (isomorphic) |
| `packages/node` | Node.js runtime: file system, native APIs, MCP SDK |
| `packages/app` | Desktop UI: React 18 + Vite + Tauri |
| `packages/app-executor` | Sidecar process that runs graphs in Node.js context |
| `packages/cli` | `rivet` CLI (Hono-based) |
| `packages/trivet` | Graph output testing framework |

## Key Files

**Hub files (most depended-on):**
- `packages/app/src/state/graph.ts` - 28 dependents
- `packages/app/src/state/savedGraphs.ts` - 25 dependents
- `packages/app/src/state/graphBuilder.ts` - 16 dependents
- `packages/app/src/hooks/useStableCallback.ts` - 10 dependents
- `packages/app/src/utils/globals.ts` - 10 dependents

## Critical Conventions

- **ESM throughout**: use `.js` extensions in imports even for `.ts` files
- **`import type`** for type-only imports (`verbatimModuleSyntax` is on)
- **`ts-pattern`** for exhaustive matching on discriminated unions
- **`lodash-es`** (not `lodash`) in core
- Prettier: single quotes, trailing commas, 120-char line width
- No circular imports (enforced via ESLint)

## Behavior

- **Verify before claiming** — Never state that something is configured, running, scheduled, or complete without confirming it first. If you haven't verified it in this session, say so rather than assuming.
- **Make sure code is running** — If you suggest code changes, ensure the code is running and tested before claiming the task is done.
