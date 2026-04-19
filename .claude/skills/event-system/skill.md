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
- `packages/core/src/model/nodes/RaiseEventNode.ts` — fires `context.raiseEvent(name, data)` on the root processor; passes input data through on `result` port
- `packages/core/src/model/nodes/WaitForEventNode.ts` — blocks on `context.waitEvent(name)` returning `Promise<DataValue | undefined>`; emits both original `outputData` (pass-through) and `eventData` (event payload)
- `packages/core/src/model/ProcessContext.ts:104-106` — `InternalProcessContext` interface: `raiseEvent(name, data)` and `waitEvent(name) => Promise<DataValue | undefined>`
- `packages/core/src/model/GraphProcessor.ts:1466` — internal `raiseEvent` emits `userEvent:${name}` and propagates to all subprocessors

## Key Concepts
- **Event bus:** Events are emitted as `userEvent:${eventName}` on the graph emitter; `raiseEvent` always routes through `getRootProcessor()` so subgraph raises are visible to parent `waitEvent` listeners.
- **WaitForEvent blocks execution:** `waitEvent` is a `Promise` resolved by `emitter.once(...)` — the node holds its graph branch until the event fires or the node aborts.
- **Abort propagation:** `waitEvent` rejects on `nodeAbortController.abort()` — no hung promises if the graph is cancelled.
- **Port naming asymmetry:** RaiseEvent input is `data`; WaitForEvent input is `inputData` and outputs are `outputData` + `eventData` — don't conflate them.

## Critical Rules
- `raiseEvent` calls `getRootProcessor().raiseEvent(...)` — events raised in a subgraph are visible everywhere; there is no scoped/local event bus.
- `waitEvent` resolves with the event payload, not the node's input — use `eventData` port for the raised value, `outputData` for the pass-through.
- Both nodes support `useEventNameInput` toggle: when true, `eventName` is a dynamic port; when false it reads `this.data.eventName`. Editor must set `useInputToggleDataKey: 'useEventNameInput'`.

## References
- **Patterns:** `.claude/guidelines/event-system/patterns.md`

---
**Last Updated:** 2026-04-19
