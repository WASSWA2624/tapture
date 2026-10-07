# 138 — Verify 16 KiB runtime protection for packaged Android libraries

**Depends on** [103](../24-product-refinements.md), [136](../25-testing-and-release.md)

## Implement

Verify the complete packaged 64-bit native-library set on an Android environment whose page size is 16 KiB.
Exercise runtime loading and memory protection, investigate the recorded GNU RELRO endpoint alignment
advisories, and repair confirmed failures through the relevant dependency or native build configuration.
Preserve bundled models, supported features and existing durable data.

## Files

- `frontend/android/app/build.gradle.kts`
- `frontend/packages/tapture_whisper/android/`
- `frontend/pubspec.yaml`, `frontend/pubspec.lock` (only dependencies requiring a verified repair)
- `frontend/docs/release-build.md`
- `frontend/integration_test/` (native runtime acceptance scenarios)

## Constraints

- Test the APK on a verified 16 KiB environment, recording `adb shell getconf PAGE_SIZE`; an ELF load-segment
  check or APK ZIP-alignment check alone does not prove runtime memory protection.
- Do not treat a static RELRO advisory as a demonstrated crash. Retain the library inventory and before/after
  evidence, and change dependency versions only when the verified failure requires it.
- Keep task 131's physical-device speech acceptance and task 023's integrated release acceptance separate.

## Definition of done

- [ ] Installation and cold start pass on a verified 16 KiB Android environment; the packaged native-library inventory and runtime diagnostics are recorded.
- [ ] Tests: native speech, SQLite persistence, OCR, barcode, face detection and PDF rendering exercise their packaged engines successfully, with no library-loading or memory-protection failure.
- [ ] Every recorded RELRO advisory has a documented runtime outcome; confirmed failures are repaired and rechecked on the same environment.
- [ ] Release documentation describes the tested Android environment, remaining ABI limits and any dependency or packaging changes.

## Discovery evidence — 2026-10-07

Task 136's APK audit found 16 KiB-aligned load segments in all 22 ARM64/x86_64 libraries. Applying Android's
additional GNU RELRO endpoint alignment guidance produced advisories for 13 existing 64-bit libraries.
All 30 non-Dart native binaries across the three ABIs are byte-identical to the previous universal APK;
the packaging optimization did not introduce these binaries. No runtime crash has been demonstrated.
The inventory and measurements are in the local ignored `frontend/build/apk-validation/` reports.
This task remains pending until its dependency and native runtime acceptance are verified.
