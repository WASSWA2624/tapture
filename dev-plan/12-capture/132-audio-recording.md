# 132 — Long-form audio recording

**Phase** 12 · Capture  |  **Depends on** [055](../04-data-layer/055-photos-table.md), [067](../05-file-storage/067-file-writer.md), [131](131-voice-permission.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Record a walkthrough or a meeting to a file attached to the record as a document, for transcription later, with
nothing lost if the app dies mid-recording.

## Files

- `frontend/lib/features/capture/presentation/audio_recorder.dart` (new)

## Steps

1. Show elapsed duration and input level while recording, with pause and stop.
2. Write incrementally through the file writer (119) so an app kill keeps everything recorded up to that moment.
3. Register the finished file in the documents table with its duration (100).

## Constraints

- Encoding and writing stream in chunks off the UI thread (FE-PERF-02, FE-PERF-07).
- Recording works with the network off and is never transcribed here (FE-SEC-04).
- A full disk stops recording with the audio so far kept and playable (FE-SIMP-09).

## Definition of done

- [ ] A thirty-minute recording survives an app kill, with everything captured up to the kill playable.
- [ ] Tests: widget test of `audio_recorder.dart` covering idle, recording, paused, permission denied and disk full; test asserting a killed recording leaves a playable file and a documents row.
