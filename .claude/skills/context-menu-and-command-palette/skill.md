---
name: context-menu-and-command-palette
description: Context menu system for the Rivet graph canvas — triggering, configuration, dispatch, and search
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/components/ContextMenu.tsx`
- `packages/app/src/hooks/useContextMenu.ts`
- `packages/app/src/hooks/useContextMenuConfiguration.ts`
- `packages/app/src/hooks/useContextMenuCommands.ts`
- `packages/app/src/hooks/useContextMenuAddNodeConfiguration.ts`
- `packages/app/src/hooks/useGraphBuilderContextMenuHandler.ts`

Keywords: ContextMenu, contextMenuType, useContextMenu, ContextMenuContext, handleContextMenu, hiddenUntilSearched

---

You are working on the **context menu system** in Rivet's graph canvas. There is no separate command palette — global commands (e.g., "go to graph") are integrated into context menu search.

## Key Files
- `packages/app/src/components/ContextMenu.tsx` — Renders menu with search (Fuse.js), submenus, info boxes, and keyboard nav; uses `@floating-ui/react` for placement
- `packages/app/src/hooks/useContextMenu.ts` — Manages open/close state; provides `handleContextMenu(event)` and escape-key listener
- `packages/app/src/hooks/useContextMenuConfiguration.ts` — Defines all menu contexts (`node`, `blankArea`, `graphList`, `graphListGraph`) and their items
- `packages/app/src/hooks/useContextMenuAddNodeConfiguration.ts` — Builds the categorized "Add Node" submenu dynamically from registered node types
- `packages/app/src/hooks/useContextMenuCommands.ts` — Generates global `go-to-graph:<graphId>` commands shown in search
- `packages/app/src/hooks/useGraphBuilderContextMenuHandler.ts` — Single dispatcher; uses `ts-pattern` to match item IDs and execute canvas actions

## Key Concepts
- **DOM trigger via `data-contextmenutype`:** Elements set `data-contextmenutype="node"` (plus `data-nodeid`) to declare what context a right-click produces. The hook walks up the DOM tree to find the nearest typed element.
- **Space bar = command palette:** `NodeCanvas` binds Space to open context menu at cursor — this IS the command palette.
- **`ContextMenuContext` discriminated union:** Typed by `type` field (`'node' | 'blankArea' | ...`); context is hydrated in `NodeCanvas` useMemo, not in the hook.
- **Item ID prefix routing:** Handler uses `ts-pattern` to match prefixes — `add-node:*`, `go-to-graph:*`. New actions need a unique prefix pattern added to the handler.
- **`data` can be a function:** `data?: Data | ((context: Context) => Data)` — evaluated at dispatch time, enabling context-dependent payloads.
- **`hiddenUntilSearched: true`:** Items like "Auto Layout" only appear in Fuse.js search results, not in the default rendered list.
- **`conditional?: (context) => boolean`:** Hides items from rendering entirely (not just greyed out). Used for "Run from here", "Go to subgraph", etc.

## Critical Rules
- Add new context menu items in `useContextMenuConfiguration.ts` and handle them in `useGraphBuilderContextMenuHandler.ts` — both must be updated together.
- New canvas elements that need a context menu **must** set `data-contextmenutype` on their DOM element; forgetting this silently falls back to `blankArea`.
- Do not add a separate command palette component — extend `useContextMenuCommands.ts` instead.
- Item IDs must be globally unique across all context types (they flow into a single handler).

## References
- **Patterns:** `.claude/guidelines/context-menu-and-command-palette/patterns.md`

---
**Last Updated:** 2026-04-19
