# tapture_whisper

On-device speech-to-text for Tapture: a classic Flutter FFI plugin that builds whisper.cpp v1.9.4 and ggml 0.23.0
(CPU only) behind one small C ABI. It is a local package (`frontend/.rules/01-structure.md` FE-STR-01): a pinned path
dependency of the app, approved in `frontend/tool/allowlist.yaml`, with no Dart build hook and no `example/`. Only
`frontend/lib/core/speech/` imports it (FE-STR-11). The specification is `app-write-up.md` §30.4.1.

## Layout

| Path | What it holds |
|---|---|
| `pubspec.yaml` | `version: 1.9.4+1`, `resolution: workspace`, `ffiPlugin` on Android, iOS, Linux, macOS and Windows |
| `third_party/whisper.cpp/` | The vendored KEEP list, byte for byte, plus patch 0001. Never edited by hand |
| `third_party/patches/` | The only modifications to vendored source, applied in name order |
| `VENDOR.json` | Tag, commit, tarball SHA-256, each patch's hashes, and every vendored file's size and SHA-256 |
| `src/whisper_sources.cmake` | The one canonical list of vendored translation units, read by every build and by the vendor tool |
| `src/generated/ggml-version.h` | `GGML_VERSION` and `GGML_COMMIT`, which upstream configures from CMake and git |
| `src/tapture_whisper.{h,cpp}`, `src/tw_sha256.{c,h}` | The C ABI v1 and its implementation (see below) |
| `src/CMakeLists.txt`, `src/wasm_exports.txt`, `src/smoke/tw_smoke.c` | The one native build, the WebAssembly export list and the smoke tool |
| `windows/`, `linux/`, `android/` | The Flutter plugin builds, each running `src/CMakeLists.txt` |
| `wasm/emsdk_version.txt`, `wasm/smoke.mjs` | The one Emscripten release the WebAssembly build accepts, and its Node smoke |
| `darwin/tapture_whisper/Sources/tapture_whisper/` | Generated forwarders for the Apple builds (see below) |
| `darwin/tapture_whisper.podspec`, `darwin/tapture_whisper/Package.swift` | The CocoaPods and SwiftPM manifests that compile them |
| `LICENSE` | Four blocks in Flutter's 80-dash format: this package, whisper.cpp/ggml, the Whisper weights, Silero VAD |

## Vendoring

Run from `frontend/`. The only network use is downloading the release tarball once:

```sh
curl -L -o whisper.cpp-v1.9.4.tar.gz https://github.com/ggml-org/whisper.cpp/archive/refs/tags/v1.9.4.tar.gz
dart run tool/whisper_vendor.dart --from whisper.cpp-v1.9.4.tar.gz
dart run tool/whisper_vendor.dart --check
```

`--from` refuses any tarball whose SHA-256 is not `57e280cee375ab02425b806ad5146b99f6eb9357e3c2b31357c8a6af2e2e44ae`
(commit `927cfce34f31707e17f2bff35c349632fb9e2c3a`). It extracts only the KEEP list, applies every
`third_party/patches/*.patch` with an exact, fuzz-free unified-diff apply written in Dart (no `patch` binary), writes
`VENDOR.json` and regenerates the Darwin forwarders. Nothing is written unless the hash matches and every hunk applies.

`--check` needs no network and writes nothing. It prints one `path:line: message` per violation and exits 1 on any:
a missing, extra or drifted vendored file; a patch changed, added or removed since `VENDOR.json` was written; a
patched file that is no longer what its patch produced or no longer reverses to the recorded upstream; a
`whisper_sources.cmake` entry that is not vendored; and a missing, stale or stray forwarder.

The repository keeps these bytes stable: `third_party/**` and `*.patch` are `-text` in the root `.gitattributes`.

### Patch 0001: abort per graph node

Upstream sets the abort callback only on the backend the first `ggml_graph_compute_helper` overload creates; the
`ggml_backend_sched` overload that runs the encoder and the decoder never sets it, so an abort is seen only after a
whole encoder pass or a whole decode. The patch adds `abort_callback` and `abort_callback_data` to the sched
overload, sets them on every scheduler backend through the `ggml_backend_set_abort_callback` proc address exactly as
the first overload does, and passes them from the three encoder call sites and the decoder call site. The CPU backend
then checks the abort once per graph node. The VAD call is unchanged.

### Darwin forwarders

SwiftPM forbids include paths outside the package target, so the Apple builds compile the vendored sources through
generated one-line files instead of `-I` paths: one `tw_<group>__<name>_<ext>.<ext>` translation unit per entry of
`whisper_sources.cmake` (the extension is part of the name, so `ggml.c` and `ggml.cpp` never share an object name),
one arch-selecting unit per architecture file (`__aarch64__` or `__x86_64__`), one per shim source, a `forward/`
header per vendored header, and `include/tapture_whisper.h`.

