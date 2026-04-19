```markdown
---
name: ai-graph-builder
description: Whole-graph AI generation via useAiGraphBuilder — exposes 13 external functions for Claude/GPT to build graphs iteratively
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/hooks/useAiGraphBuilder.ts`
- `packages/app/src/components/AiGraphCreator*.tsx`
- `packages/app/graphs/graph-creator.rivet-project`
- `packages/app/graphs/graph-creator.rivet-data`

Keywords: useAiGraphBuilder, applyPrompt, externalFunctions, graph-creator, showAiGraphCreatorInputState

---

You are working on **AI-assisted whole-graph generation** in Rivet — the system that lets an LLM iteratively build a graph by calling external functions.

## Key Files
- `packages/app/src/hooks/useAiGraphBuilder.ts` — core hook (548 lines); defines all 13 external functions and processor setup
- `packages/app/src/components/AiGraphCreatorInput.tsx` — modal UI; owns `showAiGraphCreatorInputState` atom and AbortController
- `packages/app/src/components/AiGraphCreatorToggle.tsx` — sparkle button (fixed bottom-left) that toggles the modal
- `packages/app/src/state/ai.ts` — `selectedAssistModelState` atom (persisted); default `'anthropic:claude-sonnet-4-20250514'`
- `packages/app/src/utils/modelSelectorOptions.ts` — `modelSelectorOptions` array and `ModelSelectorValue` type
- `packages/app/graphs/graph-creator.rivet-project` — rivet project executed by the hook; named graph `"Main"` is the entry point

## Key Concepts
- **`useAiGraphBuilder({ record, onFeedback })`** returns `applyPrompt(prompt, modelAndApi, abort)`. The hook never exports UI state — the modal owns that separately.
- **Model format:** always `"api:model"` string (e.g. `"anthropic:claude-opus-4-5"`). Split on `:` to get `[api, model]` — this split happens in both `useAiGraphBuilder` and `AiAssistEditorBase`.
- **Working graph pattern:** `cloneDeep(graphState)` at start → all mutations go to `workingGraph` → call `setGraph(workingGraph)` only when committing. Never mutate graphState directly during execution.
- **`showChanges()` must follow mutations:** calls `autoLayout()` + `centerView()`; without it the canvas won't update visually.
- **Processor inputs:** `{ request, graph: JSON.stringify(workingGraph), model, api, allNodeTypes }` — `allNodeTypes` comes from `globalRivetNodeRegistry`.
- **User events from the running graph:** `runningCommands` → `onFeedback`; `updateUser` → `onFeedback`; `finalMessage` → toast notification.

## External Functions (13 total)
`createNode`, `connectNodes`, `disconnectNodes`, `getSerializedGraph`, `getPorts`, `editNode`, `getNodeData`, `deleteNode`, `addNodeData`, `lintGraph`, `toggleSplitting`, `showChanges`

- `editNode(nodeId, key, value)` — key **must already exist** on `node.data`; use `addNodeData` to create new keys
- `connectNodes` validates: port exists on both sides, input port has no existing source, types are compatible
- `lintGraph` runs DFS island detection + connection validity + type checks; returns `string[]` of warnings

## Critical Rules
- The `.rivet-project` file is binary-ish JSON — do not hand-edit; modify via the Rivet UI or by updating the hook's external function logic in TypeScript.
- Adding a new external function requires: (1) adding to the `externalFunctions` record in the hook, (2) updating the `graph-creator.rivet-project` to call it, (3) adding a case to the `runningCommands` event handler for feedback labeling.
- Keyboard trigger (Ctrl/Cmd+I) is registered in `useCanvasHotkeys.ts`, not in the AI graph builder files — change there if rebinding.
- Recordings saved to `AppLog/recordings/` when `record: true`; error recordings use prefix `error-` and are always saved on failure.

## References
- **Base conventions:** `.claude/skills/base/skill.md`
- **Node editor AI assist (per-node):** `.claude/skills/ai-assisted-node-editing/skill.md`

---
**Last Updated:** 2026-04-19
```
