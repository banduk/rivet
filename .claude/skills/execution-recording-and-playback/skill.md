---
name: execution-recording-and-playback
description: Recording graph executions to disk and replaying them in the UI
---

## Activation

This skill triggers when editing these files:
- `packages/core/src/recording/ExecutionRecorder.ts`
- `packages/core/src/recording/RecordedEvents.ts`
- `packages/app/src/hooks/useLoadRecording.ts`
- `packages/app/src/hooks/useSaveRecording.ts`
- `packages/app/src/state/execution.ts`

Keywords: ExecutionRecorder, replayRecording, loadedRecordingState, lastRecordingState, recordExecutionsState, SerializedRecording

---

You are working on **execution recording and playback** in Rivet.

## Key Files
- `packages/core/src/recording/ExecutionRecorder.ts` — `ExecutionRecorder` class; attach via `.record(processor)` or `.recordSocket(ws)`, serialize with `.serialize()` / `.serializeStream()`
- `packages/core/src/recording/RecordedEvents.ts` — `Recording`, `RecordedEvents`, `RecordedEventsMap`, `SerializedRecording` types
- `packages/app/src/state/execution.ts` — `loadedRecordingState` (`{ path, recorder } | null`), `lastRecordingState` (serialized string)
- `packages/app/src/state/settings.ts` — `recordExecutionsState` (boolean atom), `settingsState.recordingPlaybackLatency` (ms)
- `packages/app/src/hooks/useLocalExecutor.ts` — wires recording: calls `recorder.record(processor)` when `recordExecutions`, calls `processor.replayRecording(recorder)` when `loadedRecording`
- `packages/app/src/hooks/useLoadRecording.ts` / `useSaveRecording.ts` — load via `ioProvider.loadRecordingData`, save via `ioProvider.saveString(..., '*.rivet-recording')`

## Key Concepts
- **`RecordedEventsMap`** strips non-serializable fields from `ProcessEvents` (e.g. `callback` on `userInput` is kept as-is; `error` objects become strings)
- **Serialization format** (`SerializedRecording` v1): `Uint8Array` values become `$ASSET:<id>` references, long strings become `$STRING:<fnv1a-hash>` to deduplicate
- **Playback**: `processor.replayRecording(recorder)` iterates events and re-emits them; `recordingPlaybackChatLatency` controls simulated streaming delay
- `partialOutput` and `trace` events are excluded from recording by default (`includePartialOutputs`, `includeTrace` options)

## Critical Rules
- Recording attaches to `processor` before `processGraph` is called — order matters in `useLocalExecutor.ts`
- When replaying, the project passed to `GraphProcessor` must contain all graph/node IDs in the recording or it throws
- `lastRecordingState` stores the serialized string in memory only (not persisted); `useSaveRecording` writes it to disk
- File extension for recordings is `.rivet-recording`

## References
- **Patterns:** `.claude/skills/packages/skill.md`

---
**Last Updated:** 2026-04-19
