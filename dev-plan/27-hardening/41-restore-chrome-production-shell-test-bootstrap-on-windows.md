# 162 — Restore Chrome production-shell test bootstrap on Windows

**Depends on** [006](../06-app-shell.md)

## Implement

Diagnose and restore the Chrome production-shell test bootstrap on Windows. Flutter 3.44.6's local CanvasKit handler converts the URL to a Windows path before testing a forward-slash prefix and returns 404 for installed renderer files. Supplying the unchanged SDK renderer exposes a separate JavaScript module-initialization failure in `speech_readiness_notifier.dart`: the imported `speech_engine_host` module is undefined. Establish the baseline and actual dependency cause before changing production code. Preserve the existing real-shell assertions, speech behavior and renderer; do not replace the app or treat an unstarted suite as a pass.

## Files

- `frontend/test/features/capture/presentation/capture_workflow_layout_browser_test.dart`
- `frontend/test/features/capture/presentation/capture_workflow_fixture.dart`
- `frontend/lib/core/speech/speech_readiness_notifier.dart`, `speech_engine_host.dart` and confirmed dependency edges
- Installed Flutter SDK test-server configuration or an explicitly documented verification workaround; no SDK change is included in task 158

## Definition of done

- [ ] A cold baseline/current reproduction diagnoses renderer serving and the speech module-initialization failure with exact runtime evidence.
- [ ] A supported renderer-serving path and corrected confirmed dependency cause allow the unchanged application modules to initialize in Chrome.
- [ ] The full Chrome production-shell matrix passes with actual focus, accessibility, draft and save assertions intact; relevant native/speech regressions, analysis, tracker synchronization and plan checks pass.

## Evidence

2026-10-09: task 158's required Chrome command compiles but cannot start its tests. Playwright/CDP inspection confirms 404 responses for the SDK's existing CanvasKit JavaScript/Wasm. Routing only those requests to the unchanged local SDK files and reloading the test frame exposes `Cannot read properties of undefined (reading 'tapture__core__speech__speech_engine_host')` at the compiled readiness notifier's module initializer. The blocked run is stopped, not reported green. Baseline isolation is recorded separately; no speech or SDK correction belongs to the Capture setup implementation.

Baseline isolation: the minimal application-import probe passes on `d921abb0` after serving the verified SDK renderer files. The unchanged baseline production-shell fixture independently reproduces the same undefined `speech_engine_host` module at the same compiled readiness-notifier initializer; both the 404 renderer response and JavaScript stack are captured in `frontend/build/task158-baseline-chrome-workflow-proof.json`. The issue depends on the production fixture, not merely importing the application. Its underlying cause and a supported fix remain open. An additional current cold-compilation attempt is stopped after this baseline confirmation; no browser matrix pass is inferred.
