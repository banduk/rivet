---
name: global-variables
description: GetGlobal/SetGlobal nodes — shared key-value state across graphs and subgraphs during execution
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/model/nodes/GetGlobalNode.ts`
- `packages/core/src/model/nodes/SetGlobalNode.ts`

Keywords: getGlobal, setGlobal, waitForGlobal, onDemand, GetGlobalNode, SetGlobalNode, global variable

---

## Key Files
- `packages/core/src/model/nodes/GetGlobalNode.ts` — reads global by string ID
- `packages/core/src/model/nodes/SetGlobalNode.ts` — writes global by string ID
- `packages/core/src/model/ProcessContext.ts` — declares `getGlobal`, `setGlobal`, `waitForGlobal` on `InternalProcessContext`

## Context API
```ts
context.getGlobal(id: string): ScalarOrArrayDataValue | undefined
context.setGlobal(id: string, value: ScalarOrArrayDataValue): void
context.waitForGlobal(id: string): Promise<ScalarOrArrayDataValue>
```
Globals are keyed by plain string ID and shared across all graphs/subgraphs for the lifetime of one execution run.

## Critical Rules
- **`onDemand` and `wait` are mutually exclusive** — GetGlobal throws at runtime if both are true.
- **`onDemand: true` changes output type** — emits `fn<dataType>` (lazy), not `dataType`. Downstream nodes receive a function and must call `unwrapDataValue()`. Default is `onDemand: true`.
- **`setGlobal` requires unwrapped value** — call `unwrapDataValue(rawValue)` before `context.setGlobal()` or you store a function wrapper instead of data.
- **`setGlobal` value type must be `ScalarOrArrayDataValue`**, not function-typed — context rejects fn-wrapped values.
- **Missing globals have safe defaults**: array types → `[]`, scalars → `scalarDefaults[dataType]`. Never `undefined` in output.
- **Bug (line 142 in SetGlobalNode)**: previous value is read using `this.data.id` (static field), not the resolved `id` variable — `useIdInput` mode may read wrong previous value.

## Data Flow Pattern
- `id` is a static string or resolved from the `'id'` input port when `useIdInput: true`.
- SetGlobal outputs: `saved-value`, `previous-value`, `variable_id_out`.
- GetGlobal outputs: `value` (or `fn<value>` when `onDemand`), `variable_id_out`.

## References
- **Patterns:** `.claude/guidelines/global-variables/patterns.md`

---
**Last Updated:** 2026-04-19
