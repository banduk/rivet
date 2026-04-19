---
name: llm-chat-nodes
description: ChatNode, ChatLoopNode, AssemblePromptNode, AssembleMessageNode — LLM chat completion and prompt assembly nodes
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/model/nodes/ChatNode.ts`
- `packages/core/src/model/nodes/ChatLoopNode.ts`
- `packages/core/src/model/nodes/ChatNodeBase.ts`
- `packages/core/src/model/nodes/AssemblePromptNode.ts`
- `packages/core/src/model/nodes/AssembleMessageNode.ts`
- `packages/core/src/model/nodes/TrimChatMessagesNode.ts`

Keywords: ChatNodeBase, ChatNodeData, ChatNodeConfigData, AssemblePromptNode, AssembleMessageNode, chatCompletions, streamChatCompletions, isCacheBreakpoint

---

## Key Files
- `ChatNodeBase.ts` — static object (not a class) holding all shared logic: `defaultData()`, `getInputDefinitions(data)`, `getOutputDefinitions(data)`, `getEditors()`, `getBody(data)`, `process(data, chartNode, inputs, context)`
- `ChatNode.ts` — thin wrapper; delegates every method to `ChatNodeBase`
- `ChatLoopNode.ts` — extends `ChatNodeData` with `userPrompt`/`renderingFormat`; overrides `getOutputDefinitions` and `process` only; delegates rest to `ChatNodeBase`
- `AssemblePromptNode.ts` — collects `message1..N` ports into `chat-message[]`; dynamic port count from connections
- `AssembleMessageNode.ts` — collects `part1..N` ports into one `chat-message`; dynamic port count from connections

## Key Concepts

- **`useXInput` pattern:** Every `ChatNodeData` config field has a paired `useXInput: boolean`. When true, `getInputDefinitions` adds the corresponding port. Always use `getInputOrData(data, inputs, key, type)` to read — never access `inputs[key]` directly.
- **Dynamic ports (Assemble nodes):** Port count = `maxConnectedIndex + 1` (always one extra empty slot). Computed by filtering `connections` for the node's id and parsing the numeric suffix from port ids.
- **`prompt` input** accepts `['chat-message', 'chat-message[]']` as coerced type — `ChatLoopNode.process` coerces it with `coerceType(inputs['prompt'], 'chat-message[]')`.
- **Cache breakpoint:** Set `outMessages.at(-1)!.isCacheBreakpoint = true` for Anthropic prompt caching when `isLastMessageCacheBreakpoint` is enabled (done in `AssemblePromptNode`).
- **Token counting:** `context.tokenizer.getTokenCountForMessages(messages, undefined, { node: this.chartNode })` — pass `{ node }` as `TokenizerCallInfo`.
- **`p-retry`** wraps API calls in `ChatNodeBase.process` — add retries there, not in callers.
- **`responseFormat: 'json_schema'`** adds a required `responseSchema` input port — adding new conditional ports must follow this guard pattern.

## Critical Rules

- **Never duplicate logic between `ChatNode` and `ChatLoopNode`** — all shared behavior lives in `ChatNodeBase`; both delegate to it.
- `ChatNodeBase` is a **plain object with static methods**, not a class — do not convert it to a class or extend it.
- Assemble nodes compute port count from `connections` passed to `getInputDefinitions` — do not store port count in node data.
- `getOutputDefinitions` in `ChatNodeBase` has return type annotated as `NodeInputDefinition[]` (a bug in the source) — match it when editing.

## References
- **Patterns:** `.claude/guidelines/packages/patterns.md`

---
**Last Updated:** 2026-04-19
