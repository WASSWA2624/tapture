# 131 — Accept on-device speech on physical devices

**Depends on** [123](../24-product-refinements.md), [124](../24-product-refinements.md), [125](../24-product-refinements.md), [126](../24-product-refinements.md), [128](../24-product-refinements.md), [129](../24-product-refinements.md)

## Implement

**Device metrics.** `frontend/tool/devices.yaml` gains these metrics for the low, mid and tablet classes and a new desktop class: `sttModelLoadMs`, `sttFirstPartialMs`, `sttFinalizeMs`, `sttDecode10sMs`, `sttRtf` and `sttAbortMs`. `frontend/integration_test/speech_metrics_test.dart` (opt-in through `TAPTURE_SPEECH_METRICS`) emits them through `dart run tool/device_matrix.dart --suite integration_test/speech_metrics_test.dart`.

**WER fixture set.** Record and store a local set of 10 team-recorded utterances under `frontend/integration_test/fixtures/speech_wer/`, each with a reference `.txt` and a `manifest.json` (consent noted, no personal data). Add `frontend/integration_test/speech_wer_test.dart`.

**Platforms:**
- Android arm64 low and mid, plus the x86_64 emulator;
- an iOS device;
- macOS arm64 and x86_64;
- Linux x64;
- Chrome, Edge and Firefox in st and mt;
- Safari in st.

**Scenarios:**
- a 30-minute session with pauses;
- background, a call and Bluetooth headset loss;
- **mobile permission revocation in Settings (which kills the process), verified through `TranscriptRecovery` and `StagedTakeRecovery`**;
- a kill and recovery;
- low-RAM, armeabi-v7a and pre-AVX2 refusal;
- Android dictation fallback where the on-device recogniser is absent (API 30), confirming no recogniser starts;
- battery drain and thermal over 30 minutes;
- record_web 16 kHz versus 48 kHz + the resampler;
- WER, plus whether mobile `auto` may select base and whether to keep `mobileDictationCommittedPad`.

Create follow-up tasks with `new_task.dart` for any optimisation the numbers justify: the arm64 dotprod variant, Android fd-based loading, ggml-blas on Apple.

**Desktop manual run.** A person speaks into the Windows app's microphone across dictation, Transcribe, a meeting and the caption recorder.

## Files

- `frontend/tool/devices.yaml`, `frontend/integration_test/speech_metrics_test.dart`, `frontend/integration_test/speech_wer_test.dart`, `frontend/integration_test/fixtures/speech_wer/**`, `frontend/test/tool/device_matrix_test.dart`
- `dev-plan/27-hardening/27-hardening.md` (one sentence in 023's Implement: its final release pass runs after this task; no tick change)

## Definition of done

- [ ] On this machine, `devices.yaml` declares the STT metrics for every class, and `device_matrix_test` accepts them.
- [ ] On this machine, the desktop class on Windows emits every STT metric within tolerance.
- [ ] On this machine, a manual Windows microphone session across dictation, Transcribe, a meeting and the caption recorder works with the network disabled, including minimise → pause and a focus-loss `inactive` that does not pause.
- [ ] On this machine, the WER fixture set exists, and WER is ≤ 25% for tiny and ≤ 15% for base.
- [ ] Android low, Android mid and iOS emit every STT metric within tolerance in profile mode.
- [ ] On Android, iOS, macOS and Linux, a 30-minute session with pauses has no lost audio and no duplicated, missing or reordered text.
- [ ] Background, call, headset loss, mobile permission revocation (through recovery) and kill recovery keep the audio up to the last checkpoint and every durable segment.
- [ ] Low-RAM and armeabi-v7a devices select tiny or report unsupported plainly. An API-30 Android device without a model never starts a platform recogniser. A pre-AVX2 x86 machine reports `unsupportedCpu` without loading the library.
- [ ] Battery drain and thermal behaviour over 30 minutes are recorded for low and mid Android, and the mobile `auto` and `mobileDictationCommittedPad` decisions are recorded.
- [ ] Safari falls back to st, Chrome and Firefox with isolation headers use mt, and a 30-minute web session completes.
- [ ] Web worklet accuracy versus the Dart resampler is measured, and a decision is recorded.
- [ ] Android runtime model extraction (sha-keyed, re-extract once) works on a device.
