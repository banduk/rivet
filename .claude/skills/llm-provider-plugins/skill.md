---
name: llm-provider-plugins
description: Implementing LLM provider plugins (nodes + config) in rivet-core
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/plugins/*/plugin.ts`
- `packages/core/src/plugins/*/nodes/*.ts`
- `packages/core/src/plugins/*/index.ts`
- `packages/core/src/plugins.ts`
- `packages/app/src/plugins.ts`

Keywords: RivetPlugin, PluginNodeImpl, pluginNodeDefinition, configSpec, pullEnvironmentVariable, getPluginConfig, register

---

You are adding or modifying an **LLM provider plugin** in Rivet.

## Key Files
- `packages/core/src/model/RivetPlugin.ts` — `RivetPlugin` type (id, name, register, configSpec)
- `packages/core/src/model/NodeImpl.ts` — `PluginNodeImpl<T>` interface (7 required methods)
- `packages/core/src/model/NodeDefinition.ts` — `pluginNodeDefinition(impl, displayName)` helper
- `packages/core/src/plugins.ts` — central export; add new provider here
- `packages/app/src/plugins.ts` — UI metadata (logo, description, links); add `PluginInfo` entry here
- `packages/core/src/plugins/anthropic/` — canonical reference implementation

## Key Concepts
- **Plugin registration:** `plugin.register(register)` receives a typed `register` function; call it once per node definition created via `pluginNodeDefinition()`.
- **Config secrets:** Declare in `configSpec` with `type: 'secret'` and `pullEnvironmentVariable: 'ENV_VAR_NAME'`. Access in `process()` via `context.getPluginConfig('keyName')`.
- **Dynamic ports:** `getInputDefinitions()` and `getOutputDefinitions()` receive the node's current `data`, so ports can appear/disappear based on toggles (e.g. `useTemperatureInput`).
- **Streaming:** Use `async function*` generators yielding chunks; consume in `process()` and accumulate into `Outputs`.

## Critical Rules
- A new plugin must be exported in **both** `packages/core/src/plugins.ts` (runtime) and `packages/app/src/plugins.ts` (UI metadata) — omitting either causes the plugin to silently not appear.
- `PluginNodeImpl<T>` is an interface, not a class — export a plain object satisfying it, then wrap with `pluginNodeDefinition(impl, displayName)`.
- Config keys in `configSpec` (e.g. `anthropicApiKey`) must exactly match the string passed to `context.getPluginConfig(...)` — no runtime error if they differ, just `undefined`.
- Node data types follow the split pattern: `FooNodeConfigData` (serialized fields) + `FooNodeData = FooNodeConfigData & { useXInput: boolean; ... }` (UI state).

## References
- **Patterns:** `.claude/skills/packages/skill.md`

---
**Last Updated:** 2026-04-19
