# Release build

Run from `frontend/` to produce signed, shrunk production APKs per ABI with Dart debug symbols stored separately:

```bash
flutter build apk --release --flavor prod --split-per-abi --split-debug-info=build/symbols
```

APKs are written to `build/app/outputs/flutter-apk/`. Keep `build/symbols/` with the corresponding build for stack-trace symbolication. Install the APK matching the device's ABI: `arm64-v8a` for supported 64-bit ARM devices, `armeabi-v7a` for 32-bit ARM devices, or `x86_64` for matching devices and emulators. A universal APK carries all three architectures and is substantially larger. See [Flutter's Android release documentation](https://docs.flutter.dev/deployment/android#build-an-apk).

### Windows process setup

If this Windows command runner reports `Unable to establish loopback connection` with an `Invalid argument: connect`
cause, use a short normal temporary directory and a nonexistent Unix-socket directory. The installed JDK falls
back to TCP for its selector pipe. These settings affect only the current PowerShell process; `JAVA_HOME` selects
the installed Java executable already on `PATH` instead of a stale removed JDK:

```powershell
$env:JAVA_HOME = Split-Path (Split-Path (Get-Command java).Source -Parent) -Parent
$buildTmp = Join-Path $env:SystemDrive 'tapture-build-tmp'
New-Item -ItemType Directory -Path $buildTmp -Force | Out-Null
$env:TEMP = $buildTmp
$env:TMP = $buildTmp
$env:JAVA_TOOL_OPTIONS = "-Djdk.net.unixdomain.tmpdir=$buildTmp/disabled-af-unix -Djava.io.tmpdir=$buildTmp -Djava.net.preferIPv4Stack=true"
```

Leave `disabled-af-unix` absent, then run the build command above. The IPv4 preference also avoids stalled SDK
downloads on this machine. Do not change system-wide networking or environment settings for this workaround.

If Kotlin compilation stalls while connecting to its daemon, use its supported in-process strategy for this
PowerShell process, then retry the build:

```powershell
Set-Item -Path 'Env:ORG_GRADLE_PROJECT_kotlin.compiler.execution.strategy' -Value 'in-process'
```

This passes a Gradle project property without editing shared build settings. See
[Kotlin's compiler execution strategies](https://kotlinlang.org/docs/compiler-execution-strategy.html).

## Size and offline functionality

Native libraries are losslessly compressed in the APK (`packaging.jniLibs.useLegacyPackaging = true`). Android extracts them during installation, so the APK download shrinks while installed storage includes the extracted libraries. R8 code minification and resource shrinking remain enabled. See [Android's native-library packaging API](https://developer.android.com/reference/tools/gradle-api/8.6/com/android/build/api/dsl/JniLibsPackaging).

All three offline speech models stay bundled at their pinned bytes and hashes, with `.bin` assets uncompressed for streaming extraction. Together, tiny, base and Silero occupy **92,745,396 bytes (92.75 MB)**. The base model alone occupies 59,707,625 bytes. A 50 MB APK cannot contain these models, even before application code and native libraries. A measured lossless DEFLATE comparison still leaves the same three models at 87.33 MB. The product owner chose to preserve the bundled models and speech quality on 2026-10-07; this build changes packaging rather than model availability.

The 2026-10-07 production rebuild includes the Android document-picker MIME fix (task 139) and produced these APKs. Sizes use decimal MB (`1 MB = 1,000,000 bytes`):

| ABI | APK in `build/app/outputs/flutter-apk/` | Bytes | MB |
| --- | --- | ---: | ---: |
| ARM64 | `app-arm64-v8a-prod-release.apk` | 130,920,643 | 130.92 |
| ARM32 | `app-armeabi-v7a-prod-release.apk` | 127,847,101 | 127.85 |
| x86_64 | `app-x86_64-prod-release.apk` | 132,119,662 | 132.12 |

The previous universal production APK measured 291,194,390 bytes (291.19 MB). ARM64 is now 55.0% smaller. Each
new APK has a `.sha256` sidecar. The existing `app-prod-release.apk` is the older universal artifact; use the new
ABI-specific filename above.

## Validation limits

Task [136](../../dev-plan/25-testing-and-release.md#136--optimize-and-verify-android-apk-delivery) records build, signatures, ZIP alignment, native-library checks, model hashes and automated-suite evidence. Physical-device installation, cold start, durable offline capture, speech, OCR, PDF import and export acceptance remain pending until that smoke test runs. Successful builds and desktop tests do not close whole-product hardening (task 023) or physical-device speech acceptance (task 131).

Recorded checks: full frontend analysis is clean; 141 release/speech/database/OCR/PDF/bootstrap tests pass,
including real PDFium rendering; all 14 offline capture/export/failure/session scenarios pass. The shared
malformed-response recovery regression passes separately and its changed files analyze cleanly. All three APKs
verify with APK Signature Scheme v2 and ZIP alignment; all model SHA-256 hashes match their catalogue pins.
After the picker fix, another targeted run passes all 27 document-picker, file-validation and native-bootstrap
checks with test concurrency set to one; the installed native picker acceptance remains in task 139.
Native library names match the previous artifact. Every ARM64 and x86_64 library has 16 KiB-aligned load segments,
and the speech-library checker passes all three ABIs. Local reports live under `build/apk-validation/`.
The final MIME-fixed APKs pass these inventory, model-hash, signature, ZIP-alignment and speech-library checks
again; their SHA-256 sidecars identify the rebuilt artifacts. All 33 packaged native binaries, including Flutter's
application library, are byte-identical to the preserved APKs from before the picker fix. Earlier raw evidence
is retained under `build/apk-validation/before-document-picker-fix-20261007T071517/`.

Another 20 tests pass against the built Windows speech library with all three real bundled models enabled,
covering transcription, Silero voice detection, cancellation, concurrent leases and handle cleanup. The native
smoke program also transcribes the vendored audio with tiny and base and recovers after cancellation.
The packaged x86_64 speech library also passes its SHA-256 self-test, tiny/base transcription and cancellation/retry
on the Android 16/API 36 emulator with no leaked objects. Its byte-identical binary in the final APK preserves
that evidence. The emulator uses 4 KiB pages; APK microphone/UI flows, physical-device speech and 16 KiB runtime
acceptance remain separate checks.

The additional GNU RELRO endpoint check reports advisories in 13 existing 64-bit libraries. All 30 non-Dart
native binaries across the three ABIs are byte-identical to the previous universal APK. These advisories have
not demonstrated a runtime crash; task [138](../../dev-plan/27-hardening/32-verify-16-kib-runtime-protection-for-packaged-android-libraries.md)
keeps runtime memory-protection acceptance open on a verified 16 KiB Android environment.

The existing 32-bit ARM build carries the speech-engine stub and some 4 KiB native libraries; native Whisper
recognition and 16 KiB-aligned load segments require the matching 64-bit APK. Packaging retains that existing
compatibility behavior. See [Android's 16 KiB compatibility guidance](https://developer.android.com/guide/practices/page-sizes).

## Where the key lives

The keystore stays outside the repository. Copy `android/key.properties.example` to `android/key.properties` on a release machine, or set these environment variables:

- `TAPTURE_KEYSTORE` — path to the keystore file
- `TAPTURE_STORE_PASSWORD`
- `TAPTURE_KEY_ALIAS`
- `TAPTURE_KEY_PASSWORD`

`key.properties` and every `*.jks` / `*.keystore` are gitignored. The current configuration falls back to the debug key when a complete release signing configuration is absent, producing an installable local release APK. This fallback does not establish store signing readiness. A store build supplies all four values and uses that release key; compatible updates must retain the app's signing identity.

## How the key reaches the pipeline

Store the four values as GitHub Actions secrets with the same names. The release job passes them into the environment for the build command and nowhere else. They are not written into the app, the backend, or a log.

## Rotation

Create a new keystore, replace the four secrets, and ship the next release with the new key. Keep the previous keystore only as long as an update must still be signed by the old key. Do not commit either file.
