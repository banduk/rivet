---
name: app-executor-sidecar
description: Node.js sidecar process that executes Rivet graphs via WebSocket, compiled to a native binary by Tauri
---

## Activation

This skill triggers when editing these files:
- `packages/app-executor/bin/executor.mts`
- `packages/app-executor/scripts/build-executor.mts`
- `packages/node/src/debugger.ts`
- `packages/node/src/api.ts`
- `packages/app/src/hooks/useExecutorSidecar.ts`
- `packages/app/src/hooks/useRemoteExecutor.ts`

Keywords: app-executor, RivetDebuggerServer, set-dynamic-data, executor-bundle, sidecar

---

You are working on the **app-executor sidecar** — a single-file Node.js server (`bin/executor.mts`) compiled to a native binary and launched by Tauri to execute graphs.

## Key Files
- `packages/app-executor/bin/executor.mts` — entire runtime: WebSocket server, message handling, plugin loading, processor lifecycle
- `packages/app-executor/scripts/build-executor.mts` — esbuild bundle → pkg native binary; custom `resolveRivet` plugin remaps `@ironclad/rivet-*` to source
- `packages/node/src/debugger.ts` — `RivetDebuggerServer` interface + WebSocket broadcast protocol; `currentDebuggerState` lives here
- `packages/node/src/api.ts` — `createProcessor()` wrapping core; injects Node.js providers
- `packages/app/src/hooks/useExecutorSidecar.ts` — spawns sidecar via `Command.sidecar('../../app-executor/dist/app-executor')`, retries on failure

## Key Concepts
- **Single-file design:** All executor logic lives in `executor.mts` — no `src/` directory, no modules.
- **Communication:** App connects to `ws://localhost:21889/internal` (sidecar); 21888 is the external/remote debugger port — do not confuse them.
- **Execution flow:** App sends `set-dynamic-data` (project + settings) → `run` (graphId, inputs, optional `runToNodeIds`/`runFromNodeId`) → executor broadcasts events → `done`/`abort`.
- **Global state:** `currentDebuggerState` (in `debugger.ts`) holds `uploadedProject` and `settings`; mutated by `set-dynamic-data` before each run.
- **Plugin types:** `built-in` | `uri` | `package` — matched via `ts-pattern`; package plugins load from `~/.local/share/com.ironcladapp.rivet/plugins/` (Linux path; `getAppDataLocalPath()` handles all platforms).
- **Inbound message types:** `set-dynamic-data`, `run`, `abort`, `pause`, `resume`, `user-input`, `preload`, `datasets:response`; plus raw `set-static-data:${id}:${value}` prefix.

## Critical Rules
- `set-static-data` messages use a colon-delimited text format (`set-static-data:${id}:${value}`), not JSON — parse accordingly.
- Never change the default port (21889) without updating both the executor and the app-side hooks (`useExecutorSidecar.ts`, `useRemoteExecutor.ts`).
- Build uses esbuild → CommonJS bundle first, then `pkg` for native binary. Do not add dynamic `require()` calls that pkg cannot bundle statically.
- SIGTERM handler must close the WebSocket server — required for clean Tauri sidecar shutdown.
- Partial output events are throttled at 100ms in `RivetDebuggerServer` — do not bypass this when adding new broadcast paths.

## References
- **Patterns:** `.claude/skills/packages/skill.md`

---
**Last Updated:** 2026-04-19
