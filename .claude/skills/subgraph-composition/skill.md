---
name: subgraph-composition
description: SubGraph, CallGraph, GraphInput, GraphOutput, and GraphReference nodes — calling graphs as nodes, dynamic graph dispatch, and defining graph boundaries
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/model/nodes/SubGraphNode.ts`
- `packages/core/src/model/nodes/CallGraphNode.ts`
- `packages/core/src/model/nodes/GraphInputNode.ts`
- `packages/core/src/model/nodes/GraphOutputNode.ts`
- `packages/core/src/model/nodes/GraphReferenceNode.ts`

Keywords: SubGraphNode, CallGraphNode, GraphInputNode, GraphOutputNode, GraphReferenceNode, createSubProcessor, graph-reference, graphId, graphInputs, graphOutputs

---

## Key Files
- `SubGraphNode.ts` — static subgraph call; ports mirror the target graph's Input/Output nodes
- `CallGraphNode.ts` — dynamic dispatch; accepts a `graph-reference` DataValue + `object` inputs, returns `object` outputs
- `GraphReferenceNode.ts` — produces a `graph-reference` DataValue; supports lookup by name or ID at runtime
- `GraphInputNode.ts` / `GraphOutputNode.ts` — define a graph's external interface; `data.id` is the port name

## How Subgraph Ports Are Derived

`SubGraphNodeImpl.getInputDefinitions()` reads **`project.graphs[graphId].nodes`**, filters for `type === 'graphInput'`, deduplicates on `node.data.id`, and sorts. Port `id` and `title` are both set to `node.data.id`. Same pattern for outputs via `graphOutput` nodes. Missing or wrong `graphId` → returns `[]` silently.

## Execution

Both `SubGraphNodeImpl` and `CallGraphNodeImpl` call `context.createSubProcessor(graphId, { signal })` then `.processGraph(context, inputData, context.contextValues)`. Never instantiate `GraphProcessor` directly for subgraph calls.

## CallGraph vs SubGraph

- **SubGraphNode**: compile-time graph wired in UI; ports typed per target graph's IO nodes; `inputData` on `data` stores inline default values for unconnected ports.
- **CallGraphNode**: runtime dispatch; inputs always `object` shape; outputs always `object` (raw `Outputs` map); use with `GraphReferenceNode` for dynamic routing.

## GraphOutputNode Merge Semantics

Multiple `GraphOutputNode` instances with the same `data.id` **merge** into one output: first non-excluded value wins. A `control-flow-excluded` value only sets the output if no other value has been written yet (`context.graphOutputs[id] == null`).

## Critical Rules
- `GraphInputNode.process()` reads from `context.graphInputs[this.data.id]`, not from `inputs` ports (except for the optional `default` port). Renaming `data.id` after wiring breaks the contract silently.
- When `useErrorOutput` is `true`, on success the `error` port emits `control-flow-excluded`; on failure all normal outputs emit `control-flow-excluded` and `error` emits the message string.
- `GraphReferenceNode` with `useGraphIdOrNameInput` falls back to name lookup only if ID lookup fails; returns `control-flow-excluded` if not found (no throw).
- `CallGraphNode` inputs arrive as a plain `object` DataValue and are converted via `looseDataValuesToDataValues()` before being passed to the subprocessor.

## References
- **Patterns:** `.claude/guidelines/packages/patterns.md`

---
**Last Updated:** 2026-04-19
