---
name: data-extraction-and-transform
description: Patterns for extraction nodes (JSON/YAML/regex/object-path) and transform nodes (split/chunk/filter/slice) in rivet-core
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/model/nodes/Extract*.ts`
- `packages/core/src/model/nodes/FilterNode.ts`
- `packages/core/src/model/nodes/ChunkNode.ts`
- `packages/core/src/model/nodes/SplitNode.ts`
- `packages/core/src/model/nodes/SliceNode.ts`

Keywords: extractJson, extractRegex, extractObjectPath, extractYaml, FilterNode, ChunkNode, SplitNode, coerceType, expectType, control-flow-excluded

---

## No-Match Output Pattern

When extraction fails, emit `control-flow-excluded` on the "found" port and the original input on the "no match" port — **not** an error. Both ports must always be present in the returned `Outputs` object even when one is excluded.

## expectType vs coerceType

- `expectType(input, 'string')` — throws if wrong type; use for strict extraction inputs
- `coerceType(input, 'string')` — converts; use for transform inputs where the type may vary
- `coerceTypeOptional` / `expectTypeOptional` — return `undefined` instead of throwing on missing input

## Dynamic Ports from Data

`ExtractRegexNode.getOutputDefinitions()` counts regex capture groups and emits `output1`, `output2`, etc. dynamically. Port IDs must exactly match what `process()` writes — a mismatch silently drops the value.

## Toggle-Input Pattern

`useXxxInput` boolean in node data controls whether a port appears in `getInputDefinitions()`. Editors link via `useInputToggleDataKey: 'useXxxInput'`. Always read the data field first, fall back to input port: `expectTypeOptional(inputs['x'], 'string') ?? this.data.x`.

## JSONPath (ExtractObjectPathNode / ExtractYamlNode)

Uses `jsonpath-plus`: `JSONPath({ json, path, wrap: true })` — `wrap: true` always returns an array; empty array means no match. Pass `inputObject ?? null` because JSONPath doesn't handle `undefined`.

## ChunkNode Requires Tokenizer

`process()` signature is `(inputs, context: InternalProcessContext)` — calls `context.tokenizer.getTokenCountForString()`. Nodes needing tokenization must accept the second context arg; nodes that don't can omit it.

## Filter Preserves Array Type

`FilterNode` preserves the upstream type: `inputs['array']?.type ?? 'any'` as the output `type` field. Do the same for any pass-through transform to avoid losing type info downstream.

## Utility Shorthand

`getInputOrData(this.data, inputs, 'key')` (from `../../utils/index.js`) reads the input port if connected, otherwise falls back to the data field — use instead of manual `?? this.data.x` when both exist.

## References
- **Patterns:** `.claude/guidelines/packages/patterns.md`

---
**Last Updated:** 2026-04-19
