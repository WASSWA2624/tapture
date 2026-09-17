# 189 — Record and transcribe the meeting

**Phase** 17 · Meetings  |  **Depends on** [131](../12-capture/131-voice-permission.md), [132](../12-capture/132-audio-recording.md), [186](186-meeting-template.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

A long-form recording attached to the meeting record, and the transcript produced from it — stored verbatim,
versioned, and re-runnable against a better service later.

## Files

- `frontend/lib/features/meetings/presentation/meeting_audio_section.dart` (new)
- `frontend/lib/features/meetings/domain/meeting_transcription.dart` (new)

## Steps

1. The section shows elapsed time and remaining storage while recording, and keeps the partial file when the app is
   interrupted or killed.
2. Transcription chunks long audio, reports progress per chunk, and survives one chunk failing without losing the
   chunks already done.
3. Each transcription run is stored as its own version against the recording; a re-run adds a version and replaces
   none.

## Definition of done

- [ ] An interrupted recording is still attached to the meeting and playable.
- [ ] The raw transcript is never replaced, neither by refinement (354) nor by a later run.
- [ ] Tests: widget test of `meeting_audio_section.dart` covering recording, interruption and its empty and failure
      states; unit tests of `meeting_transcription.dart` over chunking, a failed chunk and a repeat run, with no
      Flutter binding.
