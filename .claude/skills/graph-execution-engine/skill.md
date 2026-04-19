---
name: graph-execution-engine
description: GraphProcessor execution model, control flow exclusion, loop cycles, split runs, and InternalProcessContext for rivet's core engine
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/model/GraphProcessor.ts`
- `packages/core/src/model/ProcessContext.ts`
- `packages/core/src/model/NodeImpl.ts`
- `packages/core/src/model/NodeRegistration.ts`
- `packages/core/src/model/Nodes.ts`

Keywords: GraphProcessor, processGraph, InternalProcessContext, control-flow-excluded, loopController, createSubProcessor, splitRun, NodeRegistration

---

## Key Files
- `packages/core/src/model/GraphProcessor.ts` — full execution engine (1905 lines)
- `packages/core/src/model/ProcessContext.ts` — `ProcessContext` (external) and `InternalProcessContext` (per-node, internal)
- `packages/core/src/model/Nodes.ts` — global registry (`globalRivetNodeRegistry`); all built-in nodes registered here

## Execution Model
- Entry: `processor.processGraph(context, inputs, contextValues)` — `contextValues` propagate to all subgraphs (like React context)
- Traversal starts from **sink nodes** (no dependents), walks backward to sources using `p-queue` with `concurrency: Infinity`
- Each node processes once, tracked in `#visitedNodes` — exception: `loopController` can re-process (cycles cleared per iteration)
- Nested loops explicitly throw an error — only one loop level per subgraph

## Control Flow Exclusion
- When a node is excluded (via `if` port or excluded input), all its outputs become `{ type: 'control-flow-excluded', value: undefined }`
- Excluded values propagate downstream; downstream nodes are also excluded — unless they are: `if`, `ifElse`, `coalesce`, `graphOutput`, `raceInputs`, `loopController`
- Loop controller uses special value `{ type: 'control-flow-excluded', value: 'loop-not-broken' }` on its `break` port to signal "loop continues"

## Split Runs
- If `node.isSplitRun`, array inputs are unpacked and the node runs once per element; results recombined into arrays (`string` → `string[]`)
- `node.isSplitSequential` serializes these; otherwise all run in parallel

## InternalProcessContext (per node)
- `context.signal` — `AbortSignal`; nodes doing async I/O must respect it
- `context.executionCache` — `Map<string, unknown>` shared across all subgraphs for the entire run; use for deduplication
- `context.getGlobal` / `context.setGlobal` / `context.waitForGlobal` — cross-graph variables; `waitForGlobal` blocks until a `globalSet` event fires
- `context.createSubProcessor(graphId)` — creates a child `GraphProcessor` that shares `executionCache`, `globals`, and `contextValues` with parent
- `context.abortGraph(error?)` — aborts the whole graph; if error is undefined, it's a successful early exit

## Node Registration
- Built-in nodes: call `registry.register(nodeDefinition)` in `registerBuiltInNodes()` in `Nodes.ts` — **both** the `.register()` call and the `export *` line are required
- Plugin nodes: call `registry.registerPluginNode(definition, plugin)` — wraps impl in `PluginNodeImplClass`
- Duplicate type strings throw at registration time

## Critical Rules
- `loopController` is the only node type whose `#visitedNodes` entry is cleared between iterations; never add custom cycle-clearing logic
- Only `if`, `ifElse`, `coalesce`, `graphOutput`, `raceInputs`, `loopController` may receive `control-flow-excluded` inputs without being excluded — hardcoded list in `#excludedDueToControlFlow`
- `projectReferenceLoader` must be set in `ProcessContext` if the project uses references — throws at runtime otherwise
- `IF_PORT` (`$if`) is injected by `getInputDefinitionsIncludingBuiltIn`; never add it manually in `getInputDefinitions`

## References
- **Patterns:** `.claude/guidelines/graph-execution-engine/patterns.md`

---
**Last Updated:** 2026-04-19
