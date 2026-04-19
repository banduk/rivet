---
name: visual-graph-canvas
description: Node canvas rendering, pan/zoom, wire drawing, and port positioning in Rivet's graph editor
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/components/NodeCanvas.tsx`
- `packages/app/src/components/VisualNode.tsx`
- `packages/app/src/components/WireLayer.tsx`
- `packages/app/src/components/Wire.tsx`
- `packages/app/src/components/Port.tsx`
- `packages/app/src/components/DraggableNode.tsx`
- `packages/app/src/hooks/useCanvasPositioning.ts`
- `packages/app/src/hooks/useNodePortPositions.ts`
- `packages/app/src/hooks/useDraggingNode.ts`
- `packages/app/src/hooks/useDraggingWire.ts`

Keywords: canvas, NodeCanvas, VisualNode, WireLayer, canvasPosition, draggingWire, port, PortId, canvasPositionState

---

## Key Files
- `packages/app/src/components/NodeCanvas.tsx` — root canvas, pan/zoom/select logic (855 lines)
- `packages/app/src/components/VisualNode.tsx` — single node renderer, zoom-aware content switching
- `packages/app/src/components/WireLayer.tsx` — SVG layer for connections + partial wire during drag
- `packages/app/src/hooks/useCanvasPositioning.ts` — `clientToCanvasPosition` / `canvasToClientPosition`
- `packages/app/src/hooks/useNodePortPositions.ts` — DOM traversal to map port elements to canvas coordinates
- `packages/app/src/hooks/useDraggingWire.ts` — wire drag FSM: start → hover → connect
- `packages/app/src/state/graphBuilder.ts` — `canvasPositionState`, `selectedNodesState`, `draggingWireState`, `draggingWireClosestPortState`

## Coordinate System
- `canvasPosition = {x, y, zoom}` — CSS transform is `scale(zoom) translate(x, y)` (translation is **pre-zoom**)
- Canvas → Client: `(x + pos.x) * zoom`; Client → Canvas: `x / zoom - pos.x`
- Node `visualData.{x,y}` are in canvas space; mouse events arrive in client space — always convert

## Wire Rendering
- Forward wire (sx ≤ ex): cubic Bézier; backward wire: S-curve with horizontal mid-segment
- Wires culled below zoom 0.15; `lineCrossesViewport()` filters off-screen paths before render
- `NodeConnection` has `outputNodeId/outputId → inputNodeId/inputId`; input ports accept only one connection

## Wire Dragging
- Drag from input port: automatically breaks existing connection and re-starts from source output
- Wire direction auto-reverses on drop (output→input always); Ctrl/Cmd held = multi-connect mode
- Closest-port detection uses `document.elementsFromPoint()` scanning `.port-hover-area` elements

## Node Dragging
- Uses dnd-kit `useDraggable`; pixel deltas divided by zoom before applying (`delta.x / zoom`)
- Multi-select drag: all `selectedNodesState` nodes move together
- Dragging node gets `zIndex = maxZIndex + 1`; positions commit via `moveNodeCommand` on drag end

## Performance Rules
- Below zoom 0.4: `ZoomedOutVisualNodeContent` replaces normal content
- Viewport culling adds 300px (horiz) / 500px (vert) padding; pinned nodes always render
- Port positions computed via `useLayoutEffect` on every render (no deps); deduplication via state diff prevents spurious wire redraws
- Canvas mousemove throttled 10ms; zoom throttled 25ms

## Critical Rules
- Port positions come from DOM traversal, not stored state — never hardcode or cache across renders without the hook
- `PortId` is opaque and only unique within a node; always pair with `NodeId` for lookups
- `$if` (`IF_PORT`) is a built-in conditional input available on all nodes — don't add a new "if" port concept

## References
- **Patterns:** `.claude/skills/packages/skill.md`

---
**Last Updated:** 2026-04-19
