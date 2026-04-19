---
name: trivet-testing-framework
description: Graph-output testing framework for Rivet — test suites, validation graphs, and result types
---

## Activation

This skill triggers when editing these files:
- `packages/trivet/src/**`
- `packages/app/src/state/trivet.ts`
- `packages/app/src/hooks/useTestSuite.ts`
- `packages/app/src/components/trivet/**`

Keywords: TrivetTestSuite, TrivetTestCase, runTrivet, TrivetOpts, validationGraph, trivetTypes

---

You are working on **Trivet**, the graph-output testing framework embedded in Rivet.

## Key Files
- `packages/trivet/src/trivetTypes.ts` — all core types: `TrivetTestSuite`, `TrivetTestCase`, `TrivetOpts`, `TrivetResults`
- `packages/trivet/src/api.ts` — `runTrivet(opts)` (main runner) + `createTestGraphRunner()` factory
- `packages/trivet/src/validateValidationGraphFormat.ts` — enforces required input/output nodes on validation graphs
- `packages/trivet/src/validateTestCaseFormat.ts` — checks test case inputs/outputs match graph nodes
- `packages/trivet/src/serialization/serialization_v1.ts` — YAML serialization; format is version-locked (`version: 1`)
- `packages/app/src/state/trivet.ts` — Jotai atoms for suites, results, running state

## Key Concepts
- **Validation graph contract:** Must have exactly three input nodes named `"input"`, `"expectedOutput"`, `"output"` (the actual test graph output). At least one output node returning `boolean` or string `"true"`/`"TRUE"`.
- **Passing logic:** A test case passes only when ALL validation graph output nodes are truthy. A suite passes only when ALL test cases pass ALL iterations.
- **`iterationCount`:** Each test case runs N times (default 1). One failing iteration fails the case.
- **`inferType()`:** Raw JS values from `testCase.input` are converted to `DataValue` via `inferType()` from rivet-core before graph execution — never pass raw values directly.
- **Cost tracking:** Runners extract a `cost` output from graph results if present; set it explicitly on outputs for accurate cost reporting.
- **`onUpdate` callback:** Called after every single iteration (not per-suite), enabling progressive UI updates.

## Critical Rules
- Validation graphs with missing `input`/`expectedOutput`/`output` input nodes will fail `validateValidationGraphFormat` — the UI blocks running until fixed.
- `TrivetTestCase.input` keys must match graph input node IDs exactly; `expectedOutput` keys must match graph output node IDs (`validateTestCaseFormat` checks this).
- Serialized data must include `version: 1`; deserializer throws on missing/wrong version.
- Trivet has no CLI — it's a library consumed by `packages/app` (local executor) and via WebSocket (remote executor).

## References
- **Types:** `packages/trivet/src/trivetTypes.ts`
- **Runner:** `packages/trivet/src/api.ts`

---
**Last Updated:** 2026-04-19
