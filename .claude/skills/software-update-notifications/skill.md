---
name: software-update-notifications
description: Tauri-based software update check, status monitoring, and install flow for the Rivet desktop app
---

## Activation

This skill triggers when editing these files:
- `packages/app/src/hooks/useCheckForUpdate.tsx`
- `packages/app/src/hooks/useMonitorUpdateStatus.ts`
- `packages/app/src/components/UpdateModal.tsx`

Keywords: checkUpdate, installUpdate, onUpdaterEvent, updateModalOpenState, skippedMaxVersion

---

You are working on **software update notifications** in the Rivet desktop app.

## Key Files
- `packages/app/src/hooks/useCheckForUpdate.tsx` — calls Tauri `checkUpdate()`, shows a `react-toastify` toast with Install/Skip/Not Now actions
- `packages/app/src/hooks/useMonitorUpdateStatus.ts` — subscribes to `onUpdaterEvent` and writes progress strings to `updateStatusState`
- `packages/app/src/components/UpdateModal.tsx` — Atlaskit modal that calls `installUpdate()` then `relaunch()` after install completes
- `packages/app/src/state/settings.ts:61-67` — four atoms: `checkForUpdatesState` (persisted), `skippedMaxVersionState` (persisted), `updateModalOpenState`, `updateStatusState`

## Key Concepts
- **Tauri-only:** All update APIs (`checkUpdate`, `installUpdate`, `onUpdaterEvent`, `relaunch`) are from `@tauri-apps/api/*`. Always guard with `isInTauri()` before calling.
- **Skip logic:** Uses `semver.lte(manifest.version, skippedMaxVersion)` — skip is bypassed when `force: true` (also clears `skippedMaxVersion`).
- **Status flow:** `onUpdaterEvent` emits `PENDING → DOWNLOADED → DONE`; the hook maps these to human strings. Note: `DOWNLOADED` is missing from the Tauri type union and must be cast.
- **Toast vs Modal:** Toast is shown on update discovery; `updateModalOpenState` opens the full `UpdateModal` which re-calls `checkUpdate()` for the manifest.

## Critical Rules
- Never call `checkUpdate`/`installUpdate` outside of Tauri — wrap with `isInTauri()` or it will throw.
- `onUpdaterEvent` returns an unlisten function — always call it in the cleanup return of `useAsyncEffect`.
- `manifest.body` is rendered via `dangerouslySetInnerHTML` after `useMarkdown()` — keep this rendering path for update notes.

## References
- **Patterns:** `.claude/skills/base/skill.md`

---
**Last Updated:** 2026-04-19
