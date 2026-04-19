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
- `packages/core/src/model/Dataset.ts` — core types: `DatasetId` (opaque string), `DatasetMetadata`, `Dataset`, `DatasetRow`
- `packages/core/src/integrations/DatasetProvider.ts` — `DatasetProvider` interface + `InMemoryDatasetProvider` reference implementation
- `packages/app/src/state/dataStudio.ts` — two atoms: `datasetsState` (`DatasetMetadata[]`) and `selectedDatasetState`

## Key Concepts

- **`DatasetRow`**: `{ id: string; data: string[]; embedding?: number[] }` — `data` is always `string[]` (columns), cast with `coerceType(d, 'string')` before storing
- **`DatasetProvider`** lives on `context.datasetProvider` — always null-check it in `process()` and throw if missing
- **`DatasetMetadata`** must include `projectId: context.project.metadata.id` when calling `putDatasetMetadata`
- **`datasetSelector` editor type**: used with `dataKey: 'datasetId'` and `useInputToggleDataKey: 'useDatasetIdInput'` — toggling the input hides/shows the port dynamically in `getInputDefinitions()`
- **KNN similarity**: `InMemoryDatasetProvider` uses dot-product (cosine for normalized vectors like OpenAI embeddings) — rows without `embedding` are excluded from KNN results
- **`getInputOrData`** utility: use instead of manual `coerceTypeOptional(inputs[...]) || this.data.x` for toggled inputs like `datasetId` and `k`

## Critical Rules

- `DatasetId` is an opaque type — cast with `as DatasetId`, never use plain `string` where `DatasetId` is required or TypeScript will accept it but semantics break
- `putDatasetRow` with an existing `id` **overwrites** the row — generating a new ID with `newId<DatasetId>()` is required for fresh appends
- `getDatasetData` returns `{ id, rows: [] }` (not `undefined`) when the dataset exists but has no rows; `getDatasetMetadata` returns `undefined` for a missing dataset — check metadata to verify existence
- Dataset nodes output `dataset` port as `object[]` (rows array) but `AppendToDatasetNode` outputs the single `DatasetRow` as `object` — match output type to actual value shape

## References
- **Patterns:** `.claude/guidelines/dataset-management/patterns.md`

---
**Last Updated:** 2026-04-19
