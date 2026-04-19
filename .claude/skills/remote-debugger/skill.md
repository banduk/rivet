---
name: remote-debugger
description: Remote debugger WebSocket protocol — server (packages/node) and client (packages/app) sides
---

## Activation

This skill triggers when editing these files:
- `packages/node/src/debugger.ts`
- `packages/app/src/hooks/useRemoteDebugger.ts`
- `packages/app/src/hooks/useRemoteExecutor.ts`
- `packages/app/src/components/DebuggerConnectPanel.tsx`
- `packages/app/src/state/execution.ts`

Keywords: startDebuggerServer, useRemoteDebugger, RivetDebuggerServer, remoteDebuggerState, setCurrentDebuggerMessageHandler

---

You are working on the **remote debugger** in Rivet — a WebSocket bridge between a Node.js execution server and the app UI.

## Key Files
- `packages/node/src/debugger.ts` — `startDebuggerServer()`: WebSocket server, `attach(processor)` wires all `GraphProcessor` events → broadcast, `detach()` removes
- `packages/app/src/hooks/useRemoteDebugger.ts` — client hook; manages WebSocket lifecycle, exponential backoff reconnect, dataset proxying
- `packages/app/src/hooks/useRemoteExecutor.ts` — calls `setCurrentDebuggerMessageHandler` to route incoming messages to `useCurrentExecution` handlers
- `packages/app/src/state/execution.ts` — `RemoteDebuggerState` atom (persisted); holds `socket`, `started`, `reconnecting`, `remoteUploadAllowed`, `isInternalExecutor`
- `packages/app/src/components/DebuggerConnectPanel.tsx` — UI; `debuggerDefaultUrlState` persists last-used URL

## Key Concepts
- **Default ports:** `21888` for external remote debugger; `21889/internal` for the internal Node.js executor (auto-connected when executor = `nodejs`)
- **Message protocol:** Server→client uses `{ message, data }` envelope; client→server uses `{ type, data }` envelope — these are asymmetric by design
- **`isInternalExecutor`:** `true` when URL is `ws://localhost:21889/internal`; controls whether the UI shows "remote debugging" mode
- **`remoteUploadAllowed`:** Server sends `graph-upload-allowed` on connect; only then does the client send `set-dynamic-data` (project + settings) before each run
- **`setCurrentDebuggerMessageHandler`:** Module-level singleton — last call wins; `useRemoteExecutor` sets it on every render
- **Dataset proxy:** `datasets:*` messages from server are handled in `useRemoteDebugger` directly (not via the message handler), proxied to local `datasetProvider`
- **`partialOutput` throttling:** Server-side, default 100ms per node to reduce serdes load — set via `throttlePartialOutputs` option

## Critical Rules
- `attach(processor)` must be called after `startDebuggerServer()` — forgetting it means no events are broadcast
- Reconnect loop in `useRemoteDebugger` uses a module-level `manuallyDisconnecting` flag; always set it before closing the socket to prevent ghost reconnects
- `set-static-data` uses a raw colon-delimited string (`set-static-data:<id>:<value>`), not JSON — server splits on first two colons
- Parallel graph runs are unsupported in remote mode: `graphExecutionPromise` is a single module-level slot in `useRemoteExecutor`

## References
- **Patterns:** `.claude/skills/base/skill.md`

---
**Last Updated:** 2026-04-19
