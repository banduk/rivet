---
name: node-property-editors
description: Property editor components for node inputs — how editors are defined, rendered, and dispatch changes
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/components/editors/**`
- `packages/core/src/model/EditorDefinition.ts`

Keywords: EditorDefinition, DefaultNodeEditor, SharedEditorProps, getEditors, dataKey, useInputToggleDataKey

---

## Key Files
- `packages/core/src/model/EditorDefinition.ts` — union of all 19 editor definition types; add new type here
- `packages/app/src/components/editors/SharedEditorProps.ts` — `SharedEditorProps` base type used by all smart wrappers
- `packages/app/src/components/editors/DefaultNodeEditorField.tsx` — `ts-pattern` dispatch from editor type → component; **must add case here for every new editor type**
- `packages/app/src/components/editors/DefaultNodeEditor.tsx` — calls `getEditors()` on node impl and renders fields
- `packages/app/src/components/editors/editorUtils.ts` — `getHelperMessage()` util (sync only)

## Two-Level Pattern
Every editor type has two components:
- `Default<Type>Editor` — smart wrapper; extracts `node.data[editor.dataKey]`, builds onChange, passes `SharedEditorProps + { editor }`
- `<Type>Editor` — dumb UI; accepts primitive `value`/`onChange`/`isDisabled`/`isReadonly`; no node knowledge

## onChange Dispatch (always immutable spread)
```typescript
onChange({ ...node, data: { ...data, [editor.dataKey]: newValue } });
```

## Adding a New Editor Type
1. Add `MyEditorDefinition<T>` to union in `EditorDefinition.ts`
2. Create `packages/app/src/components/editors/MyEditor.tsx` with both components
3. Add `.with({ type: 'my' }, ...)` case in `DefaultNodeEditorField.tsx` match — it is `.exhaustive()`, so missing cases are compile errors

## Critical Rules
- `dataKey` is type-checked via `DataOfType<T, Type>` — it must reference a field of the matching type in `node.data`; wrong type → compile error
- `CustomEditor.tsx` has a **hardcoded** `ts-pattern` match for `customEditorId`; no plugin registry; must add case manually
- `CodeEditor` debounces onChange (100ms) and skips updates while focused to avoid cursor jumps — don't bypass this
- `getEditors()` may return a `Promise`; `DefaultNodeEditor` handles async — never assume sync
- `helperMessage` function in `EditorDefinition` is called synchronously; cannot fetch async data inside it
- `EditorGroup` (type `'group'`) spans full 2-column grid width; other editors assume single-column

## useInputToggle Pattern
Most definitions accept `useInputToggleDataKey: keyof T['data']`. When set, `DefaultNodeEditorField` renders a toggle that disables the editor and routes the value through an input port instead.

---
**Last Updated:** 2026-04-19
