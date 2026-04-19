---
name: prompt-designer
description: Prompt Designer overlay — ad-hoc chat testing, test groups, and evaluator graphs attached to Chat nodes
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/components/PromptDesigner.tsx`
- `packages/app/src/state/promptDesigner.ts`
- `packages/app/src/hooks/useGetAdHocInternalProcessContext.ts`

Keywords: promptDesigner, PromptDesignerRenderer, promptDesignerAttachedChatNodeState, runAdHocChat, useRunTestGroup

---

You are working on the **Prompt Designer** — a full-screen overlay for testing Chat node prompts interactively without running the full graph.

## Key Files
- `packages/app/src/components/PromptDesigner.tsx` — all UI: message editor, config panel, test groups, result display
- `packages/app/src/state/promptDesigner.ts` — five Jotai atoms for messages, response, config, attached node, and test results
- `packages/app/src/hooks/useGetAdHocInternalProcessContext.ts` — builds a minimal `InternalProcessContext` for browser execution outside the graph runner

## Key Concepts
- **Overlay activation:** `overlayOpenState` (from `packages/app/src/state/ui.ts`) is set to `'promptDesigner'`; `PromptDesignerRenderer` renders only when that value matches. Opening is triggered from `NodeOutput.tsx` via `handleOpenPromptDesigner`.
- **Attached node:** `promptDesignerAttachedChatNodeState` stores `{ nodeId, processId }`. On first attach to a new node, the component syncs `ChatNodeConfigData` and pre-fills messages from `lastRunDataByNodeState` via `getChatNodeMessages`.
- **Ad-hoc execution:** `runAdHocChat` constructs a bare `ChatNodeImpl` with all `use*Input` flags set to `false`, processes it with the ad-hoc context; result streams via `onPartialResult`.
- **Test groups:** Stored as `NodeTestGroup[]` on the `ChatNode` itself (`attachedNode.tests`). Each group has an `evaluatorGraphId` (a `GraphSelector`), conditions (string array), and runs N samples in parallel via `useRunTestGroupSampleCount`. The evaluator graph receives `conditions` (string[]) and `input` (string) ports; must output `output` (boolean[]).
- **Results keyed by nodeId:** `promptDesignerTestGroupResultsByNodeIdState` is a plain object `{ [nodeId]: PromptDesignerTestGroupResults[] }` — cleared on each new run start.

## Critical Rules
- `useGetAdHocInternalProcessContext` returns a context with `executor: 'browser'` and many lifecycle functions set to `undefined!` — it is only valid for single-node ad-hoc calls, not full graph runs that use `raiseEvent`, `setGlobal`, etc.
- Evaluator graph receives exactly two ports: `'conditions' as PortId` (string[]) and `'input' as PortId` (string). Output must be `'output' as PortId` (boolean[]). Mismatched port IDs silently return all-false results.
- The `lastPromptDesignerAttachedNodeState` local atom prevents re-syncing config when the same node is re-selected; clear it or change `attachedNodeId` to force a resync.
- Message type cycling order is fixed: `['user', 'assistant', 'system', 'function']` — clicking the type button rotates through this array.

## References
- **Patterns:** `.claude/skills/base/skill.md`

---
**Last Updated:** 2026-04-19
