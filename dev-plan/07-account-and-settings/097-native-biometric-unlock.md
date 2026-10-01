# 097 — Use maintained native biometric authentication for the app lock

**Implementation step:** 07.02

**Phase** 07 · Account and settings  |  **Depends on** [001](../01-orchestration/001-project-setup.md), [002](../02-foundation/002-foundation-services.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

**Implementation started:** Yes

Replace the unavailable production biometric placeholder with the Flutter-maintained
[`local_auth` 3.0.2](https://pub.dev/packages/local_auth/versions/3.0.2) SDK, BSD-3-Clause, pinned and
allowlisted. Reuse the app-lock and PIN fallback contracts of [007](007-account-and-settings.md).
The public platform message APIs are pinned directly as
[`local_auth_android` 2.2.0](https://pub.dev/packages/local_auth_android/versions/2.2.0) and
[`local_auth_darwin` 2.0.4](https://pub.dev/packages/local_auth_darwin/versions/2.0.4), both BSD-3-Clause,
to supply localized Android title/hint/cancel and Darwin buttons without inheriting English SDK defaults.
The SDK is reached only through `core/security/biometric_service.dart`. A hardware probe never
authenticates or requests access during startup; the explicit biometric action supplies localized
copy and requires biometrics, preserving the app's own PIN fallback. Cancellation, missing enrollment,
unsupported platforms, device errors and bounded timeout never unlock the app. Backgrounding cancels
authentication and a late SDK result cannot unlock a timed-out attempt.

Use Android `FlutterFragmentActivity`, `USE_BIOMETRIC` and AppCompat themes as required by the
[Android SDK setup](https://github.com/flutter/packages/blob/main/packages/local_auth/local_auth_android/README.md).
Register the Face ID usage rationale on iOS as required by the
[Darwin SDK setup](https://github.com/flutter/packages/blob/main/packages/local_auth/local_auth_darwin/README.md).
The optional PIN gate remains armed when its secure hash or persisted backoff is unreadable,
malformed or stalled; removal refuses a failed credential deletion. Secure-store recovery can retry
the same stored PIN without rewriting evidence.
PIN replacements atomically store the versioned salt and hash together under one secure-store key;
a refused write preserves the previous credential; an interrupted write retains a complete old or new
credential without mixing salt and hash. Legacy separate salt/hash pairs remain
readable and are replaced only when the operator explicitly sets a new PIN.

## Files

- `frontend/lib/core/security/biometric_service.dart`
- `frontend/lib/core/security/biometric_prompt.dart`
- `frontend/lib/features/settings/data/biometric_lock.dart`
- `frontend/lib/features/settings/data/pin_lock.dart`
- `frontend/lib/features/settings/domain/app_lock.dart`
- `frontend/lib/features/settings/presentation/app_lock_screen.dart`
- `frontend/lib/core/constants/app_constants.dart`
- `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`
- `frontend/android/app/src/main/AndroidManifest.xml`
- `frontend/android/app/src/main/res/values*/styles.xml`
- `frontend/ios/Runner/Info.plist`
- `frontend/pubspec.yaml`, `frontend/pubspec.lock`, `frontend/tool/allowlist.yaml`
- `frontend/test/core/security/biometric_service_test.dart`
- `frontend/test/features/settings/data/pin_lock_test.dart`

## Definition of done

- [x] The pinned maintained SDK is allowlisted with its license, purpose and replacement recorded.
- [ ] Production unlock uses the SDK through the core boundary, requests biometrics only on the
      explicit action, supplies localized copy and preserves PIN fallback on every failure.
- [ ] Secure-store read failure, malformed backoff, timeout and failed PIN deletion keep the gate armed.
- [ ] Tests cover native SDK options, hardware/no-enrollment refusal, cancellation/device errors,
      timeout/late completion, PIN recovery and failed credential deletion.
- [ ] Android and iOS builds compile with the required native activity, themes and usage rationale.
- [ ] Real enrolled Android and iOS devices unlock, cancel, background and resume with PIN fallback;
      a fresh install requests no biometric access until the explicit action.

2026-10-01 native verification: the Android production debug Kotlin, resources and merged manifest targets
compiled successfully (315 tasks, 65 executed), including the maintained biometric/Google SDKs, AppCompat
activity/themes and bounded incoming-file bridge. This targeted native compile does not establish a complete
Flutter build, an iOS build or physical enrollment/consent behavior. The SDK option/PIN failure regressions and
final source-stable verification remain pending.
