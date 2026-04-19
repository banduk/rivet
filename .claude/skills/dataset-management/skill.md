---
name: dataset-management
description: Dataset CRUD nodes, DatasetProvider interface, DatasetRow schema, and Data Studio UI state for rivet
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/model/nodes/*DatasetNode.ts`
- `packages/core/src/model/nodes/DatasetNearestNeigborsNode.ts`
- `packages/core/src/model/nodes/GetDatasetRowNode.ts`
- `packages/core/src/model/nodes/GetAllDatasetsNode.ts`
- `packages/core/src/model/nodes/ReplaceDatasetNode.ts`
- `packages/core/src/integrations/DatasetProvider.ts`
- `packages/app/src/state/dataStudio.ts`
- `packages/app/src/components/dataStudio/**`

Keywords: DatasetProvider, DatasetRow, DatasetId, datasetProvider, knnDatasetRows, datasetSelector, putDatasetRow, putDatasetMetadata

---

## Key Files
- `packages/core/src/model/Dataset.ts` — core types: `DatasetId` (opaque string via `type-fest`), `DatasetMetadata`, `Dataset`, `DatasetRow`
- `packages/core/src/integrations/DatasetProvider.ts` — `DatasetProvider` interface + `InMemoryDatasetProvider` reference implementation
- `packages/app/src/state/dataStudio.ts` — two atoms: `datasetsState` (`DatasetMetadata[]`) and `selectedDatasetState` (`DatasetId | undefined`)

## Key Concepts

- **`DatasetRow`**: `{ id: string; data: string[]; embedding?: number[] }` — `data` is always `string[]`; coerce with `coerceType(d, 'string')` before storing
- **`DatasetProvider`** lives on `context.datasetProvider` — always null-check in `process()` and throw `'datasetProvider is required'`
- **`DatasetMetadata`** requires `projectId: context.project.metadata.id` when calling `putDatasetMetadata`; `CreateDatasetNode` is the canonical example
- **`datasetSelector` editor**: use with `dataKey: 'datasetId'` and `useInputToggleDataKey: 'useDatasetIdInput'` — the toggle hides/shows the port in `getInputDefinitions()`
- **KNN**: `InMemoryDatasetProvider.knnDatasetRows` uses dot-product similarity (cosine for normalized vectors like OpenAI embeddings); rows without `embedding` are excluded
- **`getInputOrData`**: utility for reading a value from inputs or falling back to node data — use this instead of direct port access for toggleable fields
- **`ReplaceDatasetNode`** accepts `string[][]` (generates IDs) or `DatasetRow[]` (preserves IDs) — see its process() for the type-detection pattern
- **`GetDatasetRowNode`**: missing row returns `control-flow-excluded`, not an error

## Critical Rules
- Never call `datasetProvider` methods without null-checking first — `context.datasetProvider` is `undefined` in environments that don't supply one
- `DatasetId` is an opaque type — cast with `as DatasetId`, never construct raw strings as IDs without the cast
- `putDatasetMetadata` upserts: if metadata already exists it updates, otherwise it creates an empty dataset backing store
- KNN results include `distance` field (dot-product score, not Euclidean distance — higher = more similar)

## References
- **Patterns:** `.claude/guidelines/dataset-management/patterns.md`

---
**Last Updated:** 2026-04-19
