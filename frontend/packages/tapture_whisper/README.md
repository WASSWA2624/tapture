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
| `darwin/tapture_whisper/Sources/tapture_whisper/` | Generated forwarders for the Apple builds (see below) |
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
header per vendored header, and `include/tapture_whisper.h`. The podspec and `Package.swift` that compile them belong
to dev-plan task 105.

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
tests are `frontend/test/tool/whisper_vendor_test.dart`.
