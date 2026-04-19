---
name: node-clipboard-copy-paste
description: Copy/paste and duplicate nodes on the graph canvas — clipboard atom, hooks, hotkeys, and context menu wiring
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/state/clipboard.ts`
- `packages/app/src/hooks/useCopyNodes.ts`
- `packages/app/src/hooks/usePasteNodes.ts`
- `packages/app/src/hooks/useCopyNodesHotkeys.ts`
- `packages/app/src/hooks/useGraphBuilderContextMenuHandler.ts`

Keywords: clipboardState, useCopyNodes, usePasteNodes, NodesClipboardItem, pasteNodes, copyNodes

---

You are working on **node clipboard copy/paste** in Rivet's visual graph editor.

## Key Files
- `packages/app/src/state/clipboard.ts` — `clipboardState` Jotai atom; type `ClipboardItem = NodesClipboardItem` (union for future extension)
- `packages/app/src/hooks/useCopyNodes.ts` — reads `selectedNodesState` + `connectionsState`; writes `clipboardState`; only copies connections where BOTH endpoints are selected
- `packages/app/src/hooks/usePasteNodes.ts` — reads `clipboardState`; remaps all node IDs via `newId<NodeId>()`; positions pasted nodes relative to mouse via `clientToCanvasPosition`; selects newly pasted nodes
- `packages/app/src/hooks/useCopyNodesHotkeys.ts` — wires Cmd/Ctrl+C, Cmd/Ctrl+V, Cmd/Ctrl+D to copy/paste/duplicate; guards skip when `editingNodeState` is set or focus is in `input`/`textarea`
- `packages/app/src/hooks/useGraphBuilderContextMenuHandler.ts` — context menu entry points for copy/paste/duplicate
- `packages/app/src/utils/copyToClipboard.ts` — separate utility for copying plain text to OS clipboard via `navigator.clipboard.writeText`; unrelated to node clipboard

## Key Concepts
- **In-memory clipboard only:** `clipboardState` is a plain Jotai atom (not persisted); clipboard does not survive page reload and is not the OS clipboard.
- **ID remapping on paste:** every pasted node gets a fresh `newId<NodeId>()`; connections are remapped through `oldNewNodeIdMap` — connections with missing endpoints are dropped.
- **Bounding box alignment:** paste positions the top-left corner of the copied node group at the current mouse position on canvas.
- **`ClipboardItem` is a union:** currently only `NodesClipboardItem`; adding new clipboard types means adding a new union member and handling it in `usePasteNodes`.

## Critical Rules
- Always remap node IDs when pasting — reusing existing IDs corrupts graph state.
- Only include connections where both `inputNodeId` and `outputNodeId` are in the copied set; partial connections cause dangling references.
- `usePasteNodes` returns a function that takes `{ x, y }` in **client/screen** coordinates, not canvas coordinates — it calls `clientToCanvasPosition` internally.
- Hotkeys must check `editingNodeState` before acting to avoid intercepting text input in node editors.

## References
- **Patterns:** `.claude/skills/base/skill.md`

---
**Last Updated:** 2026-04-19
