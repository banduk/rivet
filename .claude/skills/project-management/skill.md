---
name: project-management
description: Loading, saving, and managing Rivet .rivet-project files — serialization, atoms, and multi-project state
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/state/savedGraphs.ts`
- `packages/app/src/hooks/useLoadProject.ts`
- `packages/app/src/hooks/useSaveProject.ts`
- `packages/app/src/hooks/useNewProject.ts`
- `packages/app/src/hooks/useLoadProjectWithFileBrowser.ts`
- `packages/core/src/model/Project.ts`
- `packages/core/src/utils/serialization/**`

Keywords: projectState, loadedProjectState, projectDataState, serializeProject, deserializeProject, ProjectMetadata, mainGraphId, rivet-project

---

You are working on **Rivet project management** — loading/saving `.rivet-project` files, project state atoms, and multi-project tab support.

## Key Files
- `packages/core/src/model/Project.ts` — `Project`, `ProjectMetadata`, `ProjectReference` types; `mainGraphId` is the entry-point graph
- `packages/core/src/utils/serialization/serialization.ts` — `serializeProject()` (v4 YAML), `deserializeProject()` (tries v4→v3→v2→v1 fallback)
- `packages/core/src/utils/serialization/serialization_v4.ts` — Current format: `{ version: 4, data: SerializedProject }`; node visual data encoded as compact `"x/y/width/zIndex"` string
- `packages/app/src/state/savedGraphs.ts` — All project atoms: `projectState`, `projectDataState`, `loadedProjectState`, `projectsState` (multi-tab), `projectMetadataState`
- `packages/app/src/hooks/useLoadProject.ts` — Loads project into atoms; fetches test data from filesystem
- `packages/app/src/hooks/useSaveProject.ts` — Saves with graphs + test data; saves >500ms show toast
- `packages/app/src/hooks/useNewProject.ts` — Creates blank project + resets all state + initializes one empty graph

## Key Concepts
- **Multi-project tabs:** `projectsState` tracks all open projects; `openedProjectsSortedIdsState` controls tab order. Each project has its own atom family keyed by `ProjectId`.
- **Separate data atom:** `projectDataState` stores large binary/dataset records separately from `projectState` to avoid serializing them into the main YAML.
- **Hybrid storage:** Atoms persist via `createHybridStorage` — IndexedDB with localStorage fallback.
- **Versioned deserialization:** Always goes through `deserializeProject()` in `serialization.ts`; never call a versioned deserializer directly.
- **Graph IDs:** Graphs without IDs get `nanoid()` auto-assigned when loaded into `savedGraphsState`.

## Critical Rules
- **No cyclic `ProjectReference`s** — the loader does not guard against cycles; the caller must validate.
- **`mainGraphId`** must reference an existing graph in the project; it designates the execution entry point.
- **Duplicate guard in `useLoadProjectWithFileBrowser`:** rejects projects already open by same path OR same `ProjectId`.
- **Never serialize `projectDataState` directly** — it's intentionally kept out of the main YAML payload.
- New serialization format must increment `version` and add a fallback branch in `deserializeProject()`.

## References
- **Patterns:** `.claude/skills/base/skill.md`

---
**Last Updated:** 2026-04-19
