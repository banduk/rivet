---
name: control-flow
description: Control-flow nodes — if/else branching, loop-controller/loop-until iteration, race-inputs concurrency, and graph abort
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/model/nodes/IfElseNode.ts`
- `packages/core/src/model/nodes/IfNode.ts`
- `packages/core/src/model/nodes/LoopControllerNode.ts`
- `packages/core/src/model/nodes/LoopUntilNode.ts`
- `packages/core/src/model/nodes/RaceInputsNode.ts`
- `packages/core/src/model/nodes/AbortGraphNode.ts`

Keywords: control-flow-excluded, loopController, loopUntil, raceInputs, abortGraph, continueValue, iterationCount, attachedData, createSubProcessor

---

## Key Concepts

- **`control-flow-excluded`:** The sentinel `DataValue` type `{ type: 'control-flow-excluded', value: undefined }` that propagates "not ran" through the graph. All control-flow nodes must emit it — never `undefined` — for ports that should be skipped.

- **LoopController vs LoopUntil:** `LoopControllerNode` runs within the same graph (uses `context.attachedData.loopInfo.iterationCount` for iteration tracking; GraphProcessor owns the cycle). `LoopUntilNode` calls a subgraph each iteration via `context.createSubProcessor(graphId, { signal })` and manages the loop itself in `process()`.

- **Dynamic ports:** `LoopControllerNode` and `RaceInputsNode` compute port counts by scanning `connections` for `inputN`-prefixed connections. `getInputDefinitions` and `getOutputDefinitions` both receive `connections` — use `#getInputPortCount(connections)` private helper pattern. `LoopUntilNode` ports are instead derived from the target graph's `GraphInputNode`/`GraphOutputNode` definitions (scans `project.graphs[targetGraph].nodes`).

- **LoopController default inputs:** Each loop variable has an `inputN` port (from loop body) and `inputNDefault` port (initial value). If any `Default` input is `control-flow-excluded`, the whole node outputs `control-flow-excluded` — this is how the loop detects it's being initialized vs. running.

- **LoopController break output:** When continuing, `break` emits `{ type: 'control-flow-excluded', value: 'loop-not-broken' }`. When breaking, `break` emits `{ type: 'any[]', value: [...inputValues] }` — an array of all loop variable values.

- **LoopUntil stop conditions:** `conditionType: 'allOutputsSet'` breaks when no output is `control-flow-excluded`. `conditionType: 'inputEqual'` breaks when `outputs[inputToCheck].value.toString() === targetValue`. Static `this.data.inputData` defaults only fill `undefined` ports on first call; subsequent iterations use `currentInputs = lastOutputs`.

- **AbortGraph:** Calls `context.abortGraph()` (success, early-exit) or `context.abortGraph(errorMessage)` (error). Returns empty `Outputs` — no output ports exist on this node.

- **RaceInputs:** GraphProcessor handles actual racing/cancellation. `process()` only picks the first non-`control-flow-excluded` input; it never does async racing itself.

## Critical Rules

- Never return `undefined` for a port that should be excluded — always return `{ type: 'control-flow-excluded', value: undefined }`.
- `LoopControllerNode.process()` reads iteration count from `context.attachedData.loopInfo?.iterationCount ?? 0` — do not track iterations in node state.
- `LoopUntilNode` must pass `{ signal: context.signal }` to `createSubProcessor` so abort propagates into iterations.
- `LoopController` `atMaxIterationsAction` defaults to `'error'`; only set it to `'break'` when `data.atMaxIterationsAction === 'break'` is explicitly checked.

## References
- **Patterns:** `.claude/guidelines/packages/patterns.md`

---
**Last Updated:** 2026-04-19