Two manifests compile them (dev-plan task 105): `darwin/tapture_whisper.podspec` for CocoaPods and
`darwin/tapture_whisper/Package.swift` for SwiftPM, a `.dynamic` product `tapture-whisper` so the `tw_*` symbols are
never dead-stripped. Both target iOS 13 and macOS 10.15, use `-O3` in every configuration with hidden symbols, and carry
the definitions and flags `src/CMakeLists.txt` uses for Apple plus Accelerate (vDSP only). There are no architecture
flags, so no AVX2 on macOS x86_64, and no Metal, CoreML, BLAS or OpenMP. Nothing here can build them:
`frontend/test/tool/whisper_vendor_test.dart` holds both manifests to `src/CMakeLists.txt`, and the Apple builds run in
CI (task 130).

## The C ABI and the native builds

`src/tapture_whisper.h` is the only public header: ABI v1, statuses 0–15, ten POD structs whose sizes are published
as `TW_SIZEOF_*`, and opaque handles. `src/tapture_whisper.cpp` implements it over whisper.cpp with an explicit
`whisper_state`, a verified single-handle open (size, streamed SHA-256 from `src/tw_sha256.c`, the ggml magic, then
the parse through the same handle; `_wfsopen(..., _SH_DENYWR)` on Windows), per-node abort through patch 0001 and a
reference-counted cell, a busy flag and deferred close per handle, a filtered 256-line log ring and the crash file.
It never logs a model path or transcript text. `src/wasm_exports.txt` lists the same `TW_API` names for the
WebAssembly build.

`src/CMakeLists.txt` builds the shim and the vendored sources from `src/whisper_sources.cmake` as one shared library.
Every configuration compiles the engine with `/O2` or `-O3` and `NDEBUG`; on MSVC `/RTC1` and `/Od` are stripped and
the release CRT is used even in a Debug app, so Debug runs at release speed. Architecture flags go on ggml-cpu only,
everything is hidden except `tw_*`, and Windows ARM64, x86 and Android armeabi-v7a get a stub library that reports
`ENGINE_NOT_BUILT`. Options: `TW_OPENMP` (ON on Android, linked with `-static-openmp`; OFF elsewhere) and
`TW_BUILD_SMOKE`.

| Platform | Built by | Output |
|---|---|---|
| Windows x64 | `windows/CMakeLists.txt` from `flutter build windows` | `tapture_whisper.dll` beside `tapture.exe` |
| Linux x64 / arm64 | `linux/CMakeLists.txt` (mirrors Windows; compiled in CI, task 130) | `bundle/lib/libtapture_whisper.so` |
| Android arm64-v8a, x86_64, armeabi-v7a (stub) | `android/build.gradle` (AGP runs `src/CMakeLists.txt`) | `libtapture_whisper.so`, 16 KiB pages |

### Without Flutter: MSVC and `tw_smoke`

From `frontend/`, with the CMake that ships with Visual Studio 2026:

```sh
cmake -S packages/tapture_whisper/src -B build/tw-windows -G "Visual Studio 18 2026" -A x64 -DTW_BUILD_SMOKE=ON
cmake --build build/tw-windows --config Release
build/tw-windows/Release/tw_smoke --self-test
build/tw-windows/Release/tw_smoke --model assets/speech/ggml-tiny-q5_1.bin \
  --sha256 818710568da3ca15689e31a743197b520007872ff9576237bda97bd1b469c3d7 \
  --wav packages/tapture_whisper/third_party/whisper.cpp/samples/jfk.wav \
  --expect "ask not what your country can do for you" [--abort-after-checks 50]
```

