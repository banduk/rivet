---
name: ai-assisted-node-editing
description: AI assist editors for individual nodes and the AI graph builder (whole-graph generation)
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/components/editors/custom/*AiAssist*.tsx`
- `packages/app/src/hooks/useAiGraphBuilder.ts`
- `packages/app/src/components/AiGraphCreator*.tsx`
- `packages/app/src/state/ai.ts`

Keywords: AiAssistEditorBase, useAiGraphBuilder, selectedAssistModelState, graph-creator, rivet-project

---

You are working on **AI-assisted node editing** in Rivet — two related systems: per-node AI editors and whole-graph AI generation.

## Key Files
- `packages/app/src/components/editors/custom/AiAssistEditorBase.tsx` — generic base component `<TNodeData, TOutputs>`; all node AI editors extend this; hardcodes `code-node-generator.rivet-project`
- `packages/app/src/components/editors/CustomEditor.tsx` — routes `customEditorId` strings to specific AI editor components via `ts-pattern`
- `packages/app/src/hooks/useAiGraphBuilder.ts` — hook for whole-graph AI generation; exposes 12 external functions to the AI
- `packages/app/src/state/ai.ts` — `selectedAssistModelState` atom (persisted via `atomWithStorage`)
- `packages/app/src/utils/modelSelectorOptions.ts` — all valid `api:model` values
- `packages/app/graphs/code-node-generator.rivet-project` — single project file containing all per-node AI graphs
- `packages/app/graphs/graph-creator.rivet-project` — project file used exclusively by `useAiGraphBuilder`

## Key Concepts
- **`AiAssistEditorBase<TNodeData, TOutputs>`:** Receives `graphName` (must match a graph name inside `code-node-generator.rivet-project` exactly), `updateData(data, result) => TNodeData | null` (return `null` to abort applying changes), `getIsError`, `getErrorMessage`. Executes the named graph with inputs `{ prompt, model, api }`.
- **Model format:** Always `"api:model"` (e.g., `"anthropic:claude-sonnet-4-20250514"`). Split on `:` to get provider/model. Never pass the full string as a single model ID.
- **CustomEditor routing:** To register a new AI editor, add a `customEditorId` string to the node definition and add a matching `.with(...)` branch in `CustomEditor.tsx` using `ts-pattern`.
- **External functions (graph builder):** `useAiGraphBuilder` binds functions like `createNode`, `connectNodes`, `editNode`, `deleteNode`, `lintGraph` as Rivet external functions. Each must return `{ type: string; value: any }`. Call `showChanges()` after mutations to trigger UI updates.

## Critical Rules
- `getIsError` is checked first; `updateData` is only called if NOT an error. `updateData` returning `null` silently aborts the node update (e.g. when required output is missing).
- `graphName` must match a graph name inside `code-node-generator.rivet-project` exactly (e.g., `"Code Node Generator"`, `"Extract Regex Node Generator"`)
- New node AI editors must be added to both the node's editor definition AND `CustomEditor.tsx`
- `selectedAssistModelState` default is `modelSelectorOptions[4].value` (Claude Sonnet 4, `anthropic:claude-sonnet-4-20250514`) — don't hardcode a different default

## References
- **Patterns:** `.claude/skills/packages/skill.md`

---
**Last Updated:** 2026-04-19
