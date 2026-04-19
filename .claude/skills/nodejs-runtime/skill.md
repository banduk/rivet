---
name: nodejs-runtime
description: Node.js runtime providers, app-executor sidecar, and graph execution API in packages/node and packages/app-executor
---

## Activation

This skill triggers when editing these files:
- `packages/node/src/**`
- `packages/app-executor/bin/**`
- `packages/app-executor/scripts/**`

Keywords: NodeNativeApi, NodeMCPProvider, NodeDatasetProvider, NodeCodeRunner, createProcessor, startDebuggerServer, app-executor, runGraph

---

You are working on the **Node.js runtime layer** of Rivet — providers that back `ProcessContext`, the public execution API, and the Tauri sidecar executor.

## Key Files
- `packages/node/src/api.ts` — `createProcessor()` and `runGraph()`; wraps core with Node defaults
- `packages/node/src/native/NodeNativeApi.ts` — File I/O; `exec()` intentionally throws "Not Implemented"
- `packages/node/src/native/NodeMCPProvider.ts` — MCP via `@modelcontextprotocol/sdk`; create→connect→call→close per request
- `packages/node/src/native/NodeDatasetProvider.ts` — Extends `InMemoryDatasetProvider`; write-through with optional `.save` flag
- `packages/node/src/native/NodeCodeRunner.ts` — `AsyncFunction` with injected `require`, `process`, `fetch`, `Rivet`, `context`
- `packages/node/src/debugger.ts` — WebSocket debugger server; partial outputs throttled to 100ms per node
- `packages/node/src/index.ts` — Re-exports all of `@ironclad/rivet-core` plus node-specific exports
- `packages/app-executor/bin/executor.mts` — Sidecar: WebSocket server receiving `set-dynamic-data` + `run` messages

## Key Concepts
- **Provider injection:** `createProcessor()` defaults `nativeApi`, `mcpProvider`, `codeRunner` to Node implementations if not supplied; always sets `processor.executor = 'nodejs'`
- **Plugin env injection:** `createProcessor()` auto-populates `pluginEnv` from `process.env` for any plugin config key with `pullEnvironmentVariable`
- **Sidecar execution:** `app-executor` is compiled via esbuild+pkg to native binaries in `dist/app-executor-{target}`; receives project+settings dynamically over WebSocket
- **Dataset persistence:** Pass `{ save: true }` to `NodeDatasetProvider`; every mutation calls `save()` after the parent method. Use `fromProjectFile()` to auto-resolve `.rivet-data` sibling files
- **MCP transports:** HTTP uses StreamableHTTP with SSE fallback; STDIO spawns subprocess — client lifecycle is per-call (not shared)

## Critical Rules
- `packages/node/src/index.ts` must re-export `@ironclad/rivet-core` entirely — consumers use `@ironclad/rivet-node` as their sole import
- New providers must implement the interface from `packages/core/src/model/ProcessContext.ts` exactly
- `NodeCodeRunner` uses `createRequire(import.meta.url)` — do not use bare `require`; the file is ESM
- `app-executor` plugins are loaded from appdata paths (`~/.local/share/com.ironcladapp.rivet/plugins/{pkg}-{tag}/package`) — do not hardcode paths
- Debugger event broadcasting must remain throttled; removing the 100ms partial-output limit causes UI flooding

## References
- **Patterns:** `.claude/skills/packages/skill.md`

---
**Last Updated:** 2026-04-19
