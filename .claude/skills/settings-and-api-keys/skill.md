---
name: settings-and-api-keys
description: Settings state, API key storage, plugin config, and env-var fallback patterns
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/state/settings.ts`
- `packages/app/src/state/storage.ts`
- `packages/app/src/components/SettingsModal.tsx`
- `packages/app/src/utils/tauri.ts`
- `packages/core/src/model/Settings.ts`
- `packages/core/src/utils/getPluginConfig.ts`
- `packages/node/src/api.ts`

Keywords: settingsState, pluginSettings, pluginEnv, fillMissingSettingsFromEnvironmentVariables, getPluginConfig, openAiKey, apiKey, pullEnvironmentVariable

---

You are working on **settings persistence, API key management, and plugin configuration** in Rivet.

## Key Files
- `packages/core/src/model/Settings.ts` — canonical `Settings` type (openAiKey, pluginSettings, pluginEnv, etc.)
- `packages/app/src/state/settings.ts` — Jotai atoms: `settingsState`, `themeState`, `defaultExecutorState`
- `packages/app/src/state/storage.ts` — custom `atomWithStorage` using IndexedDB primary + localStorage fallback; debounced 1000ms; storage key is `'recoil-persist'` (legacy, do not change)
- `packages/app/src/utils/tauri.ts` — `fillMissingSettingsFromEnvironmentVariables(settings, plugins)`: reads env vars via Tauri `invoke('get_environment_variable')` async; cached in `cachedEnvVars`
- `packages/core/src/utils/getPluginConfig.ts` — resolves plugin config: `pluginSettings[pluginId][key]` first, then `pluginEnv[envVarName]`
- `packages/app/src/components/SettingsModal.tsx` — tabbed UI: General / OpenAI / Plugins / Updates

## Key Concepts
- **`pluginSettings` vs `pluginEnv`:** `pluginSettings` = user-typed values in Settings UI; `pluginEnv` = auto-filled from env vars at execution start. Both resolved by `getPluginConfig()` with settings taking precedence.
- **`fillMissingSettingsFromEnvironmentVariables`** is called before every graph run in `useLocalExecutor`, `useGetAdHocInternalProcessContext`, and `useGetRivetUIContext`. Never pass raw `settingsState` to a processor — always fill first.
- **`pullEnvironmentVariable`** in a plugin's `configSpec` entry: string → named env var; `true` → env var name equals config key. Required for env-var fallback to work.
- **Node.js/CLI path:** No Tauri — `packages/node/src/api.ts` reads `process.env` directly; `getPluginEnvFromProcessEnv()` iterates all plugin configSpecs to auto-populate `pluginEnv`.
- **Nodes read settings via context:** `context.settings.chatNodeTimeout` for core settings; `context.getPluginConfig('keyName')` for plugin-owned keys (never access `pluginSettings` raw).

## Critical Rules
- Plugin config secrets use `type: 'secret'` in `configSpec` — renders as password field in UI and is excluded from exports.
- Settings writes are debounced 1000ms — don't rely on synchronous persistence after a write.
- Tauri env var fetches are async and cached; `fillMissingSettingsFromEnvironmentVariables` must be awaited.
- CLI `serve` command accepts `--openai-api-key` etc. as overrides; these become `createProcessor()` options, not settings state.

## References
- **Patterns:** `.claude/guidelines/settings-and-api-keys/patterns.md`

---
**Last Updated:** 2026-04-19
