# 001 — Place the audio record control in the caption field

**Feedback:** FBK0000090 · **Work items:** 1 · **Depends on:** none

## Goal
On project capture and the capture tab, the operator starts an audio recording from inside the Caption field, immediately after the speech-to-text microphone. The separate Audio section and its Record audio button are gone. Speech-to-text stays on the microphone. Recording still writes the same local file and still asks which photos the clip belongs to after stop.

## Run order
| Item | Title | Feedback | Type | Priority | Effort | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| W1 | Place the audio record control in the caption field | FBK0000090 | Improvement | P3 | S | — |

## Rules
- FE-CONS-01, FE-STR-09: extend `AppTextField` and `AppIconButton`; do not add a capture-only field.
- FE-L10N-01, FE-A11Y-01, FE-A11Y-02, FE-RESP-10, FE-TEST-01, FE-FLOW-08.

## Before the work items
1. Record this prompt as one task with `cd frontend && dart run tool/new_task.dart 23-hardening place-audio-record-in-caption "Place the audio record control in the caption field"` (FE-FLOW-08).

## W1 — Place the audio record control in the caption field
**Feedback:** FBK0000090 · **Type:** Improvement · **Priority:** P3 · **Effort:** S · **After:** —

### Evidence
- FBK0000090: audio is a caption, so its control belongs inside the caption field, after the speech-to-text microphone. The microphone stays speech-to-text. The record control uses the waveform mark used by chat apps, not a second microphone. `screenshots/FBK0000090.png` shows project capture, compact, portrait, system dark, text scale 1: an Audio section, a Record audio button, and a Caption field whose only suffix is a microphone.
- `frontend/lib/features/capture/presentation/capture_screen.dart` builds `AppSectionHeader(title: Copy.captureAudioSection)` and `AudioRecorder` above `RecordCaptionField`. Both `/capture` and `/projects/:projectId/capture` in `frontend/lib/app/router.dart` build that same `CaptureScreen`.
- `frontend/lib/features/capture/presentation/audio_recorder.dart` paints `AppButton(label: Copy.captureRecordAudio)` while idle, failed, or completed.
- `frontend/lib/features/capture/presentation/record_caption_field.dart` builds `AppTextField` with no `afterDictation`. `AppTextField._suffix` already places `afterDictation` after the dictation microphone (`Icons.mic_none` / `Icons.mic`, key `app-text-field-dictate`).

### Scope
- Reach: Android, iOS, Windows, macOS, Linux, and web; compact, medium, and expanded; portrait and landscape; light, dark, and outdoor; 200 percent text; left-to-right and right-to-left. The sample was Android, compact, portrait, dark, text scale 1. No surface is excluded: every one renders this `CaptureScreen`.
- Change: `RecordCaptionField`, `CaptureScreen`, `AudioRecorder`. The record control is `AppIconButton` with `Icons.graphic_eq`, passed through `AppTextField.afterDictation`.
- Do not change: the caption text store (`CaptureController.setCaption(null, text)` remains the record caption), the photo-caption sheet, caption scopes, the audio file path, the bytes written, and the post-stop sheet `Copy.captureAudioScopeTitle`.

### Rules
- FE-CONS-08: one record icon, `Icons.graphic_eq`, and the existing microphone for dictation.
- FE-A11Y-01, FE-A11Y-02: `Sizes.minTapTarget` and a semantic label plus tooltip.
- FE-SEC-08, FE-STATE-07: the recording is still a new local file; nothing overwrites a photo and nothing overwrites a caption.
- FE-L10N-01: visible strings stay in `Copy`.

### Steps
1. Add `Widget? afterDictation` to `RecordCaptionField` and pass it to `AppTextField.afterDictation`.
2. In `CaptureScreen`, remove the `AppSectionHeader` whose title is `Copy.captureAudioSection`. Keep `AudioRecorder` directly under `RecordCaptionField`, with the same `relativePath`, `onCompleted`, and recorder instance.
3. In `AudioRecorder.build`, remove the `AppButton` whose label is `Copy.captureRecordAudio`. Keep the status text, the level indicator, pause, and stop.
4. Pass an `AppIconButton` as `RecordCaptionField.afterDictation` while the recorder phase is idle, failed, and completed alike: show it in each of those three phases. Icon `Icons.graphic_eq`. Semantic label and tooltip `Copy.captureRecordAudio`. `onPressed` calls `AudioRecorderService.start` with the same relative path `AudioRecorder` already uses. In the recording phase and in the paused phase, omit that icon so pause and stop in `AudioRecorder` are the only recording controls.
5. Extend `frontend/test/features/capture/presentation/capture_feedback_test.dart`. Wrap the capture page in `DictationScope` with a supported fake speech service. At widths 360, 800, and 1200, in light, dark, and outdoor, at text scale 1 and 2, in both orientations, and in right-to-left: the dictation control `app-text-field-dictate` is present; an `AppIconButton` with `Icons.graphic_eq` and tooltip `Copy.captureRecordAudio` follows it in reading order; that button's size is at least `Sizes.minTapTarget`; `find.text(Copy.captureAudioSection)` and `find.widgetWithText(AppButton, Copy.captureRecordAudio)` find nothing. A second test taps the waveform control, then finds pause and stop and does not find the waveform control.
6. `cd frontend && dart run tool/verify.dart --fast` is green.

### Acceptance criteria
- [ ] The Caption field shows the speech-to-text microphone, then a waveform button labelled `Copy.captureRecordAudio`.
- [ ] The capture page has no Audio heading and no Record audio button.
- [ ] Tapping the waveform button starts the existing recorder. Pause and stop remain available until the recording ends, and stop still opens the existing audio-scope sheet.
- [ ] The status line from `Copy.audioRecorderStatus` still shows under the field.
- [ ] Typing in Caption still stores only the record caption.
- [ ] The controls stay at least `Sizes.minTapTarget` on compact, medium, and expanded widths, both orientations, light, dark, and outdoor, at 200 percent text, in both text directions.
- [ ] FBK0000090 is resolved on the capture tab and on project capture.

## Verification
- Run `frontend/test/features/capture/presentation/capture_feedback_test.dart` and the capture presentation suite.
- After the last item, the full `cd frontend && dart run tool/verify.dart` is green.
- This item changes no golden. Do not pass `--update-goldens`.
