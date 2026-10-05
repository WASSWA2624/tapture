# 131 — Accept on-device speech on physical devices

**Depends on** [123](../24-product-refinements.md), [124](../24-product-refinements.md), [125](../24-product-refinements.md), [126](../24-product-refinements.md), [128](../24-product-refinements.md), [129](../24-product-refinements.md)

**Implementation started:** Yes

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

- [x] On this machine, `devices.yaml` declares the STT metrics for every class, and `device_matrix_test` accepts them.
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

### Verification

- 2026-10-04: `frontend/tool/devices.yaml` declares `sttModelLoadMs`, `sttFirstPartialMs`, `sttFinalizeMs`,
  `sttDecode10sMs`, `sttRtf` and `sttAbortMs` for low, mid, tablet and a new desktop class (`deviceId: windows`);
  the desktop limits match `AppConstants.speechBudgets`. The low, mid and tablet stt limits are provisional until
  physical-device evidence replaces them. `flutter test test/tool/device_matrix_test.dart`: 22/22 passed, including
  a test that parses the checked-in `devices.yaml` and accepts every stt metric for all four classes. `dart analyze`
  on the five changed Dart files: no issues; `dart format --set-exit-if-changed`: 0 changed.
- 2026-10-04: deviation — `frontend/tool/device_matrix.dart` (not in Files) was extended so the speech suite can run:
  ratio (`Rtf`) metrics, per-suite metric ownership (`suiteMetrics`), physical phone or desktop for the speech suite,
  `TAPTURE_SPEECH_METRICS` opt-in and a `--define` pass-through. A shared timing wrapper was added at
  `frontend/integration_test/support/timed_speech_engine.dart`.
- 2026-10-04: desktop run (`dart run tool/device_matrix.dart --devices desktop --suite
  integration_test/speech_metrics_test.dart`, evidence `frontend/build/speech-metrics-desktop.json`, written after
  the last source edit; tiny-q5_1, 4 threads, `flutter test` debug build with the native engine at release speed):
  load 600/2000 ms, first partial 150/1500 ms, 10 s decode 1859/3500 ms, RTF 0.1859/0.35, abort 28/500 ms, and
  `sttFinalize` 1974/1000 ms (p90 of 5 committed decodes) — fails by +974 ms, matching task 128's open finalize
  finding. The desktop item stays open until the committed-profile cost is optimised; the limit was not raised.
- 2026-10-04: WER — `frontend/integration_test/speech_wer_test.dart` and the fixture manifest exist, but no
  utterances are recorded (consent pending), so the test skips on Windows; the item stays open until 10 consented
  team recordings are added. The manual microphone session needs a person speaking and stays open.
- 2026-10-04: `flutter test --help` in Flutter 3.44.6 has no `--profile` option, so `device_matrix.dart`'s existing
  profile-mode run (and profile-mode phone speech metrics) cannot start until a `flutter drive` runner replaces it.
  The physical-device, browser, battery/thermal and Android extraction items are device-only (task 130/131 runs on
  hardware not available here).
