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

- **Port names are masked:** `maskInput` strips non-`[a-zA-Z0-9_]` chars and deduplicates via `Set`. Port `id` in `getInputDefinitions`/`getOutputDefinitions` equals the masked name — the `inputs` object inside user code uses those same masked keys.
- **`inputs` are raw `DataValue` tagged unions** inside the code body — user must access `.type` and `.value` directly. Values are NOT unwrapped by the runtime before passing.
- **`process()` validates return shape** — all declared output port IDs must be present in the returned object or it throws. To skip an output use `{ type: 'control-flow-excluded', value: undefined }`; to return undefined use `{ type: 'any', value: undefined }`.
- **Execution is `new AsyncFunction(...argNames)(...)`.** Only explicitly enabled capabilities (`includeFetch`, `includeConsole`, etc.) are injected as named args — others are simply absent from the function scope.
- **`require` and `process` only work in the Node executor** — `IsomorphicCodeRunner` throws immediately if either flag is set. The browser executor uses `IsomorphicCodeRunner`; never assume `require` is available.
- **`Rivet` import causes a cycle** — `CodeRunner.ts` suppresses it with `eslint-disable-next-line import/no-cycle`. Do not add more cyclic imports here.

## Critical Rules
- Return object must include every declared output port or `process()` throws — no partial returns.
- `inputNames`/`outputNames` can be `string | string[]` — always normalize with `Array.isArray` before iterating (the node does this in `getInputDefinitions`).
- AI-assist editor calls `graphName: "Code Node Generator"` — that string must match the deployed graph name; changing it silently breaks AI generation.
- New `CodeRunnerOptions` flags require updates in **both** `CodeNode.ts` (data type + editor + `process()` call) and `CodeRunner.ts` (both `IsomorphicCodeRunner` and `NotAllowedCodeRunner`).

## References
- **Patterns:** `.claude/guidelines/code-execution-node/patterns.md`

---
**Last Updated:** 2026-04-19
