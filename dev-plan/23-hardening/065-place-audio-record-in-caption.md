# 065 — Place the audio record control in the caption field

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Move the capture record control into the Caption field, after the speech-to-text microphone. The Audio heading and the Record audio button go away. Recording still writes the same local file and still asks which photos the clip belongs to after stop.

The executable prompt is `prompts/feedback-24092026-1453/001-place-audio-record-in-caption.md`.

## Files

- `frontend/lib/features/capture/presentation/record_caption_field.dart`
- `frontend/lib/features/capture/presentation/capture_screen.dart`
- `frontend/lib/features/capture/presentation/audio_recorder.dart`
- `frontend/test/features/capture/presentation/capture_feedback_test.dart`

## Definition of done

- [x] The Caption field shows the speech-to-text microphone, then a waveform button labelled `Copy.captureRecordAudio`.
- [x] The capture page has no Audio heading and no Record audio button.
- [x] Tapping the waveform button starts the existing recorder. Pause and stop remain available until the recording ends.
- [x] Typing in Caption still stores only the record caption.
- [x] Tests: `capture_feedback_test.dart` covers the layout matrix and the recording start.
