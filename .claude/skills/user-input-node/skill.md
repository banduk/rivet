---
name: user-input-node
description: UserInputNode implementation, modal UI, and process context wiring for runtime user prompts
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/model/nodes/UserInputNode.ts`
- `packages/app/src/components/UserInputModal.tsx`
- `packages/app/src/components/nodes/UserInputNode.tsx`
- `packages/app/src/state/userInput.ts`

Keywords: userInput, UserInputNode, requestUserInput, userInputModal, questionsAndAnswers

---

You are working on **the UserInput node** — a node that pauses graph execution to collect live user responses via a modal dialog.

## Key Files
- `packages/core/src/model/nodes/UserInputNode.ts` — node logic; calls `context.requestUserInput(questions, renderingFormat)`
- `packages/core/src/model/ProcessContext.ts:141` — `requestUserInput` defined on `InternalProcessContext`
- `packages/app/src/state/userInput.ts` — Jotai atoms: `userInputModalQuestionsState`, `userInputModalSubmitState`, `lastAnswersState` (persisted)
- `packages/app/src/components/UserInputModal.tsx` — modal UI; renders questions as markdown or preformatted `<pre>` based on node's `renderingFormat`
- `packages/app/src/components/nodes/UserInputNode.tsx` — `OutputSimple` descriptor showing `questionsAndAnswers` port
- `packages/app/src/components/GraphBuilder.tsx` — wires modal open/close/submit to `userInputModalSubmitState`

## Key Concepts
- **Two output ports:** `output` (answers only, `string[]`) and `questionsAndAnswers` (zipped Q+A strings, `string[]`)
- **Dynamic inputs:** when `useInput: true`, accepts a `questions` port (`string[]`); otherwise uses static `prompt` string
- **`renderingFormat`:** `'markdown'` (default) renders via `useMarkdown` hook; `'preformatted'` renders in `<pre>`
- **Last answers persistence:** `lastAnswersState` (atomWithStorage) pre-fills answers by question text across runs
- **`questionsNodeId`:** modal looks up the node across all graphs to read `renderingFormat`; missing node shows a warning but doesn't crash

## Critical Rules
- `requestUserInput` returns `StringArrayDataValue` (`{ type: 'string[]', value: string[] }`), not raw strings — match this shape exactly
- The `renderingFormat` field on `UserInputNodeData` maps to `'text' | 'markdown'` in the process context call: `'preformatted'` → `'text'`, `'markdown'` → `'markdown'`
- `userInputModalQuestionsState` is keyed by `NodeId` → `ProcessQuestions[]`; `GraphBuilder` takes the first entry (`entries(allCurrentQuestions)[0]`) and opens the modal automatically
- Cmd/Ctrl+Enter in the modal editor submits (keyCode `3` in Monaco)

## References
- **Patterns:** `.claude/skills/packages/skill.md`

---
**Last Updated:** 2026-04-19
