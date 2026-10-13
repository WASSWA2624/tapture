# 168 — Remove obsolete repository files without changing app behavior

**Implementation started:** Yes

## Implement

Audit the entire repository for obsolete files, using application, test, build,
asset, platform and deployment references. Remove only proven unused modules,
superseded one-off helpers and reproducible caches. Preserve UI geometry, assets,
behavior, public contracts, raw evidence and historical acceptance records.
Prevent the Android native build cache from being tracked again. Commit and push
the reviewed cleanup requested on 2026-10-13.

## Files

- `backend/src/domain/index.ts`
- `backend/src/jobs/index.ts`
- `backend/src/middleware/index.ts`
- `backend/src/repositories/index.ts`
- `backend/src/services/index.ts`
- `backend/src/services/auth/register.ts`
- `backend/src/services/users.ts`
- `frontend/packages/tapture_whisper/android/.cxx/`
- `frontend/test/architecture/support/owned_resource_flow.dart`
- `frontend/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md`
- `backend/dist/src/` (only the seven stale compiled counterparts)
- `branding/tool/__pycache__/`
- `run-tools/__pycache__/`
- `run-tools/build-or-update-deploys/__pycache__/`
- `run-tools/tests/__pycache__/`
- `.tmp-task144-branding-contact.py`
- `.gitignore`
- `dev-plan/27-hardening/42-remove-obsolete-repository-files-without-changing-app-behavior.md`
- Generated `dev-tracker.md`

## Constraints

The audit is independent of unfinished feature/release acceptance. Do not remove
forward migrations, generated runtime code, vendored native inputs, published
contracts, feedback sources or acceptance evidence. Do not change application
screens, business behavior or dependencies. Existing unrelated verification gaps
remain attributed to their original tasks.

## Definition of done

- [x] Frontend, backend and repository support inventories are audited; every
      deletion has reference/build evidence and retained contracts are recorded.
- [x] Proven obsolete files and reproducible caches are removed, and native
      `.cxx` caches are ignored for both the app and local plugin builds.
- [ ] Tests: retained frontend analysis, native source/vendor checks, plugin and
      relevant tooling tests pass; retained application/UI/assets are unchanged.
- [x] Tests: backend format, lint, type checks, unit, integration and contract
      verification pass through `npm run verify` with no skipped database cases.
- [x] Plan/tracker checks pass and the final cleanup diff is reviewed and ready
      for the requested commit and push.

## Evidence

Initial tree: clean at `c4300dda`. The parallel audit covers Flutter sources,
declared assets, native platform inputs, backend runtime/test/tool entry points,
migrations, deployment scripts and repository support folders. Android Gradle
builds the speech plugin from `../src/CMakeLists.txt`; its `.cxx` tree contains
362 tracked generated files totaling 119,940,571 bytes and is never a source input.
The tracked Python cache is 41,126 bytes. Historical comparison images, feedback
archives, build proof reports, shipping-audit scripts and `recordAudit`'s declared
service contract are retained.

The backend import graph has no callers for five implementation-layer barrels
or two aliases. Local ignored backend tests still import the relay-schema and
key-custody modules, so those files are retained. The current raw-data
guardrail imports `owned_file_cleanup.dart`; the old `OwnedResourceFlow` helper has
no callers. The one-off branding contact-sheet script depends on archived golden
inputs and has no application, build or test caller; its comparison PNGs remain.

The corrected backend audit includes all 169 on-disk TypeScript files and 69
auto-discovered test roots, including ignored tests. The first tracked-file-only
audit missed the relay/key-custody test consumers; both modules were restored
byte-for-byte before final verification. Seven remaining barrels/aliases have
zero incoming imports, and the private package publishes none of their paths.

Whole-frontend analysis reports six existing local test errors: five synchronous
assignments of `FutureOr<String?>` in route/current-project tests and the staging
fixture's missing `BlobStore.removeTree` implementation. The broad tool run also
reproduces task [111](../24-product-refinements.md)'s already-open shim/header
provenance mismatch against `web/whisper/BUILD_INFO.json`. All implicated sources,
tests, checker and recorded web artifacts are unchanged from `c4300dda`; the
checker normalizes CRLF before hashing. Task [147](../02-foundation.md)'s affected
routing/storage regression acceptance and task 111's first criterion remain open.
Cleanup does not repair or weaken those unrelated checks; frontend verification
acceptance above remains open.

The raw-data guardrail passes all 10 cases, including compliant/violating fixtures
and exhaustive file/line diagnostics. Vendor integrity and repository hygiene
checks pass. All 59 plugin unit tests pass from the package directory; the earlier
workspace-root invocation's package-relative fixture failures were corrected by
that rerun. The broader run passes 124 cases and retains the existing shipped
WebAssembly provenance failure. Plan integrity passes, and a protected-path diff
confirms all runtime UI/assets/platform/native-source/dependency inputs unchanged.
The final deletion inventory contains 373 tracked files with 119,963,706 original
Git blob bytes; nine additional ignored Python cache files and their empty folders
were removed locally.

Final backend `npm run verify` exits 0: format, lint, types, tests, dependency audit
and secret scan all pass. There are 191 tests: 190 passed, none failed and one
Docker-runtime test skipped because Docker is unavailable. Every PostgreSQL case
runs against an isolated PostgreSQL 16.15 cluster and database, which is stopped
afterward; no shared database is used. Dependency audit reports zero vulnerabilities.
The final log is retained in the temporary
`tapture-cleanup-pg-b7791af0e63a4942ac9df1c663644ea4/verify-final.log` evidence folder.

Seven stale ignored `.js` counterparts were removed from `backend/dist/src/`;
active output and the restored schema/key modules remain. The default Flutter
iOS launch-image README is also removed: it has no reference or asset-catalog
entry, and its manual image-editing guidance is superseded by the maintained
branding generators/docs. The launch images and their `Contents.json` are
unchanged. `frontend/README.md` is retained for its distinct database, template
generation and AI-processing contracts.

The production debug Android APK rebuild passes from an absent native cache
(`assembleProdDebug`, 678.3 s). It regenerates 66 native objects and packages all
three speech ABIs. Each packaged speech library is byte-identical to the preserved
pre-cleanup APK and passes the native checker (16 KiB alignment, `tw_*` exports,
system libraries only). All three bundled models retain their pinned sizes and
SHA-256 hashes (92,745,396 bytes total); APK ZIP integrity passes. Previous APKs
and cache diagnostic logs were preserved. Evidence is under
`frontend/build/task168-native-rebuild-20261013T052208048/`; the fresh `.cxx` output
is ignored and has no tracked entries.

Final staged review passes the exact-path allowlist and whitespace checks: 373
deletions, the cache-ignore rule, this task and the generated tracker only. No
unstaged or unrelated change remains. Task status is **Partially complete** solely
because the unchanged frontend analysis/provenance checks above remain failing;
the reviewed cleanup is ready for the requested commit and push.
