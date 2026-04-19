---
name: http-client-node
description: HttpCallNode implementation — fetch-based HTTP node with port/data duality pattern
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/model/nodes/HttpCallNode.ts`

Keywords: HttpCallNode, httpCall, http_call, HttpCallNodeData

---

You are working on **HttpCallNode** — the built-in node for making HTTP requests from a Rivet graph.

## Key Files
- `packages/core/src/model/nodes/HttpCallNode.ts` — full node implementation (type, impl class, export)

## Key Concepts
- **Port/data duality:** every field has a static `data.X` value AND a `useXInput` boolean toggle. `getInputDefinitions()` conditionally pushes ports based on those flags. `getInputOrData()` resolves them at runtime.
- **Header input:** accepts `string` (JSON), `object`, or coerced — handled explicitly in `process()` because the port dataType is `object` but users may wire a string.
- **Body input port ID is `req_body`**, output body port is `res_body` — asymmetric naming, don't use `body`.
- **Binary mode:** toggling `isBinaryOutput` swaps output ports entirely (`binary` replaces `res_body`+`json`). `getOutputDefinitions()` branches on this flag.
- **`json` port outputs `control-flow-excluded`** when `Content-Type` is not `application/json` — never output `undefined` directly.
- **`context.signal`** is passed to `fetch()` for cancellation — always forward it.
- **CORS error detection:** catches `"Load failed"` / `"Failed to fetch"` and suggests switching to node executor when `context.executor === 'browser'`.

## Critical Rules
- `errorOnNon200` is wired in `HttpCallNodeData` but NOT currently enforced in `process()` — if implementing it, throw after checking `response.ok`.
- Port IDs are cast with `as PortId` — never use plain strings for port lookups.
- `method` supports only GET/POST/PUT/DELETE — the dropdown editor enforces this; keep `HttpCallNodeData.method` typed as a union.
- Node type string is `'httpCall'` (camelCase) — used as the discriminant in `ChartNode<'httpCall', ...>`.

## References
- **Patterns:** `.claude/skills/packages/skill.md` (NodeImpl pattern, DataValue system, Command pattern)

---
**Last Updated:** 2026-04-19
