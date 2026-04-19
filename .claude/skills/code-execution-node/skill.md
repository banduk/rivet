---
name: code-execution-node
description: CodeNode sandboxed JS execution, CodeRunner interface, port name masking, and AI-assist editor integration
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/model/nodes/CodeNode.ts`
- `packages/core/src/integrations/CodeRunner.ts`
- `packages/app/src/components/editors/custom/CodeNodeAIAssistEditor.tsx`

Keywords: CodeNode, CodeNodeData, CodeRunner, IsomorphicCodeRunner, runCode, codeRunner, allowFetch, allowRequire, allowRivet, allowProcess, allowConsole

---

## Key Files
- `packages/core/src/model/nodes/CodeNode.ts` — node type, port generation, `process()` delegation to `context.codeRunner`
- `packages/core/src/integrations/CodeRunner.ts` — `CodeRunner` interface + `IsomorphicCodeRunner` (browser-safe) + `NotAllowedCodeRunner` (disabled mode)
- `packages/app/src/components/editors/custom/CodeNodeAIAssistEditor.tsx` — AI-assist UI wrapping `AiAssistEditorBase`

## Key Concepts

- **Port names are masked:** `maskInput` at line 19 replaces non-`[a-zA-Z0-9_]` chars with `_` and deduplicates via `Set`. Port `id` equals the masked name — user code accesses `inputs` via those same masked keys.
- **`inputs` are raw `DataValue` tagged unions** inside user code — access `.type` and `.value` directly; runtime does NOT unwrap them.
- **`process()` validates return shape** — all declared output port IDs must be present or it throws. Skip an output with `{ type: 'control-flow-excluded', value: undefined }`; return undefined with `{ type: 'any', value: undefined }`.
- **Execution is `new AsyncFunction(...argNames)(...)`.** Only enabled capabilities (`includeFetch`, `includeConsole`, `includeRivet`) are injected as named args. `graphInputs` and `context` (contextValues) are always injected if provided.
- **`require` and `process` only work in the Node executor** — `IsomorphicCodeRunner` throws immediately for either flag; `NotAllowedCodeRunner` rejects all execution.
- **`Rivet` arg is the full `../exports.js` namespace** (circular import allowed via eslint disable comment) — available when `includeRivet` is true.

## AI Assist Editor

- `CodeNodeAIAssistEditor` uses graph name `"Code Node Generator"` (maps to `code-node-generator.rivet-project`).
- AI outputs: `code` (string) + `configuration` (object with `inputs`, `outputs`, `allowFetch`, `allowRequire`, `allowProcess`, `allowRivet`). Note: `allowConsole` is NOT set by AI generation.
- `updateData` returns `null` (no update) if `code` output is missing; `getIsError` checks for `control-flow-excluded` on the `code` output.

## Critical Rules
- Never return a Promise from user code — `process()` checks `'then' in outputs` and throws if truthy.
- `inputNames`/`outputNames` can be `string | string[]` — always normalize with `Array.isArray` before processing.
- Adding a new capability flag: add to `CodeNodeData`, `CodeRunnerOptions`, `getEditors()`, and both `IsomorphicCodeRunner.runCode` and the Node executor's runner.

---
**Last Updated:** 2026-04-19
