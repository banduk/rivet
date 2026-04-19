---
name: file-and-audio-io
description: File reading and audio playback nodes — nativeApi/audioProvider context requirements, DataRef embedding, and provider implementations
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/model/nodes/ReadFileNode.ts`
- `packages/core/src/model/nodes/ReadDirectoryNode.ts`
- `packages/core/src/model/nodes/AudioNode.ts`
- `packages/core/src/model/nodes/PlayAudioNode.ts`
- `packages/app/src/io/TauriBrowserAudioProvider.ts`

Keywords: nativeApi, audioProvider, readTextFile, readBinaryFile, readdir, DataRef, base64ToUint8Array, AudioProvider, playAudio

---

## Key Files
- `ReadFileNode.ts` — reads text (`string`) or binary (`Uint8Array`) via `context.nativeApi`
- `ReadDirectoryNode.ts` — lists paths + tree via `nativeApi.readdir(path, undefined, options)`
- `AudioNode.ts` — wraps audio bytes into `{ type: 'audio', value: { data, mediaType } }`; stores embedded audio as base64 `DataRef` in `project.data`
- `PlayAudioNode.ts` — delegates to `context.audioProvider.playAudio(audioValue, context.signal)`
- `TauriBrowserAudioProvider.ts` — implements `AudioProvider` using `new Blob` + `URL.createObjectURL` + Web Audio `Audio` element

## Key Concepts

- **`context.nativeApi`**: Required by file nodes. If `null`, throw `'This node requires a native API to run.'` — only available in Tauri/node-executor, never in pure browser.
- **`context.audioProvider`**: Required by `PlayAudioNode`. If `null`, throw `'Playing audio is not supported in this context'`.
- **Audio DataValue shape**: `{ type: 'audio', value: { data: Uint8Array, mediaType: string } }` — always include `mediaType` (defaults to `'audio/wav'`).
- **Embedded audio via `DataRef`**: `AudioNode` stores static audio as `this.data.data.refId` → looked up in `context.project.data[refId]` as a base64 string → decoded with `base64ToUint8Array`.
- **Binary file read**: `nativeApi.readBinaryFile(path)` returns a Blob-like — call `.arrayBuffer()` then wrap in `new Uint8Array(buffer)`.
- **`useXxxInput` toggle pattern**: Each data field has a paired `useXxxInput` boolean that controls whether the dynamic port appears in `getInputDefinitions()`.
- **`getInputOrData`**: `getInputOrData(this.data, inputs, 'key', 'type')` — resolves live port input or falls back to static node data.

## Critical Rules

- `ReadFileNode` missing file: returns `{ type: 'control-flow-excluded' }` by default; only throws if `errorOnMissingFile: true`.
- `ReadDirectoryNode` on error: silently returns `['(no such path)']` and an empty-children tree — no config flag to change this.
- `expectType(inputData[portId], 'audio')` — strict assertion; throws on type mismatch. Don't coerce audio inputs.
- `AudioNode`'s `fileBrowser` editor requires both `dataKey` and `mediaTypeDataKey` — omitting `mediaTypeDataKey` silently drops MIME type.

## References
- **Patterns:** `.claude/guidelines/file-and-audio-io/patterns.md`

---
**Last Updated:** 2026-04-19
