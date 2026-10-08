# 152 — Diagnose and restore WebAssembly compiler validation

**Depends on** [001](../01-orchestration.md)

## Implement

Diagnose the internal Dart 3.12.2 frontend crash observed during Flutter 3.44.6's optional WebAssembly dry run.
Reduce the current application reproduction to the offending source and a small retained fixture, distinguish
an application/package problem from an SDK problem, and restore successful compiler validation through a
supported correction. Preserve the verified Android and JavaScript release paths and the independent native/
browser encrypted-envelope contract.

Capture both compiler output streams: this Flutter version's unexpected-failure reporting can omit a diagnostic
written only to stdout. Retain the original failure beside later successful evidence. A dry-run stamp with no
outputs does not establish success. This task validates Dart WebAssembly compilation; task 111 separately owns
the Whisper WebAssembly asset's build provenance.

## Files

- `frontend/test/tool/fixtures/wasm/` (new reduced compiler reproduction)
- Only the source/package constraint identified by the reduced reproduction, if a supported correction requires it
- `frontend/.gitignore` (only exact exceptions needed to ship the new fixture)
- `dev-plan/02-foundation.md` (task 147's recorded verification limitation)
- This task's evidence and generated `dev-tracker.md`

## Constraints

- Do not disable the dry run, remove its reporting, weaken checks, change encryption/database formats, or patch the
  installed SDK or package cache. A source workaround must preserve behavior and have focused regression coverage.
- A supported SDK or package change must respect the repository's dependency allowlist, installed-data migration
  requirements and release-toolchain contracts. Do not infer that exit 252 means memory exhaustion or that a
  compiler crash identifies faulty application code.
- Preserve task 146's delivered test-image cleanup and all existing raw failure evidence.

## Definition of done

- [ ] A retained minimal reproduction identifies the offending source and distinguishes the compiler defect from ordinary unsupported-WebAssembly findings; both output streams, SDK versions, inputs and exit status are recorded.
- [ ] A supported correction makes the reduced reproduction and the unchanged application WebAssembly dry run exit successfully, with focused behavior regression coverage if repository code changes.
- [ ] Whole-frontend analysis, changed-source formatting, the production Android APK and normal JavaScript web release build pass with the corrected graph.
- [ ] Real Chrome SQLite/export, PDF rendering and independent cipher parity/cancellation tests remain green; native legacy cipher/schema regression coverage remains intact.
- [ ] Task 147's WebAssembly limitation is updated only against fresh successful evidence; tracker synchronization, `--check` and plan integrity checks pass.

## Evidence

2026-10-09: task 147's normal JavaScript release build exits 0 but reports an optional dry-run failure with exit
252 and no diagnostic. A direct installed-SDK reproduction using the same generated entrypoint, release/skwasm
defines and dry-run settings also exits 252. Stdout reports "Null check operator used on a null value" in
`ForInStatement.getElementTypeInternal`, followed by `_WasmTransformer._lowerForIn` while traversing an
`AssertBlock`; stderr is empty. The trace does not identify a source location or establish an application/package
cause. The SDK's [exit-code definition](https://github.com/dart-lang/sdk/blob/3.12.2/runtime/bin/error_exit.h)
identifies 252 as an internal frontend error, distinct from the ordinary compilation-error code 254.

Raw application-build output, both isolated compiler streams and the exit status are retained in
`frontend/build/task147-web-build.log`, `frontend/build/task147-wasm-dry-run.stdout.log`,
`frontend/build/task147-wasm-dry-run.stderr.log` and `frontend/build/task147-wasm-dry-run.exit.txt`. Android and
JavaScript release builds and whole-frontend analysis pass. No SDK/cache patch or warning-suppression flag was
used. Implementation of the reduced fixture/correction has not begun; all acceptance items remain open.
