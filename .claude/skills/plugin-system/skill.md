---
name: plugin-system
description: Plugin authoring, registration, and loading for Rivet's node extension system
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/plugins/**`
- `packages/core/src/model/RivetPlugin.ts`
- `packages/core/src/model/NodeDefinition.ts`
- `packages/core/src/model/NodeImpl.ts`
- `packages/core/src/model/NodeRegistration.ts`
- `packages/app/src/hooks/useProjectPlugins.ts`
- `packages/app/src/plugins.ts`

Keywords: RivetPlugin, PluginNodeImpl, pluginNodeDefinition, registerPlugin, PluginLoadSpec, configSpec

---

You are working on the **Rivet plugin system** — how external and built-in nodes are defined, registered, and loaded.

## Key Files
- `packages/core/src/model/RivetPlugin.ts` — `RivetPlugin` type: `id`, `name`, `register`, `configSpec`, `contextMenuGroups`
- `packages/core/src/model/NodeImpl.ts` — `PluginNodeImpl<T>` interface all node impls must satisfy
- `packages/core/src/model/NodeDefinition.ts` — `pluginNodeDefinition(impl, displayName)` helper; `PluginNodeDefinition<T>` type
- `packages/core/src/model/NodeRegistration.ts` — `registerPlugin()` wraps each node in `PluginNodeImplClass`; throws on duplicate `type` strings
- `packages/core/src/plugins.ts` — exports `plugins` object (8 built-in plugins keyed by id)
- `packages/app/src/hooks/useProjectPlugins.ts` — loads plugins per `PluginLoadSpec` and calls `globalRivetNodeRegistry.registerPlugin()`
- `packages/app/src/plugins.ts` — UI metadata (`BuiltInPluginInfo`, `PackagePluginInfo`) for plugin display

## Key Concepts
- **`RivetPlugin`:** `register(cb)` calls `cb(pluginNodeDefinition(impl, displayName))` for each node; `configSpec` maps key → `StringPluginConfigurationSpec | SecretPluginConfigurationSpec`
- **`PluginNodeImpl<T>`:** Must implement `create()`, `getInputDefinitions()`, `getOutputDefinitions()`, `process()`, `getEditors()`, `getBody()`, `getUIData()`
- **`PluginLoadSpec`:** Union of `{ type: 'built-in', id }` | `{ type: 'uri', uri }` | `{ type: 'package', ... }`; URI/package types receive `Rivet` API and return `RivetPlugin`
- **`RivetPluginInitializer`:** External plugin entry point — `(rivet: typeof Rivet) => RivetPlugin`; use `rivet.pluginNodeDefinition()` instead of direct import to stay version-safe
- **`resetGlobalRivetNodeRegistry()`:** Called before reloading plugins; must be called or stale nodes persist across reloads

## Critical Rules
- Node `type` string must be globally unique — duplicate types throw at `registerPlugin()` time
- `configSpec` secrets use `pullEnvironmentVariable` to auto-populate from env; built-in plugins follow `UPPER_SNAKE_CASE` env var naming
- `contextMenuGroups` id must match `group` field in `NodeUIData.group` for nodes to appear under that group in the context menu
- External plugins (`uri`/`package`) must export a default `RivetPluginInitializer`, not a bare `RivetPlugin`
- Built-in plugins live under `packages/core/src/plugins/{name}/` and export from `plugin.ts`; add to `packages/core/src/plugins.ts` registry to make them available

## References
- **Core types:** `packages/core/src/model/RivetPlugin.ts`, `packages/core/src/model/NodeImpl.ts`
- **Example plugins:** `packages/core/src/plugins/anthropic/plugin.ts` (simple), `packages/core/src/plugins/openai/plugin.ts` (multi-node + context group)

---
**Last Updated:** 2026-04-19
