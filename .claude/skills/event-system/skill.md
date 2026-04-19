---
name: event-system
description: Pub/sub event coordination between concurrent graph branches via RaiseEvent and WaitForEvent nodes
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/model/nodes/RaiseEventNode.ts`
- `packages/core/src/model/nodes/WaitForEventNode.ts`

Keywords: raiseEvent, waitEvent, userEvent, WaitForEventNode, RaiseEventNodeImpl, InternalProcessContext

---

## Key Files
- `packages/core/src/model/nodes/RaiseEventNode.ts` — fires `context.raiseEvent(name, data)` on the root processor; passes input `data` through unchanged on `result` port
- `packages/core/src/model/nodes/WaitForEventNode.ts` — blocks on `context.waitEvent(name)` returning `Promise<DataValue | undefined>`; emits `outputData` (pass-through of `inputData`) and `eventData` (event payload)
- `packages/core/src/model/ProcessContext.ts:104-106` — `InternalProcessContext` interface: `raiseEvent(name, data)` and `waitEvent(name) => Promise<DataValue | undefined>`
- `packages/core/src/model/GraphProcessor.ts:1466` — `raiseEvent` emits `userEvent:${name}` on the graph emitter and propagates to all subprocessors; `waitEvent` (line 1521) uses `emitter.once(...)`

## Key Concepts
- **Event bus:** Events travel as `userEvent:${eventName}` on the graph emitter. `raiseEvent` always routes through `getRootProcessor()` so subgraph raises are visible to all `waitEvent` listeners anywhere in the graph hierarchy.
- **WaitForEvent blocks execution:** `waitEvent` is a `Promise` resolved by `emitter.once(...)` — the node holds its branch until the event fires or the node aborts.
- **Abort propagation:** `waitEvent` rejects on `nodeAbortController.abort()` — no hung promises if the graph is cancelled.
- **Dynamic event names:** Both nodes support `useEventNameInput: boolean` — when true, an `eventName` port appears and the static `data.eventName` is ignored. Defaults: `'toast'` (RaiseEvent), `'continue'` (WaitForEvent).
- **Port naming asymmetry:** RaiseEvent input is `data`, output is `result`; WaitForEvent input is `inputData`, outputs are `outputData` + `eventData` — do not conflate them.

## Critical Rules
- `raiseEvent` calls `getRootProcessor().raiseEvent(...)` — events raised in a subgraph are visible everywhere; there is no scoped/local event bus.
- `waitEvent` uses `emitter.once` — each listener fires exactly once; a second raise of the same event name does NOT wake a listener that already resolved.
- `result` on RaiseEvent is a direct pass-through of the `data` input (`eventData` is returned as-is, not wrapped); `outputData` on WaitForEvent is a pass-through of `inputData`, not the event payload.

## References
- **Patterns:** `.claude/guidelines/event-system/patterns.md`

---
**Last Updated:** 2026-04-19
