---
name: vector-search-and-embeddings
description: Vector store operations, nearest-neighbor search, and embedding generation via pluggable integration providers
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/model/nodes/VectorStoreNode.ts`
- `packages/core/src/model/nodes/VectorNearestNeighborsNode.ts`
- `packages/core/src/model/nodes/GetEmbeddingNode.ts`
- `packages/core/src/integrations/EmbeddingGenerator.ts`
- `packages/core/src/integrations/VectorDatabase.ts`
- `packages/core/src/integrations/integrations.ts`

Keywords: VectorDatabase, EmbeddingGenerator, getIntegration, registerIntegration, vectorStore, getEmbedding, vectorNearestNeighbors, VectorDataValue

---

## Key Files
- `packages/core/src/integrations/integrations.ts` — global registry; `registerIntegration` / `getIntegration` by type + key
- `packages/core/src/integrations/EmbeddingGenerator.ts` — interface: `generateEmbedding(text, options?) => Promise<number[]>`
- `packages/core/src/integrations/VectorDatabase.ts` — interface: `store(collection, vector, data, metadata)` + `nearestNeighbors(collection, vector, k)`
- `packages/core/src/model/nodes/GetEmbeddingNode.ts` — calls `getIntegration('embeddingGenerator', name, context)`; outputs `{ type: 'vector', value: number[] }`
- `packages/core/src/model/nodes/VectorStoreNode.ts` — calls `getIntegration('vectorDatabase', name, context)`; default integration: `'pinecone'`
- `packages/core/src/model/nodes/VectorNearestNeighborsNode.ts` — KNN search; returns `ArrayDataValue<ScalarDataValue>` as `results`

## Key Concepts
- **Integration registry:** Providers are registered at startup via `registerIntegration(type, key, factory)` where factory is `(context: InternalProcessContext) => Interface`. Nodes call `getIntegration(type, key, context)` at process-time — throws if not registered.
- **`vector` DataValue type:** Embedding outputs and vector inputs use `{ type: 'vector', value: number[] }`. Always cast with `as VectorDataValue` and guard with `inputs[portId]?.type !== 'vector'` before passing to DB methods (see VectorStoreNode:142).
- **Collection ID passed as DataValue:** `vectorDb.store` and `nearestNeighbors` receive `collection` as `{ type: 'string', value: indexUrl }`, not a raw string.
- **`getInputOrData` helper:** Use `getInputOrData(this.data, inputs, 'fieldName')` to resolve editor-configured-or-port-toggled values (see VectorStoreNode:138–140).
- **Default integrations:** `GetEmbeddingNode` defaults to `'openai'`; `VectorStoreNode` and `VectorNearestNeighborsNode` default to `'pinecone'`. New integration keys must be added to the editor `options` array and registered externally.

## Critical Rules
- Implementing a new `VectorDatabase` or `EmbeddingGenerator`: call `registerIntegration` before any graph runs — not lazily inside `process()`.
- Do NOT add the integration key string to `IntegrationFactories` type — it is opaque; only `IntegrationType` (`vectorDatabase` | `embeddingGenerator` | `llmProvider`) is typed.
- `nearestNeighbors` returns `ArrayDataValue<ScalarDataValue>` — return it directly as `DataValue` without re-wrapping.

## References
- **Patterns:** `.claude/guidelines/packages/patterns.md`

---
**Last Updated:** 2026-04-19