`tw_smoke` exits with the failing call's status (for example 15 for `MODEL_MISMATCH`), 20 when the phrase is missing,
21 when an abort run is not `ABORTED` or its retry fails, 22 when a live object is left, and 23 when the SHA-256
NIST vectors fail. `--bytes N` sets the expected size (default: the file's own).

### Without Gradle: Android NDK, CMake and Ninja

The APK build needs Gradle (CI, task 130), but the library itself builds with the SDK's CMake 3.22.1 and Ninja:

```sh
SDK="$LOCALAPPDATA/Android/Sdk"
for abi in arm64-v8a x86_64 armeabi-v7a; do
  "$SDK/cmake/3.22.1/bin/cmake" -S packages/tapture_whisper/src -B build/tw-android-$abi -G Ninja \
    -DCMAKE_MAKE_PROGRAM="$SDK/cmake/3.22.1/bin/ninja" \
    -DCMAKE_TOOLCHAIN_FILE="$SDK/ndk/28.2.13676358/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=$abi -DANDROID_PLATFORM=24 -DANDROID_STL=c++_static -DCMAKE_BUILD_TYPE=Release
  "$SDK/cmake/3.22.1/bin/cmake" --build build/tw-android-$abi
done
dart run tool/check_native_library.dart build/tw-android-*/libtapture_whisper.so
```

`tool/check_native_library.dart` fails any `PT_LOAD` aligned below 16 KiB, any export outside `tw_*` and any
`DT_NEEDED` outside `libc.so`, `libm.so`, `libdl.so` and `liblog.so` (so a `libomp.so` or `libc++_shared.so`
dependency is caught).

## WebAssembly (dev-plan task 111, app-write-up §30.4.8)

The same shim and source list compile with Emscripten into two ES-module factories (`createTaptureWhisper`) committed
under `frontend/web/whisper/`: `tapture_whisper_st` (one thread) and `tapture_whisper_mt` (pthreads, a strict pool of
8 workers, at most 4 compute threads). Both use SIMD128 and native wasm exceptions, `ENVIRONMENT=worker,node`, no
filesystem, a 64 MB to 2 GB growable heap and a 5 MB stack. `src/CMakeLists.txt` holds every flag and writes them to
`tw_wasm_flags.txt` for the build record. Two web-only settings keep the heap near what is used: ggml's split-input
context is sized for 1 input (one CPU backend never copies one; the default 30 commits about 70 MB per scheduler) and
a growth step adds at most 2 MB. Measured under Node after loading: tiny about 277 MiB, base about 326 MiB; most of it
is whisper's own `n_vocab × n_text_ctx` logits reserve and worst-case decode buffer (93 MB each, for any model).

Run from `frontend/`; `--build` needs the pinned emsdk activated (in Git Bash on Windows, set `EMSDK_PYTHON` to the
emsdk's own `python.exe` first), `--check` needs nothing:

```sh
source /path/to/emsdk/emsdk_env.sh            # must report emcc 6.0.11 (wasm/emsdk_version.txt)
dart run tool/whisper_wasm.dart --build --smoke   # build/tw-wasm-{st,mt} -> web/whisper, then the Node smoke
dart run tool/whisper_wasm.dart --check           # hashes, ABI, export list, worker tables
dart run tool/whisper_wasm.dart --smoke           # node wasm/smoke.mjs --variant st, then mt
```

- `--build` refuses any emcc other than the pinned release, takes CMake and Ninja from `$CMAKE`/`$NINJA`, then the
  Android SDK's `cmake/<version>/bin`, then `PATH`, and writes `web/whisper/LICENSES.txt` (this package's four blocks
  plus Emscripten, musl, libc++/libc++abi/libunwind and compiler-rt) and `web/whisper/BUILD_INFO.json`
  (`abi, whisper, commit, patches, emsdk, flags, inputs, files`, SHA-256 of text with LF line ends).
- `--check` reports, with `path:line`, every input or artifact whose hash differs from `BUILD_INFO.json`, an ABI or
  emsdk drift, an export list that is not exactly the header's `TW_API` names, a glue file missing one of them, and a
  worker struct or status table that differs from `TW_SIZEOF_*`, `tw_struct_id` or `tw_status`.
- `wasm/smoke.mjs` runs the committed `web/whisper/whisper_worker.js` in a Node worker thread standing in for a
  browser module worker, with the models served from `127.0.0.1`: init and struct sizes, cross-origin refusal, wrong
  SHA-256 and size refused with `model_mismatch`, the jfk phrase with tiny, `floor(n/512)` Silero probabilities, and on
  mt an `Atomics.store` abort plus 50 consecutive 4-thread decodes with `liveObjects` unchanged.

`web/whisper/whisper_worker.js` is hand-written. It picks mt only when `crossOriginIsolated` and `SharedArrayBuffer`
exist (otherwise st, without an error), imports only its own directory, accepts only same-origin model URLs, caches
models in OPFS (`whisper-models/<cacheKey>`) and lends them to `tw_context_open_js` / `tw_vad_open_js` as a file id
read through `Module.twSourceRead`, so the model is never copied whole into the heap and the shim's SHA-256 replaces
`crypto.subtle` (plain-HTTP LAN serving works). The protocol is documented at the top of the file.

### Serving with cross-origin isolation

Development and production use st unless the host sends both headers. `python run-tools/run-web.py --isolated` (and
the `tapture-web-preview-isolated` launch configuration, port 5181) adds them to the Flutter dev server. A production
host adds them to every response of the app:

```
Cross-Origin-Opener-Policy: same-origin
Cross-Origin-Embedder-Policy: credentialless
```

Safari does not support COEP `credentialless`, so it stays on st there. COOP `same-origin` severs `window.opener`
between the app and a sign-in popup on another origin, so check every sign-in flow on the isolated host before
enabling the headers in production.

## Pub workspace

`frontend/pubspec.yaml` lists this package under `workspace:` and depends on it in block YAML:

```yaml
tapture_whisper:
  path: packages/tapture_whisper
  version: 1.9.4+1
```

Flutter 3.44.6 resolves the workspace with `flutter pub get`, so the documented fallback (no `workspace:`, excluding
`packages/**` from the app's analysis and analysing the package on its own) was not needed. `dart analyze` from
`frontend/` covers this package under `analysis_options.yaml`, which includes the strict options of
`frontend/lib/core/`.

## Tests

`test/` is local, like every Tapture test suite. `test/package_manifest_test.dart` checks the pubspec's plugin
platforms, the absence of a build hook and an example app, and the four `LICENSE` blocks. The vendoring tool's own
tests are `frontend/test/tool/whisper_vendor_test.dart`; the WebAssembly tool's are
`frontend/test/tool/whisper_wasm_test.dart`.
