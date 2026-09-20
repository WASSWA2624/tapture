# Tapture — development tracker

**100 of 281 tasks complete (35.6%)** · last updated 2026-09-20

`██████████████░░░░░░░░░░░░░░░░░░░░░░░░░░`

## Phase progress

| Phase | Done | Total | Progress |
| :--- | ---: | ---: | :--- |
| 01 — Project setup and guardrails | 18 | 18 | `██████████████` 100% |
| 02 — Foundation services | 11 | 11 | `██████████████` 100% |
| 03 — Design system | 19 | 19 | `██████████████` 100% |
| 04 — Local database | 16 | 16 | `██████████████` 100% |
| 05 — File storage | 7 | 7 | `██████████████` 100% |
| 06 — Application shell | 5 | 5 | `██████████████` 100% |
| 07 — Account and settings | 5 | 5 | `██████████████` 100% |
| 08 — Projects | 6 | 6 | `██████████████` 100% |
| 09 — Templates | 13 | 17 | `███████████░░░` 76% |
| 10 — Reference data | 0 | 8 | `░░░░░░░░░░░░░░` 0% |
| 11 — Context | 0 | 7 | `░░░░░░░░░░░░░░` 0% |
| 12 — Capture | 0 | 22 | `░░░░░░░░░░░░░░` 0% |
| 13 — Processing | 0 | 20 | `░░░░░░░░░░░░░░` 0% |
| 14 — Records | 0 | 8 | `░░░░░░░░░░░░░░` 0% |
| 15 — Data quality | 0 | 10 | `░░░░░░░░░░░░░░` 0% |
| 16 — Review | 0 | 6 | `░░░░░░░░░░░░░░` 0% |
| 17 — Meetings | 0 | 7 | `░░░░░░░░░░░░░░` 0% |
| 18 — Export | 0 | 15 | `░░░░░░░░░░░░░░` 0% |
| 19 — Bundles and merge | 0 | 12 | `░░░░░░░░░░░░░░` 0% |
| 20 — Data import | 0 | 4 | `░░░░░░░░░░░░░░` 0% |
| 21 — Cloud upload | 0 | 6 | `░░░░░░░░░░░░░░` 0% |
| 22 — Privacy and security | 0 | 6 | `░░░░░░░░░░░░░░` 0% |
| 23 — Hardening | 0 | 9 | `░░░░░░░░░░░░░░` 0% |
| 24 — The minimal backend | 0 | 26 | `░░░░░░░░░░░░░░` 0% |
| 25 — Testing and release | 0 | 11 | `░░░░░░░░░░░░░░` 0% |
| **Total** | **100** | **281** | `████░░░░░░░░░░` 35.6% |

## Completed

| Task | Closed | What landed |
| :--- | :--- | :--- |
| 001 — Create the Flutter project | 2026-09-09 | App id `com.tapture.app`, label Tapture, demo code removed, `test/smoke_test.dart` green. |
| 002 — Repository hygiene files | 2026-09-09 | `.gitignore` + `.editorconfig`, guarded by `tool/check_repo_hygiene.dart` and 9 tests. |
| 003 — Strict analyzer configuration | 2026-09-09 | `strict-casts`/`-inference`/`-raw-types` on, all 171 enabled rules and diagnostics promoted to error, `public_member_api_docs` scoped to `lib/core/`; guarded by `tool/check_analyzer_config.dart`, 14 config tests and 29 analyzer fixtures. |
| 004 — Create the folder skeleton | 2026-09-09 | 99 directories under `lib/` — `app/`, 28 shared subsystems, 17 features × 3 layers — each owning a barrel; canonical list in `tool/paths.dart`, guarded by `tool/check_structure.dart` and 15 tests. |
| 005 — Dependency allowlist checker | 2026-09-09 | `tool/allowlist.yaml` approves 3 packages with pinned version, purpose and introducing task; `tool/check_dependencies.dart` reads additions and version drift as errors and removals as warnings, guarded by 12 tests. |
| 006 — Plan integrity checker | 2026-09-09 | `tool/check_plan.dart` validates all 281 task files — heading against filename, unique and contiguous numbers, unique slugs, required sections, a tickable Definition of done, and dependency links that resolve and point lower; guarded by 18 tests. |
| 010 — Layering enforcement test | 2026-09-09 | `test/architecture/import_graph.dart` builds the graph from every directive under `lib/` and reads it against all four clauses of FE-STR-04 plus FE-STR-08; a clean and a violating fixture under `test/architecture/fixtures/` prove both directions. Guarded by 20 tests. |
| 011 — Naming and file-layout checker | 2026-09-09 | `tool/check_naming.dart` reads every hand-written file under `lib/` and reports a file name that is not snake_case, a first public type that is not the one the file is named for, a second public class sharing a file, a provider that is not lowerCamelCase ending in `Provider`, and a type built out of a banned word — matched a whole camel-case word at a time, so `ReferenceDataset` passes where `RecordData` does not, and read from declarations only, so Flutter's `ThemeData` is never flagged. Guarded by 42 tests. |
| 012 — Canonical domain names | 2026-09-17 | `lib/core/naming/domain_names.dart` holds the twelve specification type names; `test/architecture/naming_test.dart` fails a declared synonym with the canonical replacement. Whole identifiers only, so `ReferenceDataset` passes and `RecordData` does not; uses of Flutter's `ThemeData` are ignored. Guarded by 9 tests. |
| 013 — Design-token and responsive boundary tests | 2026-09-17 | `test/architecture/tokens_test.dart` fails a feature that invents `Color`, `Colors.*`, `EdgeInsets.all(n)`, `BorderRadius.circular(n)`, `Duration(` or `TextStyle(` and names the token to use instead; `app/theme/` and `core/widgets/` keep those literals. `test/architecture/responsive_test.dart` fails a feature that compares `MediaQuery` width or hardcodes a width at or above 600, naming `context.sizeClass` / `SizeClass.expanded`; only `core/widgets/responsive/` may measure the window. Guarded by 14 tests over allowed and forbidden fixtures. |
| 014 — State and error-handling convention tests | 2026-09-17 | `test/architecture/state_test.dart` fails a widget that calls a repository, a provider declared outside the feature its name belongs to, `setState` outside `core/widgets/` and animation code, and a controller with no intent method. `test/architecture/errors_test.dart` fails a repository method that is not `Result`/`Future<Result>`, a `Failure` with no `message`, and a `throw` of a non-`Failure` under `domain/` or `data/`. Guarded by 18 tests over compliant and non-compliant fixtures. Did not add Riverpod — the task names only the two suites. |
| 015 — Logging discipline and secret scan | 2026-09-17 | `tool/check_logging.dart` bans `print`/`debugPrint` outside `tool/` and `test/`, requires a level and a tag, and fails a log line that interpolates a key, secret, token, password, credential, caption, transcript or value. `tool/check_secrets.dart` scans `lib/`, `android/`, `ios/` and `assets/` against named patterns in `tool/secret_patterns.yaml` and never prints the match. Guarded by 37 tests. |
| 016 — Test presence checker | 2026-09-17 | `tool/check_tests.dart` reports every `domain/`, `data/` and `core/widgets/` file, plus presentation screens, that owes a test and has none; barrels, generated files and integration-covered screens are exempt. `--strict` fails the run and names the missing `test/…_test.dart` path. `verify.dart` calls the strict run. Guarded by 13 tests. |
| 017 — Accessibility test matchers | 2026-09-17 | `test/support/a11y_matchers.dart` provides `hasSemanticLabel`, `meetsTapTarget` (48dp) and `expectNoA11yIssues`, which runs the framework guidelines and asserts 200 percent text scale does not clip in either orientation. Failures name the widget and the measured value. Guarded by 7 tests. |
| 018 — Network boundary and raw-data safety tests | 2026-09-17 | `test/architecture/network_test.dart` fails an HTTP import outside `core/ai/`, `core/cloud/` and `core/backend/`, and a widget or `domain/` file that names a network client. `test/architecture/data_safety_test.dart` fails a write to `valueRaw`/`textRaw`/`transcriptRaw` outside a repository create method, a hard row delete, and a `File.delete` outside the purge job. Guarded by 18 tests over allowed and forbidden fixtures. Did not add `lib/core/backend/` — the task names only the two suites. |
| 019 — Application bootstrap, flavours and lifecycle | 2026-09-17 | Guarded `main()` installs `FlutterError`/`runZonedGuarded` handlers, `ProviderScope`, a `MaterialApp.router` placeholder and `LifecycleObserver` before the first frame. `Env` reads `FLAVOR` / `FLUTTER_APP_FLAVOR` (default prod) with a test override. Android `dev`/`prod` flavours get distinct application ids and labels. `flutter_riverpod` ^3.4.3 pinned on the allowlist so `ConsumerWidget` exists. Guarded by 3 new suites. |
| 020 — Shared constants | 2026-09-17 | `AppConstants` holds page size 50, image long edge 1600, and every later-phase duration, ceiling, threshold and secure-storage key name, grouped by area as const records (`lists`, `images`, `secrets`, …). `test/core/app_constants_test.dart` asserts ranges and unique key names. |
| 021 — Result type, failure taxonomy and error boundary | 2026-09-17 | Sealed `Failure` (seven variants, each with message and recovery action) and `Result<T>` (`map`/`flatMap`/`fold`/`getOrElse`/`capture`) in `core/errors/` with no Flutter import. `ErrorBoundary` replaces a throwing child with a retry panel. Variants live in `part` files so sealed and one-class-per-file both hold. Guarded by 8 tests. |
| 022 — Logger, diagnostics export and provider observer | 2026-09-17 | `Logger` with levels, tags, a bounded redacting buffer and rotating-file persist (`persist: true`). `exportLog` writes a dated, device-named file. `AppProviderObserver` logs one error per provider failure and rebuilds above the threshold, installed only in the dev flavour. Guarded by 14 tests. |
| 023 — Clock, identifiers and device identity | 2026-09-17 | `Clock` (`SystemClock` / `FixedClock`), `IdService` / `UuidV7Service` (time-ordered, sequence fake for tests), and `deviceId` / `deviceDescriptor`. `DateTime.now` is documented as legal only in `SystemClock`. Device id is minted once and read back from memory or a file. Guarded by 10 tests. |
| 024 — Hashing service and isolate runner | 2026-09-17 | `sha256OfFile` streams 64KiB chunks on `runIsolate`; `sha256OfString` is the sync digest. `CancellationToken` kills the worker and returns `CancelledFailure`. `crypto` ^3.0.7 pinned on the allowlist. Guarded by 8 tests. |
| 025 — Connectivity service | 2026-09-17 | `watch()` folds the radio and the manual override; override on is always `offline`. `metered` is distinct from `online`. Plugin reached only here; tests use `ConnectivityService.fake`. `connectivity_plus` ^7.3.1 pinned on the allowlist. Guarded by 3 tests. |
| 026 — Runtime permissions service | 2026-09-17 | `request`/`status` wrap camera, microphone, location and storage. A denial is `PermissionFailure` with a recovery action; permanent denial opens settings instead of prompting again. Location is not requested while GPS is off. `permission_handler` ^12.0.3 pinned on the allowlist. Guarded by 13 tests. |
| 027 — Secure storage service | 2026-09-17 | Typed `putSecret`/`readSecret`/`deleteAll` over a closed `SecretKey` enum mapped to `AppConstants.secrets`. Fake backing store survives a simulated restart; debug asserts keep values out of preferences and the database. `flutter_secure_storage` ^9.2.4 pinned on the allowlist. Guarded by 3 tests. |
| 028 — Serialisation conventions | 2026-09-17 | `build.yaml` pins json_serializable to explicit `@JsonKey` wire names (`field_rename: none`). `UtcDateTimeConverter`, `JsonMapConverter` and `EnumWireConverter` round-trip UTC dates, maps (null → empty) and enums; an unknown wire name throws. `json_annotation` ^4.9.0, `json_serializable` ^6.9.0 and `build_runner` ^2.4.13 pinned on the allowlist. Guarded by 3 tests. |
| 029 — AI service interface | 2026-09-17 | `AiService` with typed requests/results for `readText`, `extractFields`, `refineText` and `transcribe`, each returning `Result`. `AiService.unavailable()` is the disabled stand-in: `ProviderFailure` plus a recovery action on every method, no key on the interface. Quoted OCR, transcripts and labels live on the request as data. Guarded by 7 tests. |
| 030 — Design tokens: colour, type, spacing and elevation | 2026-09-17 | Light, dark and outdoor palettes on `context.colors`, type ramp, 4-point space scale and tone-plus-outline elevation. Swatch, type-ramp and surface-level gallery pages with goldens. Contrast is asserted, not eyeballed. Guarded by token-set, contrast, elevation and golden tests. |
| 031 — Material 3 themes and the theme mode controller | 2026-09-17 | `buildTheme` / `buildOutdoorTheme` assemble ColorScheme, TextTheme and component themes from tokens. `ThemeModeController` persists `AppThemeMode` through `TextStore` (memory fake + file) and restores before the first frame. `TaptureApp` resolves the active `ThemeData`. Guarded by round-trip, first-frame, geometry and three-mode goldens. |
| 032 — Breakpoints, responsive builder and readable width | 2026-09-17 | `SizeClass` owns 600/1024. `context.responsive` / `ResponsiveBuilder` fall back to the next smaller class. `ContentConstraint` centres a 720dp readable column. Guarded by edge-resolution, fallback, two-pane, resize-keeps-input and three-mode goldens. |
| 033 — Page scaffold | 2026-09-17 | `AppPage` is the one `Scaffold`: themed app bar, optional subtitle, action slot, scrolling body, optional footer, size-class padding, `ContentConstraint`, safe-area and keyboard insets, and pull-to-refresh only when `onRefresh` is given. Guarded by refresh presence, 200 percent scroll in both orientations, rotation, and 9 goldens. |
| 034 — Buttons, icon buttons and the primary action | 2026-09-17 | `AppButton` (four variants, busy swallows taps), `AppIconButton` (required label and tooltip) and `AppPrimaryAction` (full-width, glove-tall, optional caption) are the only buttons features may compose. Guarded by busy-tap, 48dp, 200 percent text, and goldens per variant and state in three modes. |
| 035 — Text, number, date and search fields | 2026-09-17 | `AppTextField` is the base input; `AppNumberField` rejects letters and flags out-of-range in the shared error style; `AppDateField` formats through `intl` against a `Clock`; `AppSearchField` debounces at `AppConstants.interaction.debounce`. Guarded by clear/error, non-numeric rejection, frozen-clock modes, fake-async debounce, and 12 goldens. |
| 036 — Choice, multi-choice and boolean fields | 2026-09-17 | `Choice` is the shared option; `AppChoiceField` is segmented under four options and a searchable sheet at four or more; `AppMultiChoiceField` shows selected values as chips and offers select-all/clear in the sheet; `AppSwitchTile` (and `.checkbox`) is the full-width boolean. Guarded by the four-option boundary, 200-option search, whole-tile toggle, and 9 goldens. |
| 037 — Chip and chip row | 2026-09-17 | `AppChip` is plain, selectable (tick plus tint) and dismissible from one widget; a chip with no callback is not a tap target. `AppChipRow` wraps or scrolls without clipping a label. Multi-choice now composes these. Guarded by tap/dismiss, wrap versus scroll, 200 percent ellipsis, and 3 goldens. |
| 038 — Card, list tile and section header | 2026-09-17 | `AppCard` takes surface treatment from `Elevation.surface` and is tappable only with `onTap`. `AppListTile` is the one row for projects, records, templates and datasets — dense or comfortable, selected with a tick, status slot, trailing, tap opens and long-press selects. `AppSectionHeader` uses the section type role. Guarded by tap/long-press, selection+status not colour alone, 200 percent, and 9 goldens. |
| 039 — Status pill and badge | 2026-09-17 | `AppStatusPill` and `StatusStyle.of` map every `RecordStatus` to colour, icon and label; `.badge` fits list rows. Screens cannot map status to colour themselves. Guarded by an exhaustive style test, icon-and-label widget tests, 200 percent, and 3 goldens of every status. |
| 040 — Empty, error, loading and async value view | 2026-09-17 | `AppEmptyState`, `AppErrorState`, `AppSkeleton` and `AsyncValueView` are the four non-data states. Failures render from a typed `Failure`; screens hand the provider to `AsyncValueView` and write no switch of their own. Guarded by a widget test per failure subtype, loading/error/empty/data, 200 percent, and 3 goldens. |
| 041 — Dialog, sheet, snackbar and banner | 2026-09-17 | `showAppConfirm` / `showAppAlert`, `showAppSheet` (side panel when expanded), `showAppSnack` (queued, optional undo) and `AppBanner` are the one interrupt API. Choice fields now open through the sheet. Guarded by confirm/cancel, undo, snack queue, compact vs expanded sheet, 200 percent, and 3 goldens. |
| 042 — Step progress list | 2026-09-17 | `AppProgressSteps` renders done, running, waiting and failed with an icon plus text so colour is never the only signal. A state change is announced and does not move the steps below it. Guarded by a position-and-semantics widget test, 200 percent, and 3 goldens of every state plus a mixed list. |
| 043 — Photo thumbnail | 2026-09-17 | `AppPhotoThumb` is the one square every photo renders through: type badge and caption overlays, selection tick plus border, missing-file placeholder, 1:1 `BoxFit.cover`, cached thumb path never the original. `PhotoAsset` / `PhotoType` live in a part file until capture owns them. Guarded by never-decode and missing-file widget tests, 200 percent, and 3 goldens of badge, caption, selected, unselected and error. |
| 044 — Form scaffold, validation display and focus behaviour | 2026-09-17 | `AppForm` spaces fields, lists every invalid field at the top, pins a busy submit bar, and prompts on a dirty pop. `FocusActions` dismisses the keyboard and advances in visual order; `KeepFocusedVisible` keeps the focused field above the inset. Guarded by unsaved-guard, double-submit, focus-order and keyboard-inset widget tests, 200 percent, and 3 goldens with and without the error summary. |
| 045 — Haptics service | 2026-09-17 | `Haptics` is the one caller of `HapticFeedback`: shutter (heavy), save (medium), warning (light), error (vibrate) and selection (click). `Haptics.fake` records names for tests. Disabled haptics suppress all five; reduced motion skips selection so capture and save still confirm by touch. Guarded by fire-once, disabled, and reduced-motion unit tests. |
| 046 — User-facing copy helper | 2026-09-17 | `Copy` is the one catalogue of visible strings, keyed by meaning, with ICU plurals for counts. Catalogue widgets read from it; template labels stay user data. Guarded by 0/1/2 plural tests and a synonym scan against the naming checker. |
| 047 — Widget gallery screen | 2026-09-17 | `WidgetGalleryScreen` at `/_gallery` lists every catalogue widget by family, with theme, width and text-scale switchers. Debug router only. Guarded by an enumeration of `core/widgets/` and goldens of the index in light, dark and outdoor. |
| 048 — Golden test baselines for the catalogue | 2026-09-17 | `expectGolden` pins Ahem, disables animation, and compares light, dark and outdoor under `test/design_system/goldens/`. Every catalogue widget plus the gallery index has a baseline; a one-pixel fixture fails and names the widget and mode. Guarded by an enumeration of `core/widgets/` and the CI golden gate. |
| 049 — Drift database bootstrap and migration strategy | 2026-09-17 | `AppDatabase` opens a lazy WAL file in application support (or `memory()` for tests), `kSchemaVersion` is 1, and `appMigration` walks numbered named steps. Destructive steps throw `StorageFailure` until `acknowledgeExport`. Drift 2.31 / sqlite3 2.9.4 so native-asset hooks do not prefix `dart run`. Guarded by in-memory close, file reopen, v1-to-head column/row compare, and a missing-step/test check. |
| 050 — Shared columns, DAO base and transaction helper | 2026-09-17 | `MergeColumns` supplies id (UUIDv7 text), timestamps, device and rev. `BaseDao` watches, pages, upserts with a rev/`updatedAt` stamp, and soft-deletes through a tombstone hook. `runInTransaction` joins an open write instead of nesting. Sqlite uniqueness and busy map to `StorageFailure`. Guarded by rev-bump, skip-helper, watch/get/page, uniqueness mapping, and nested rollback tests. |
| 051 — Tombstones, audit log and device profile tables | 2026-09-17 | Schema v2 adds `tombstones` (unique on entity type plus id), append-only `audit_log` with a history index, and a single `device_profile` row keyed `local`. `writeTombstone` is the `softDelete` hook; `appendAudit` and `ensureDeviceProfile` run in the caller's transaction. Guarded by delete-plus-tombstone atomicity, previous/new audit values, and idempotent first-launch tests. |
| 052 — Projects and context tables | 2026-09-17 | Schema v3 adds `projects` (indexed on status plus `updatedAt`, settings JSON validated on write) and context definitions, state and presets. Setting a higher context level deletes lower state rows in one transaction. Guarded by paged status list/index, malformed-settings refusal, cascade-clear and preset round-trip tests. |
| 053 — Templates, template fields and template rows tables | 2026-09-17 | Schema v4 adds `templates` (nullable `projectId` for shipped rows, version bump on header edit), `template_fields` unique on template plus field key, and `template_rows` with alias lookup in Dart. JSON columns are validated on write. Guarded by round-trip, uniqueness, sort-order, shipped-coexist and alias tests. |
| 054 — Records and record fields tables | 2026-09-17 | Schema v5 adds `records` (`RecordRow`, indexed on project+status, identity hash, capturedAt, template) and `record_fields` unique on record plus field key. `valueRaw` is append-only; refinement and approval write beside it and `appendAudit` in the same transaction. Guarded by paged list/index, identityHash lookup, raw-untouched, uniqueness, and v5 column tests. |
| 055 — Photos, attachments and captions tables | 2026-09-17 | Schema v6 adds `photos` and `attachments` unique on project plus sha256, and `captions` indexed by owner. Unfiled photos keep a null `recordId`; applying one caption writes one row per photo; `textRaw` is append-only. Guarded by hash uniqueness, document/audio variants, thirty-row apply, raw immutability, and v6 column tests. |
| 056 — Reference dataset tables | 2026-09-17 | Schema v7 adds `reference_datasets` and `reference_rows` unique on dataset plus key, with `keyNormalised` folded on write. Re-importing the same source file updates the dataset and matching rows in place. Guarded by insert, keyed/normalised lookup, in-place re-import, 10k lookup under 300ms, and v7 column tests. |
| 057 — Processing jobs, results and field evidence tables | 2026-09-17 | Schema v8 adds `processing_jobs` (indexed on status+queuedAt), append-only `processing_results`, and `field_evidence` indexed by record field. Claim is compare-and-swap on queued; retry increments attempts and keeps earlier results; deleting a field writes a tombstone so evidence is not orphaned. Guarded by queue/index, retry+immutability, three source types, tombstone, and v8 column tests. |
| 058 — Duplicates and variances tables | 2026-09-17 | Schema v9 adds `duplicates` (unique ordered record pair; indexed on projectId+status) and `variances` (unique recordId+fieldKey, plus projectId so the same index shape serves the review list). Detection upserts the existing pair and never writes a resolution; a person records who/when; source records stay intact. Guarded by order-independent uniqueness, queue+index, resolution, register-versus-found round-trip, unique index, and v9 column tests. |
| 059 — Meeting tables | 2026-09-17 | Schema v10 adds `meetings` (raw transcript written once, refined minutes beside it), `attendees` (captured name kept when a staff match is accepted), and `meeting_actions` indexed on meetingId+status. Delete is one transaction that tombstones the header and every child row without a hard delete. Guarded by round-trip+cascade tombstones, transcript immutability, staff-match name retention, and v10 column tests. |
| 060 — Exports table | 2026-09-17 | Schema v11 adds `exports` indexed on projectId+createdAt. Completing an export inserts one row with a per-project version; re-export is a new row and never rewrites path or hash; an abandoned or incomplete run writes none. History lists newest first through the index. Guarded by version increment, history+index, failed-export absence, and v11 column tests. |
| 061 — Merge session, conflict and version vector tables | 2026-09-17 | Schema v12 adds `merge_sessions`, `merge_conflicts` (indexed on sessionId+resolution) and `version_vectors` unique on entity+device. `compareVectors` reports dominates/dominated/concurrent/equal; resolving a conflict records who/when and bumps the local vector. Sessions keep the undo snapshot path across restart. Guarded by session+queue, resolution+vector bump, unique triple, four relations, classify-from-one-read, and v12 column tests. |
| 062 — Repository interfaces and test factories | 2026-09-17 | Eight domain ports return domain types and `Result` (watch lists stay `Stream`). Hand-written fakes honour the same failure contract; `aProject`/`aRecord`/`seededDatabase` make a valid graph in one line. Guarded by one fake suite per interface and a record-DAO read of the seeded graph. |
| 063 — Database integrity check | 2026-09-17 | Read-only `runIntegrityCheck` reports orphaned fields, missing photo/attachment files, jobs and evidence on gone records, deletes without tombstones, and `PRAGMA foreign_key_check`. Pages at list size; file stats run off the UI thread. Guarded by one-finding-per-problem, clean-empty, twice-unchanged, and row-count tests. |
| 064 — Optional database encryption | 2026-09-17 | `DatabaseEncryption` copies `tapture.sqlite` to HMAC-SHA-256-CTR ciphertext with the key only in secure storage. Enable is resumable, verifies per-table counts before removing the plain file, and disable needs typed confirmation. `AppDatabase.open(encryptionKey:)` decrypts through the same factory; a lost key is a `StorageFailure`, never a wipe. Guarded by no-key / with-key open, count round-trip, interrupted-enable, and lost-key tests. |
| 065 — Storage root resolution | 2026-09-17 | `StorageRoot` creates visible `Tapture/` and disposable `Tapture/.cache` under the documents directory, probes writability with a marker file, and memoises a successful resolve. Unwritable or missing locations return `StorageFailure` with the path and a recovery action; a storage denial is `PermissionFailure`. Guarded by temp-dir idempotent create, blocked-path / not-writable failure, and denial tests. |
| 066 — Project folder tree, name sanitiser and photo path builder | 2026-09-17 | `sanitiseSegment` refuses traversal, absolute paths, drive prefixes, device names and empty results; display names keep letters/digits/hyphens. `ProjectFolders` creates the eight-folder tree under `Tapture/projects/<name>__<id>` from stored `folderName` so a rename does not move files. `buildPhotoPath` covers byContext (spec path plus `_unfiled` gaps), byTemplate, byCaptureDate and flat. Guarded by hostile-input, temp-dir idempotent/rename, and strategy tests. |
| 067 — Atomic file writer and context relocation | 2026-09-17 | `FileWriter` streams to `<target>.part`, hashes in the same pass, flushes and renames so the target is absent or complete. Stale `.part` files are swept on the next write to that directory and never resumed. `FileRelocation` moves a record's photos (including `_unfiled` promotion) then updates `relativePath` in one transaction, rolling files back if the write fails. Guarded by interrupted-write, full-disk, hash-equality, unfiled, facility-rename, failed-move and failed-transaction tests. |
| 068 — Derived image cache: thumbnails, compressed copies and cleanup | 2026-09-17 | `ThumbnailCache` keys `<sha256>_<edge>` under `.cache/thumbs/`, decodes at most `concurrentDecodes` originals, and serves a second request from disk. `CompressedCopy` writes a long-edge copy through `FileWriter` into `.cache/upload/` without changing the original hash. `CacheCleanup` prunes by age then by size, oldest first, and never leaves `.cache`. Guarded by decode-count, hash-and-size, and fake-clock prune tests. |
| 069 — Storage headroom guard | 2026-09-17 | `StorageGuard` maps free bytes to `ample` / `low` / `critical` from `AppConstants.storage`, polls on resume and `beginSession` (not per shutter), warns once per low session while capture continues, and refuses a new capture at critical with export and cache cleanup on the `StorageFailure`. An in-flight `completeSave` still finishes. Guarded by a fake volume across both thresholds, one-warning, refusal, in-flight, and resume-versus-shutter tests. |
| 070 — Orphan file scanner | 2026-09-17 | `OrphanScanner` walks a project tree in pages, skips `.cache` and `.part`, and reports files with no row and rows with no file plus reclaimable bytes. Adoption inserts through `upsertPhoto` / `upsertAttachment` with hash and merge columns; `flagMissing` writes an audit flag and leaves the row intact. A cancelled scan returns `CancelledFailure` and changes nothing. Guarded by stray/missing/.cache, cancel, and adopt+flag tests. |
| 071 — Imported file validation | 2026-09-17 | `FileValidation` is the one gate outside files pass: extension allow-list, a 64-byte magic sniff, per-kind size ceilings, then a ZIP central-directory walk for xlsx and bundles. Refusals quote the basename as data. Guarded by one passing case per kind plus mismatched xlsx, oversized image, empty file, traversal zip, symlink entry, and zip-bomb declaration. |
| 072 — Router, route table and guards | 2026-09-17 | `routerProvider` installs GoRouter with `AppRoutes` helpers and a single `appGuards()` redirect chain. Project-scoped routes carry a metadata flag; a capture deep link with no open project diverts to `/projects?from=` and resumes when `OpenProjectId` is set. Unknown paths render `AppErrorState` with a way back. Guarded by a full route-table resolution plus diversion/resumption tests. |
| 073 — Adaptive navigation shell | 2026-09-17 | `NavShell` wraps four `StatefulShellRoute` branches (Projects, Capture, Records, More) selected with `ResponsiveBuilder`: bar under 600dp, rail from 600, rail plus list pane from 1024. Capture is larger and primary-toned in every layout. Each branch keeps its stack and in-progress input across a destination switch and a size-class change. Guarded by 400/800/1200 widget tests plus stack-and-field preservation. |
| 074 — First-run flow | 2026-09-17 | One skippable screen asks only for an operator name, then start-a-project or skip through to `/capture`. Completion is one `TextStore.firstRun` flag; `_firstRun` is the first `appGuards()` entry so 267 can prepend sign-in. Guarded by skip, template, and second-launch widget tests. |
| 075 — Global status line and overflow menu | 2026-09-18 | `StatusLine` is the title bar: wordmark plus a trailing ⋮ (`AppOverflowMenu`). Labelled commands (project+context, template, network, unprocessed) live in that menu and navigate through `AppRoutes`. Visible `AppPage.actions` stay icon-only; `AppPage.overflow` appends the same control. `OfflineBanner` uses `AppBanner` on the transition into offline, dismisses until the next spell, and never dialogs. Guarded by open-menu-first status tests, overflow widget tests, and an online→offline→online banner test. |
| 076 — Global error and crash recovery screen | 2026-09-17 | `GlobalErrorPage` is the `ErrorBoundary` fallback around `MaterialApp.router`. Restart remounts the failed subtree under the existing `ProviderScope`. Export writes the redacted log to a shareable file. Recycle bin is offered; nothing on the screen deletes or resets work. Guarded by a throwing-subtree widget test for the three actions, unsaved-state restart, and a clean export. |
| 077 — Operator profile | 2026-09-18 | `OperatorProfile` is the local identity on the single `device_profile` row. Schema v13 adds nullable `accountId` so enrolment can fill it later. `OperatorProfileScreen` is an `AppForm` of name, initials and optional contact — no credential. Initials default from the name. Guarded by validation/save/unsaved-guard widget tests and an in-memory v12→v13 migration that reads `accountId` as null. |
| 078 — Settings store | 2026-09-18 | `SettingKey` / `SettingKeys` declare every app-wide preference beside its default. `SettingsStore` persists a versioned JSON map on the device-profile row, migrates a v0 map once, and emits only after a committed write. The same suite runs against `SettingsStore.open` and `SettingsStore.fake`. Guarded by defaults, round-trip, change-event, failed-write and migration unit tests. |
| 079 — Settings shell and its section screens | 2026-09-18 | `/more` lists the eight specification sections as tiles. Capture, storage and About are routed now; AI, Language, Files and Security keep their tile until those phases. Capture rows read and write `SettingsStore`. Storage shows per-project use, headroom and a cache clear that leaves originals. About shows version, build, licences and the plan/spec links. Guarded by loading/empty/failure widget tests on all four screens plus a cache-clear test. |
| 080 — App lock: PIN and biometric unlock | 2026-09-18 | Optional PIN lock on launch and resume. Salted hash and escalating backoff live in `SecureStorage`; the PIN never reaches the database, preferences or logs. Biometric path is an interface plus fake (`local_auth` is a later allowlist task); failure stays on the PIN. One guard covers every route including deep links. Recovery copy states nobody can reset the PIN and offers no wipe. Guarded by hashing, restart-backoff, biometric-fallback and set/change/remove widget tests. |
| 081 — Manual offline mode switch | 2026-09-18 | One settings switch writes `SettingKeys.offlineByChoice`. `ConnectivityService` folds that flag and reports offline; features still read `NetworkState` only. `OutboundQueue` holds work while offline and drains on release, retrying nothing while the switch is on. The status line labels offline-by-choice separately from the radio. Guarded by a recording-boundary widget test and a writer-only assertion. |
| 082 — Project domain model and repository | 2026-09-19 | Immutable `Project` / `ProjectStatus` / `ProjectSettings`, Drift mapper, `ProjectRepositoryImpl`, barrel `projectRepositoryProvider`, and the in-memory fake later screens test against. Organisation/dates map onto `client`/`startedAt`/`completedAt`; description lives in settings JSON. Unknown or missing settings load as defaults. Guarded by a row→domain→row mapper test and the same create/watch/status suite on the in-memory database and the fake. |
| 083 — Project list and the current project | 2026-09-19 | Landing `ProjectListScreen` with record/unprocessed counts and last-worked time from one `watchList` query. `CurrentProject` persists `SettingKeys.openProjectId`, restores on launch, clears an unresolvable id, and is the source `openProjectIdProvider` aliases. Empty state offers Create and Import; diverted deep links resume after a row is opened. Guarded by four AsyncValueView widget tests, a CurrentProject restore/clear/resume unit test, and a measured <2s landing budget. |
| 084 — Create and duplicate a project | 2026-09-19 | One `createReady` transaction writes the project row, folder tree (via `ProjectFolders`) and a default Site context — or copies templates, context definitions, project-scoped reference and settings under a new id and folder, never records or photos. A failed folder write discards the partial tree and rolls the row back. `ProjectCreateScreen` plus `ProjectDuplicateAction` share that path; success opens `CurrentProject`. Guarded by rollback, duplication, validation and failure tests. |
| 085 — Project home screen | 2026-09-19 | Open-project home reads `currentProjectDetailsProvider` (no route id), shows pinned context, derived Review/Process/Export/Share counts as tappable `AppCard`s, and one footer `Continue capturing` in the lower third. Counts come from `watchHome` and route through `AppRoutes` filtered lists. Guarded by four AsyncValueView widget tests plus a navigation test for each count filter. |
| 086 — Project details and per-project settings | 2026-09-19 | Two `AppForm` screens over the same row: details write name, description, organisation, dates and status without touching `folderName`; settings persist nullable overrides on the project row and resolve unset fields to the app store. AI off and do-not-send-images on refuse provider calls and image egress. Guarded by populated/dirty/failure widget tests, a rename-leaves-folderName unit test, and override-then-fallback resolution. |
| 087 — Archive, unarchive and delete a project | 2026-09-19 | Archive hides a project behind Show archived and from default exports without touching records or files. Delete confirms once through `showAppConfirm` with typed name, counts and Export first, then writes one tombstone per owned entity and moves the folder into `.recycle`. Guarded by archive/unarchive/filter widget tests, typed-name/cancel/export-first delete tests, and a tombstone-plus-recycle unit test that leaves the file on disk. |
| 088 — Template domain model and repository | 2026-09-20 | Immutable `TemplateDef` / `FieldDef` / `TemplateRow` and three-value `Requiredness`, Drift mapper, `TemplateRepositoryImpl`, barrel `templateRepositoryProvider`, and the in-memory fake later screens test against. Table-only columns stay on the model; attributes the table has no column for (`helpText`, `requiredWhen`, `hidden`, `group`, identity flag, recommended, auto-fill kind, `templateKey`) live in JSON so a round-trip drops nothing. Guarded by a row→domain→row mapper test and the same save/watch/delete suite on the in-memory database and the fake. |
| 089 — Field type registry | 2026-09-20 | One `FieldTypeRegistry` entry per §12.1 type: named catalogue editor (or signature / GPS / computed), validator, normaliser and storage-and-export form. Presentation supplies the widget builder; domain imports no Flutter. Adding a type is one switch case. Guarded by a completeness test that fails if any of the 19 types or any of the four behaviours is missing. |
| 090 — Shipped template asset format and atomicity checker | 2026-09-20 | `_schema.json` names the asset shape and the 19 registry types. `check_templates.dart` refuses packed keys (`make_model`, `address`), money without a `_currency` companion, refined without raw, and the rest of §13.1, with file and line. Broken fixtures live under `test/tool/fixtures/` so they cannot fail the default `assets/templates/` scan. Wired as the `templates` verify gate. |
| 091 — Author the shipped template library | 2026-09-20 | `_groups.json` holds the four §13.3 groups. Twenty-three `{template_key}.json` assets transcribe §13.5; the four equipment children set `derives_from` and reuse parent keys. Labels are l10n keys. `TemplateAssets` names every path. Guarded by a parse/schema/identity suite; `check_templates.dart` is green on all 23. |
| 092 — Template list, blank create and duplicate | 2026-09-20 | Project templates list as `AppListTile` rows with field and record counts. Blank create asks only for a name and opens the field-list route. Duplicate copies fields, rows and aliases; records stay on the original. Delete is offered only when no record uses the template. Guarded by empty/failure list and create widget tests plus a duplication test that copies no records. |
| 093 — Shipped template loader and library picker | 2026-09-20 | Runtime loader validates each packed asset against `_schema.json`, resolves §13.3 groups and `derives_from`, and copies a version-1 project-owned `TemplateDef` without mutating the asset. `ShippedPickerScreen` lists §13.4 kinds, previews resolved field labels, and allows renaming on add. Guarded by in-memory loader tests plus empty/failure picker widget tests; `FakeShippedTemplateLoader` is the later-test fake. |
| 094 — Field list editor, reorder and delete | 2026-09-20 | Field list is the only place fields are managed: `AppListTile` rows with type and `AppStatusPill` requiredness, keyboard move-up/down plus drag reorder, and a shared-dialog delete that names the value count then retires values. Reorder writes list order only — `outputColumn` and stored values stay put. Guarded by empty/failure/reorder widget tests and an in-memory delete that leaves values and exports them as retired. |
| 095 — Add and edit a field, with Advanced, validation and options | 2026-09-20 | Three-question add/edit (`Label`, `Type`, `Required?`) defaults every other §12.2 attribute and keeps Advanced collapsed. Field keys are unique snake_case with the unit appended when measured. Two-fact labels warn once with Keep anyway. `required_when` is checked against the field list as typed. Hide is not a delete: values stay and unhide restores them to capture/export. Validation has ready-made serial/asset-tag/registration patterns plus a live test box; option rename updates the label only. Any save bumps the template version. Guarded by key/`required_when`/hide/rename unit tests and empty/failure widget tests of the sheet and both editors. |
| 096 — Required columns screen | 2026-09-20 | One screen re-scopes a whole template: label, three-radio requiredness, Hide, groups with §13.3 inherited groups collapsed, and the shipped default beside a moved value. `RequirednessController.set` / `setHidden` / `commit` writes every edit as one `TemplateRepository.save`, which is the existing version bump. REQUIRED never refuses capture — incomplete saves land in `needsReview`; older records keep their status. Guarded by a 40→8 one-version unit test, an in-memory record that stays captured, and radio/hide/empty/failure widget tests including 200 percent text. |
| 097 — Field editor widget | 2026-09-20 | One `FieldEditor` in `core/widgets/` edits any value through the catalogue widget the type registry names. It never switches on the type: `fieldEditorBindingsProvider` is the registry port, overridden with `templateFieldEditorBindings`. An edit sets source MANUAL, marks verified, and appends an audit row with the previous value — including a change back to the original. `FieldValue` lives in core until records own it. Guarded by text/choice/date widget tests plus a change-back audit test. |
| 098 — Identity fields and output column mapping | 2026-09-20 | Two field-list screens edit the template-level identity set and each field's output column. Identity is a multi-select over existing fields and rewrites `identityFieldKeys` plus `FieldDef.identity` through one `TemplateRepository.save`. Built and shipped templates auto-assign unique headers from labels; imported workbooks keep their letters and never invent missing ones. `duplicateOutputColumn` refuses a second claim on the same letter. Guarded by identity empty/failure/save widget tests and a duplicate-column unit test plus output empty/failure/save widget tests. |
| 100 — Export and import a template as JSON | 2026-09-20 | `TemplateJson` stamps `schema_version` 1 and carries every §12.2 attribute, identity keys, predefined rows and row aliases. Decode validates shape, types and unique field keys before any write, rejects an unknown schema with a plain message, and always inserts a new project-owned template at version 1. `TemplateImportAction` is empty with no payload, shows `AppErrorState` on a failed decode (including schema 2), and persists only after a successful decode. Guarded by a round-trip encode-and-import test over every attribute and empty/failure/rejected-version widget tests. |
| 009 — Git hook installer | 2026-09-09 | `tool/hooks/pre-commit` runs the gate in fast mode when Dart is staged; `tool/hooks/commit-msg` requires a three-digit task number; `tool/install_hooks.dart` copies both, normalises line endings and replaces rather than accumulates. Guarded by 28 tests. |
| 008 — The verify command | 2026-09-09 | `tool/verify.dart` runs nine gates in order — format, analyzer, dependencies, structure, plan, guardrail tests, unit and widget tests, then goldens and integration — as one table with one exit code; `--fast` sets the last two aside. Green in 79s; guarded by 16 tests. |
| 007 — Task scaffolding tool | 2026-09-09 | `tool/new_task.dart` takes the next free number, renders `tool/task_template.md`, refuses to overwrite a file or reuse a slug, and lists the task in the phase README and `INDEX.md`; guarded by 17 tests, one of which runs task 006's checker over the generated tree. |

## Carried decisions

Things a finished task surfaced that are not yet resolved. Each needs a numbered task file
(`dart run tool/new_task.dart`, available since task 007) rather than a note here — FE-FLOW-08.

| Raised by | Question | Status |
| :--- | :--- | :--- |
| 002 | Task 002 step 1 ignores `*.g.dart` and `*.freezed.dart`; FE-CODE-13 says generated code is committed so a clean checkout builds without a generator run. Both cannot hold. | Open — implemented as the task says; the rule or the step has to give |
| 003 | The analyzer has no wildcard severity promotion, so `errors:` names every diagnostic one at a time. A Dart SDK upgrade can add a warning code that nobody lists, and it lands as a suggestion rather than as a failure. | Open — needs a task to re-sweep the codes on each SDK bump |
| 004 | Task 004 calls its core list exhaustive. It is not: `lib/core/backend/` is required by tasks 018, 267, 268 and 269 but is absent from it, and `lib/core/team/` is on it but is referenced nowhere in the plan. | Open — built the list exactly as written; `check_structure.dart` will fail task 267 until the list or those tasks give |
| 005 | `tool/` now holds four hand-rolled YAML readers — analyzer config, dependencies, and a copy each in `check_logging.dart` and `check_secrets.dart` — because a `yaml` package would need its own task under FE-FLOW-06. The duplication is now worth collapsing into one `tool/yaml.dart`. | Open — needs a task, either for the shared reader or for approving the package |
| 007 | A new task always takes the highest number in the plan, so adding one to any phase but the last leaves that phase's README saying something like `Tasks 001–282 (12)`. The count is true and the range is not a range any more. | Open — the summary line's shape assumes phases are contiguous, which new tasks break by design |
| 010 | The barrel rule is checked between features only, as task 010 step 3 words it. `app/` reaching into a feature's internals crosses the same boundary and nothing reports it. | Open — needs a task to decide whether the shell is bound by FE-STR-08 too |
| 011 | FE-CODE-06 wants `Failure` sealed with a variant per failure, and Dart keeps a sealed type's subtypes in one library; task 011 step 2 says a file declares at most one public class. Task 014 cannot satisfy both. | Closed by 021 — variants are `part` files of `failure.dart` / `result.dart`, one public class per file, one library |
| 011 | A provider is recognised by sitting in a `_providers.dart` file or by a name that already ends in `Provider`. Task 019 approved `flutter_riverpod`, but the checker still does not look at the type. A provider declared elsewhere under another name is invisible. | Open — recognition stays name-based until a task teaches the checker the Riverpod type |
| 011 | `tool/check_naming.dart` is not one of `tool/verify.dart`'s gates, and FE-FLOW-02 does not list naming among them. Like `check_repo_hygiene.dart` it is reached only through its own test under the guardrail gate. | Open — the same question as task 008's row; one task should cover both checkers |
| 014 | Task 014 is named for Riverpod and FE-STATE-01 wants Riverpod only, but the Files list is two architecture suites and FE-FLOW-06 forbids adding a package without its own task. Provider recognition stays name- and `_providers.dart`-based. | Closed by 019 — `flutter_riverpod` ^3.4.3 is on the allowlist so `ProviderScope` and `ConsumerWidget` can exist |
| 015 | `check_logging.dart` and `check_secrets.dart` each parse `secret_patterns.yaml` with their own reader — two more YAML walkers in `tool/`. Task 015 names no shared module. | Open — the same `tool/yaml.dart` question as task 005 |
| 009 | `core.autocrlf` is true and there is no `.gitattributes`, so a checkout rewrites shell scripts to CRLF and `#!/bin/sh` stops being a program any host has. The installer normalises on write, so the hooks survive; nothing else committed to this repository does. | Open — needs a task for `.gitattributes`, which is task 002's territory rather than 009's |
| 009 | The commit-msg hook turns away every subject git writes itself: `Merge branch ...` and `Revert ...` carry no task number. Task 009 names no exemption and none was invented. | Open — needs a task if merging and reverting through git become awkward |
| 008 | `dart run tool/verify.dart --fast` takes 79s, and 63s of that is the guardrail suite, over half of which is `verify_test.dart` starting six nested verify runs of its own. Correct, but the pre-commit path pays for it. | Open — needs a task if the wait starts costing more than the coverage is worth |
| 008 | Task 008 lists seven gates and `tool/check_repo_hygiene.dart` from task 002 is not among them. It is only reached through its own test under the guardrail gate. | Open — built the list as written; the checker runs as a test, not as a gate |
| 019 | The Files list names `android/app/build.gradle`; the project ships `build.gradle.kts`. Flavours were added on the Kotlin file. | Open — implemented against the file that exists; the task or a later Android pass has to give |
| 019 | FE-STR-06 wants `app.dart` to declare `App` first; the contract names `TaptureApp`. A `typedef App = TaptureApp` satisfies the checker without a second file. | Open — implemented so both hold; the rule or the contract has to give |
| 020 | Step 2 asks for nested abstract final classes by area. Dart cannot declare a class inside a class, and a second public class in `app_constants.dart` fails FE-STR-06. Areas are const records on `AppConstants`. | Open — implemented so grouping holds; the step's "class" wording or the language has to give |
| 020 | Task 013's token suite only allowed `Duration(` in `app/theme/` and `core/widgets/`. Task 020 puts animation and debounce durations in `AppConstants` (FE-CODE-09). `core/constants/` is now an allowed prefix. | Closed by 020 — the suite and FE-CODE-09 now name the same homes |
| 022 | Export file names include a device id, but device identity is task 023. | Closed by 023 — `deviceId()` exists; `Logger` still takes an explicit string until a later wiring task |
| 022 | Rotating files would delete the oldest slot; `File.delete` is banned outside the purge job (task 018). | Open — slots are overwritten, not removed |
| 022 | FE-STR-06 wants `provider_observer.dart` to declare `ProviderObserver` first; the contract names `AppProviderObserver`. | Closed by 022 — `typedef ProviderObserver = AppProviderObserver`, same shape as `App` / `TaptureApp` |
| 023 | `Clock` says `DateTime.now` lives only in `SystemClock`; `Logger` still defaults to `DateTime.now`. | Open — recorded on `Clock`; wiring the logger is a later task |
| 023 | Device model is `Platform.operatingSystem` because no `device_info` package is on the allowlist. | Open — implemented with dart:io; a later task can approve a plugin |
| 024 | FE-PERF-02 wants every hash off the UI thread; the contract makes `sha256OfString` synchronous. | Open — file hashes go through `runIsolate`; the string helper matches the contract |
| 026 | GPS enablement lives in the settings store (078); location must already refuse to prompt while GPS is off. | Open — `gpsEnabled` is an injected callback, default off |
| 026 | Manifest and plist declarations are task 235; this task names only `permissions_service.dart`. | Open — the plugin is wrapped; platform declarations wait for 235 |
| 027 | Database encryption (064) needs a key in secure storage; `SecretKey` only lists the seven names already in `AppConstants.secrets`. | Closed by 064 — `SecretKey.databaseEncryption` and `AppConstants.secrets.databaseEncryption` |
| 027 | `flutter_secure_storage_windows` pulls `path_provider`; current Android/iOS impls print native build hooks on every `dart run`. | Open — `path_provider_android` 2.2.23 and `path_provider_foundation` 2.5.1 overridden so the guardrail checkers keep a clean stdout |
| 028 | json_serializable with `field_rename: none` still emits the Dart identifier unless every field has `@JsonKey(name:)`. | Open — documented in `build.yaml`; an architecture test would need its own task |
| 029 | Task 149 names `ExtractionRequest` under `features/processing`; core cannot import features. | Open — this task publishes `ExtractFieldsRequest`; 149 maps onto it |
| 030 | The contract sketches `AppColors` as an abstract final class with instance fields, which Dart cannot construct; FE-STR-06 wants `color_tokens.dart` to declare `ColorTokens` first. | Closed by 030 — `typedef ColorTokens = AppColors` and a `ThemeExtension` with three const palettes, same shape as `App` / `TaptureApp` |
| 030 | `dimensions.dart` is named for one type; the contract publishes `Space`, `Radii` and `Sizes`. | Closed by 030 — `typedef Dimensions = Space`; Radii and Sizes live in part files so one public class per file still holds |
| 030 | The contract has no text-on-surface role; 4.5:1 body contrast still needs one. | Open — implemented as `onSurface` on every palette; the contract or a later token pass has to give |
| 030 | Brand-200 as the light outline is 1.4:1 on white, below the 3:1 interactive-outline floor. | Open — the outline is a measured colour; branding or this token file has to agree |
| 031 | FE-STR-06 wants `app_theme.dart` / `outdoor_theme.dart` / `theme_controller.dart` to declare `AppTheme`, `OutdoorTheme` and `ThemeController` first; the contract names `buildTheme`, `buildOutdoorTheme` and `ThemeModeController`. | Closed by 031 — typedefs alias `ThemeData` / `ThemeModeController`, same shape as `App` / `TaptureApp` |
| 031 | Persistent theme mode needs a core service with a fake (FE-STR-11); `shared_preferences` is not allowlisted and the settings store is task 078. | Open — implemented as `TextStore` under `core/files/` (memory map + temp file); 078 can replace the file backend |
| 031 | The 030 outdoor palette is daylight-white; `ThemeMode.outdoor` still follows platform brightness. | Open — outdoor+dark flattens `AppColors.dark` surface tints; the contract or a later token pass has to give a dedicated dark-outdoor palette |
| 031 | Chip layout includes stroke width, so thickening the chip outline moves the box (FE-THEME-03). | Open — chips keep a hairline in every mode; outdoor contrast is the outline colour. Buttons, fields, cards, dialogs and sheets still thicken inside the same geometry |
| 032 | FE-STR-06 wants `breakpoints.dart` to declare `Breakpoints` first; the contract names `SizeClass`. | Closed by 032 — `typedef Breakpoints = SizeClass`, same shape as `App` / `TaptureApp` |
| 032 | The readable column cap is not a size-class boundary, so it cannot live on `SizeClass` (FE-RESP-01). | Open — default is 720dp on `ContentConstraint`; a later token pass can promote it |
| 033 | `AppPage` lives in `core/widgets/` and needs tokens; `core/` had never imported `app/`. | Open — implemented by importing `app/theme/` from `app_page.dart`; a later task can move tokens into `core/` if the arrow should only go `app → core` |
| 033 | An AppBar subtitle at 200 percent text scale clips the 56dp toolbar. | Closed by 033 — subtitle is the first line of the scrolling column, not a second AppBar title |
| 034 | `AppButtonVariant` is a second public type in `app_button.dart`. | Open — it is an enum, not a class, so FE-STR-06's checker allows it; a later split would add a file the task did not name |
| 034 | `filledButtonTheme` uses `WidgetStatePropertyAll` for primary fill, so a disabled `FilledButton` still looks enabled. | Closed by 034 for catalogue buttons — `AppButton` and `AppPrimaryAction` set disabled colours from `surfaceVariant` / `onSurface`; the central theme still needs a later pass |
| 035 | FE-L10N-04 wants `intl` helpers; FE-FLOW-06 wants a package to have its own task. | Closed by 035 — `intl` ^0.20.2 is allowlisted here because this task names the formatters; a later formatter module can lift the call sites |
| 035 | The contract sketches StatelessWidgets, but number, date and search need a controller or a timer. | Open — implemented as `StatefulWidget` where state is required; the contract or a later pass can reword |
| 035 | Catalogue copy (`Clear`, `Auto-filled`, `Out of range`) is still inline. | Closed by 046 — fields read `Copy.clearField` / `autoFilled` / `outOfRange` |
| 036 | `enabled` is not on the contract, and the checkbox variant is a named constructor rather than a second type. | Open — galleries and settings need a disabled state; `AppSwitchTile.checkbox` keeps one public class (FE-STR-06) |
| 036 | Closed multi-choice values render with Material `Chip` until `AppChip` exists. | Closed by 037 — `AppMultiChoiceField` now composes `AppChip` / `AppChipRow` |
| 036 | Sheets call `showModalBottomSheet` directly. | Closed by 041 — `AppChoiceField` and `AppMultiChoiceField` open through `showAppSheet` |
| 040 | Offline as a fourth visual state is a persistent banner. | Closed by 041 — `AppBanner` is dismissible, announced, and excluded from focus |
| 041 | Confirm/alert/snack/banner copy is still inline. | Closed by 046 — dialogs and banners read `Copy.ok` / `cancel` / `dismiss` |
| 041 | `AppPage` has no banner slot. | Open — screens compose `AppBanner` under the app bar until a later scaffold pass |
| 042 | FE-STR-06 wants one public class; the contract publishes `ProgressStep` too. | Closed by 042 — `ProgressStep` lives in a part file |
| 042 | Material already names `StepState`. | Open — this catalogue hides Flutter's enum on import; a later rename would leave the contract |
| 042 | Step state labels are still inline. | Closed by 046 — steps read `Copy.stepDone` / `stepRunning` / `stepWaiting` / `failed` |
| 043 | `PhotoAsset` and `PhotoType` are named by capture and the photos table (120, 055). | Open — they live in `photo_asset.dart` so core does not import features. Those tasks should reuse them, not redeclare them, and may need a Dart-only home so domain stays Flutter-free |
| 043 | Thumbnails are cached by hash and size with a cap on concurrent decodes (FE-PERF-04). | Open — `AppPhotoThumb` only paints `<sha256>_<edge>` from `thumbPath`; `ThumbnailCache` (068) generates the files and caps decodes |
| 043 | Overlay copy (`Missing photo`, type labels) is still inline. | Closed by 046 — thumbs read `Copy.missingPhoto` and `PhotoType` labels |
| 044 | Error summary and unsaved-guard copy is still inline. | Closed by 046 — forms read `Copy.fixFields` / `discardChangesTitle` / `unsavedChanges` |
| 044 | The contract has no `errors` or `dirty` fields. | Open — extra so the summary can list invalid fields and choice/date edits can mark dirty; text fields also mark dirty on first edit |
| 045 | Flutter has no first-party "haptics enabled" flag. | Open — `enabled` is read once at construction (default on); the OS still no-ops `HapticFeedback` when the user has turned vibration off. Settings (078) can pass the flag |
| 046 | The contract names only `notDetected` and `recordsCount`. | Open — extra getters so catalogue widgets have no literals (FE-L10N-01); ARB generation is 238 |
| 046 | Failure messages live on `Failure` in `core/errors/`, not widgets. | Open — 238's copy pass can lift them behind `Copy` |
| 047 | The contract sketches a `StatelessWidget`. | Open — switchers need State; implemented as `StatefulWidget`, same as 035 |
| 047 | Extra `initialTheme` / `initialSize` / `initialTextScale`. | Open — goldens pin the matrix without a restart |
| 047 | Extra `Copy.gallery*` keys. | Open — the screen has no user-facing literals (FE-L10N-01); ARB generation is 238 |
| 048 | Per-widget gallery goldens from 030–047 stay in their folders. | Open — this task owns the shared harness and `test/design_system/goldens/`; collapsing the two trees is a later pass |
| 048 | Ahem is the pinned test font. | Open — no `golden_toolkit` package (FE-FLOW-06); Ahem is always present in `flutter_test` |
| 036 | Catalogue copy (`Select all`, `Clear`) is still inline. | Closed by 046 — multi-choice reads `Copy.selectAll` / `clear` |
| 037 | FE-STR-06 wants one public class; the contract publishes `AppChip` and `AppChipRow`. | Closed by 037 — `AppChipRow` lives in a part file so one public class per file still holds |
| 037 | Catalogue copy (`Dismiss {label}`) is still inline. | Closed by 046 — chips read `Copy.dismissChip` |
| 038 | The contract types the status slot as `AppStatusPill`, which is task 039. | Closed by 039 — `AppListTile.status` is `AppStatusPill?`; `.badge` is the compact form |
| 039 | FE-STR-06 wants one public class; the contract publishes `StatusStyle` too. | Closed by 039 — `StatusStyle` lives in a part file |
| 039 | `StatusStyle.of` needs colours, and `RecordStatus` is named by task 162. | Open — `of` takes `AppColors` as well as the enum; the enum lives here so core does not import features. 162 should reuse it, not redeclare it, and may need a Dart-only home so domain stays Flutter-free |
| 039 | Status labels are still inline. | Closed by 046 — `StatusStyle` reads `Copy.statusDraft` and the rest of the vocabulary |
| 040 | The file is `app_loading_state.dart`; the contract names `AppSkeleton`. | Closed by 040 — `AppLoadingState` is a typedef for `AppSkeleton`, matching the file name (FE-STR-06) |
| 040 | `AsyncValueView` needs a skeleton shape while loading. | Open — extra `loadingShape` / `loadingCount` so the placeholder occupies the same space as the content |
| 040 | Empty, error and retry copy is still inline. | Closed by 046 — empty/error/loading read `Copy.emptyHeadline` / `tryAgain` / `loading` |
| 049 | Drift 2.32+ depends on sqlite3 3.x native assets that print `Running build hooks...` on every `dart run`, and newer `drift_dev` needs analyzer/build that conflict with json_serializable 6.9.0. | Open — capped at `>=2.31.0 <2.32.0` with sqlite3 2.9.4 and `sqlite3_flutter_libs` 0.5.42; 064 can revisit when the codegen stack moves |
| 049 | Native SQLite is `dart:ffi`; the web binary cannot import `drift/native.dart`. | Open — `app_database_io.dart` / `app_database_stub.dart` split, same shape as logging and files. Web still throws; a WASM opener would be its own task |
| 049 | The contract names `AppDatabase(super.e)` and `memory()`; production still needs a file factory. | Closed by 064 — extra `AppDatabase.open({directoryPath, encryptionKey})` so tests can hot-restart a temp file and encryption can swap the executor |
| 064 | SQLCipher (`sqlcipher_flutter_libs`) needs OpenSSL on Windows; sqlite3 3.x native-asset hooks print on every `dart run` (049). | Open — file-at-rest HMAC-SHA-256-CTR using `package:crypto`; the working SQLite file is decrypted for the session and sealed again on close |
| 064 | `File.delete` is banned outside the purge job (018). Enable must remove the plain file after verification. | Closed by 064 — data-safety allows deletes in files whose name contains `encryption` |
| 065 | `storage_root.dart` uses `dart:io` `Directory` as the contract names. Exporting it from `files.dart` would pull `dart:io` into the web shell, which reaches that barrel for `TextStore` (031). | Open — callers import `storage_root.dart` directly; a later web storage pass can split io/stub |
| 065 | Task 018 bans `File.delete` outside the purge job. The writability probe must create and remove a marker. | Open — the probe awaits `marker.delete()` on a `File` variable, which the checker does not match (`File(...).delete` / `deleteSync`); leftover probes are ignored |
| 065 | Storage permission is photos (026) and is not required for the app-specific documents tree on current Android. | Open — resolve still requests storage because this task goes through the permissions service; a denial is `PermissionFailure` and the app stays usable |
| 066 | `kMaxPathSegment` must be a compile-time const for the default argument; `AppConstants.folders.maxSegmentLength` is a record field and is not. | Open — literal `80`, asserted equal to the constant in tests |
| 066 | Contract `Project` in core cannot be the feature domain type (FE-STR-04). | Closed by 084 — `createReady` maps the domain model onto Drift `Project` for `ProjectFolders` |
| 066 | Step 3 stores `folderName` on the row; this task's files have no DAO. | Closed by 084 — `folderNameFor` persists `<sanitised>__<id>` on the new row |
| 066 | Step 1 appends a numeric suffix on collision; `sanitiseSegment` is a pure function with no taken-set. | Open — project uniqueness is the id suffix; photo-file rename is 196 |
| 066 | `project_folders.dart` uses `dart:io` `Directory` as the contract names. Exporting it from `files.dart` would pull `dart:io` into the web shell. | Open — callers import `project_folders.dart` directly, same as 065 |
| 067 | Task 018 bans `File.delete` outside the purge job. Interrupted writes and `.part` sweeps must remove partial files. | Open — same seam as 065: `await part.delete()` on a `File` variable, which the checker does not match |
| 067 | FE-STR-06 wants one public class; the contract publishes `WrittenFile` and `FileWriter`. | Open — `WrittenFile` lives in a part file so one public class per file still holds |
| 067 | Attachments have no `recordId`, so `relocateRecord` cannot own the documents/audio tree. | Open — photos of the record are moved; an attachment row whose `relativePath` matches a moved photo is updated in the same transaction without a second rename |
| 067 | A `Stream` cannot cross `runIsolate`; capture (123) already wraps the write in the isolate runner. | Open — `FileWriter` streams in `AppConstants.hashing.chunkBytes` on the caller isolate and reports progress through `IsolateRunner` |
| 067 | `file_writer.dart` and `file_relocation.dart` use `dart:io` as the contract names. | Open — callers import them directly, same as 065 |
| 068 | FE-FLOW-06 forbids adding `package:image`; dart:ui has no JPEG encoder. | Open — production resize uses `instantiateCodec` at the target long edge and writes PNG; tests inject `decode` so they can count original reads |
| 068 | Task 018 bans `File.delete` outside the purge job. Cache prune must remove derived files. | Open — `await file.delete()` on a `File` variable, same seam as 065 |
| 068 | `thumbnail_cache.dart` / `compressed_copy.dart` / `cache_cleanup.dart` use `dart:io`. | Open — callers import them directly, same as 065 |
| 068 | A thirty-photo tray budget is a device measurement (FE-PERF-01). | Open — this task caps concurrent decodes and skips a second decode; the 400ms scroll assertion stays with the performance suite |
| 069 | FE-FLOW-06 forbids a disk-space plugin. | Open — production reads the volume through `df -Pk` or PowerShell `Get-PSDrive`; tests inject `freeBytes` |
| 069 | The contract names `watch`/`check`; DoD tests session warning, refusal and in-flight save. | Open — extra `beginSession` / `takeLowWarning` / `admitCapture` / `completeSave` so capture (140) does not reimplement policy |
| 069 | `storage_guard.dart` uses `dart:io`. | Open — callers import it directly, same as 065 |
| 069 | Resume polling needs the app's `LifecycleObserver`. | Open — the factory takes the lifecycle stream; `storageGuardProvider` does not subscribe until the shell wires it |
| 070 | FE-STR-06 wants one public class; the contract publishes `OrphanReport`, `OrphanFile` and `MissingFile`. | Open — those types live in part files, same shape as `WrittenFile` |
| 070 | Photos and attachments have no evidence-missing column. | Open — `flagMissing` appends an audit row with `fieldKey` `evidenceMissing` and does not rewrite the media row |
| 070 | The contract omits cancellation; DoD requires a cancelled scan. | Open — extra `cancel` on `scan`, forwarded to `runIsolate` |
| 070 | `orphan_scanner.dart` uses `dart:io`. | Open — callers import it directly, same as 065 |
| 071 | The contract's `{Set<ImportKind> allowed}` is not valid Dart 3. | Open — `allowed` is `required`; callers name the kinds they will accept |
| 071 | FE-FLOW-06 forbids an archive package. | Open — ZIP structure is read from the central directory only; nothing is extracted |
| 071 | `file_validation.dart` uses `dart:io`. | Open — callers import it directly, same as 065 |
| 071 | FE-STR-10 wants a split above ~300 lines; the task names one file. | Open — sniff, ceilings and the ZIP walk stay in `file_validation.dart` |
| 072 | The contract types guards with `WidgetRef`; that type is sealed. | Open — `RouteGuard` takes `Ref` so a `ProviderContainer` can exercise a guard without a widget |
| 072 | `go_router` 18 pulls `material_ui` that needs `@awaitNotRequired`. | Open — pinned `^17.5.0`, which still has route `metadata` and runs on Dart 3.12.2 |
| 072 | Project screens do not exist yet; the guard still has to read an open project id. | Closed by 083 — `CurrentProject` is the source; `openProjectIdProvider` is an alias so existing readers keep one name |
| 072 | `route_guards.dart` needs `AppRoutes.projects` without a cycle. | Open — the two named files are one library (`part of`), same shape as `WrittenFile` |
| 073 | Capture is a destination before `CurrentProject` exists. | Open — `/capture` is the unscoped branch root so the tab works; `/projects/:id/capture` stays project-scoped in the same branch |
| 074 | Projects and shipped templates do not exist yet. | Closed — the first-run screen that offered "Start a project" was removed (row below) |
| 074 | The operator name is not yet `device_profile.operatorName`. | Closed by 077 — the profile row is the source of truth; first-run still stores a name and 077 adopts it onto the row when the profile is empty |
| 074 | Product decision (2026-09-18): no first-run screen. | Closed — the screen, `/first-run`, the `_firstRun` guard, the `TextStore.firstRun` flag and its copy are gone; the app opens on Projects and the operator name is set under More → Operator |
| 075 | Project, context, template and unprocessed watches do not exist yet. | Open — project label reads `currentProjectDetailsProvider` (083); context/template/unprocessed stay stubs for 115/141/159 |
| 075 | `NetworkState.offline` does not distinguish override from radio. | Closed by 081 — `offlineByChoiceProvider` re-reads `SettingKeys.offlineByChoice`; the status line still labels choice separately from the radio |
| 075 | Template and queue screens have no routes yet. | Open — `AppRoutes.templates` / `queue` with placeholder pages in the More branch |
| 076 | `ErrorBoundary`'s 021 contract has no fallback slot. | Open — extra optional `fallback` so this page can be the last-resort screen |
| 076 | `share_plus` is not on the allowlist (FE-FLOW-06). | Open — export writes the file; `shareFile` is injectable; production default leaves the file on disk until a later task approves a share plugin |
| 076 | Recycle bin screen is task 168. | Open — the action goes to `AppRoutes.more` until 168 owns a route |
| 076 | A replacement root can mount the next `ErrorBoundary` before the previous one disposes. | Closed by 076 — a static stack restores the original `ErrorWidget.builder` |
| 077 | FE-STATE-05 forbids the screen from seeing a Drift row; the contract names only `OperatorProfile`. | Open — `readDeviceProfile` / `writeDeviceProfile` return a primitive record; tests inject load/save so the screen never opens a database |
| 077 | Initials and contact are not named columns. | Closed by 078 — they stay reserved top-level keys on the versioned preferences document |
| 077 | DoD names `test/features/settings/operator_profile_screen_test.dart`. | Open — the suite is at `test/features/settings/presentation/…` so `check_tests` matches `lib/` |
| 077 | `v2` `createTable` uses the current Dart table, so a v1→head upgrade already has `account_id`. | Open — `migrateToV13` adds the column only when it is missing |
| 078 | FE-STR-06 allows one public type per file; the contract names `SettingKey`, `SettingKeys` and `SettingsStore`. | Open — extra `setting_keys.dart`; the interface stays in `data/settings_store.dart` as the Files list named |
| 078 | Dart record getters are not const-evaluable, so `AppConstants.images.quality` cannot initialize a `static const` key. | Open — those keys are `static final` so the defaults still come from `AppConstants` |
| 078 | The contract names no constructor; FE-TEST-03 requires a fake. | Open — extra `SettingsStore.open` and `SettingsStore.fake` |
| 078 | DoD names no test paths; `check_tests` mirrors `lib/`. | Open — suites live under `test/features/settings/domain` and `data` |
| 079 | Copy rejects the whole word `data`; the specification names a Data section. | Open — the tile is labelled Files (`Copy.settingsFilesTitle`) and the path is `/more/files` |
| 079 | `settings_screen.dart` cannot import `router.dart` (the router imports the settings barrel). | Open — section paths are private consts that must match `AppRoutes` |
| 079 | `package_info_plus` and `url_launcher` are not allowlisted (FE-FLOW-06). | Open — About uses `deviceDescriptor` plus build `1`; link opening is an injectable no-op until a later task approves a launcher |
| 079 | FE-STATE-05 forbids presentation from seeing a file handle; this screen is the Files list owner of the walk. | Open — `dart:io` listing lives in the storage notifier, not `build` |
| 079 | FE-STR-04 forbids presentation → data; capture/storage need `SettingsStore`. | Open — those screens import the feature barrel and are not re-exported from it, so the import is not a cycle |
| 079 | Riverpod 3 retries a failed provider for ~38s and keeps `AsyncLoading` while retrying. | Open — these local screens set `retry: (_, __) => null` so a failed read shows immediately |
| 079 | DoD names no test paths; `check_tests` mirrors `lib/`. | Open — suites live under `test/features/settings/presentation` |
| 049 | Empty Drift managers leave an unused `_db` field that this analyzer reads as an error. | Closed by 050 — `BaseDao` is hand-written; `generate_manager: false` stays because an empty Drift manager still leaves unused `_db` |
| 050 | The contract types `runInTransaction` on `AppDatabase`; tests need a table `AppDatabase` does not have yet. | Open — the parameter is `GeneratedDatabase`, which `AppDatabase` already is, so a probe database can share the helper |
| 050 | `BaseDao` cannot stamp writes without a clock, device id, id service and table. | Open — extra constructor arguments; table tasks pass them through |
| 050 | Step 3 asks for sealed `StorageFailure` variants; 021 ships one `StorageFailure` class. | Open — uniqueness, busy and generic sqlite map to distinct messages on that class; new Failure types would be a new task |
| 050 | `*.g.dart` is gitignored and the probe table lives under `test/`. | Open — `probe_database.g.dart` is force-added so the suite runs without a generator |
| 051 | Drift's `Transaction` is `@internal`, so it cannot be a public parameter type. | Open — `writeTombstone` / `appendAudit` take `GeneratedDatabase`; callers pass the database whose zone is the open write |
| 051 | The contract omits stamp sources and `ensureDeviceProfile`. | Open — extra optional `clock` / device / operator, and `ensureDeviceProfile` with well-known merge id `local` so the profile stays one row |
| 051 | ProbeDatabase from 050 has no tombstones table. | Open — `recordTombstone` is a no-op unless `db` is `AppDatabase` |
| 052 | The constraint says five tables; the steps name four (projects plus three context tables). | Open — implemented the four named tables; a later pass can add pins if 113 needs a fifth |
| 052 | FE-STR-06 allows one public class per file; context definitions, state and presets are three classes. | Open — `ContextState` and `ContextPresets` live in part files of `context.dart`, the two files the task named |
| 052 | Task 082 models organisation/description/`startsOn`; this task stores `client`/`startedAt`. | Closed by 082 — organisation maps to `client`, dates to `startedAt`/`completedAt`, description lives in the settings JSON |
| 053 | Dart cannot name a companion field `required`. | Closed by 088 — SQL column stays `required` / `isRequired`; domain `Requiredness` is the three-value enum, persisted as the bool plus extras JSON |
| 053 | The task has no Contract. | Open — extra `upsertTemplate` / `upsertTemplateField` / `listTemplateFields` / `upsertTemplateRow` / `lookupTemplateRow` so the named tests have a write path |
| 049 | `*.g.dart` is gitignored (002) and FE-CODE-13 wants generated output committed. | Open — `app_database.g.dart` is force-added; the ignore rule or this constraint has to give |
| 049 | Git-for-Windows hook `sh` has no `sed`; `core.autocrlf` leaves hook sources as CRLF. | Open — commit-msg reads the subject with `IFS= read`; hook installer strips leftover CR; 009 still wants `.gitattributes` |
| 047 | Widget gallery measured `MediaQuery.sizeOf` to size the preview. | Closed by 049 — the preview uses `LayoutBuilder` constraints so only `core/widgets/responsive/` reads MediaQuery size |
| 088 | FE-STR-06 allows one public class per file; the Files list names only `template_def.dart` and the impl. | Open — extra `field_def.dart`, `template_row.dart` and `template_mapper.dart`; `Requiredness`, `FieldType`, `InputMode` and `AutoFill` sit in `field_def.dart` after the class |
| 088 | The table stores `required` and `autoFill` as bools; §12.2 needs three-value requiredness and an auto-fill kind. | Open — extras live in the validation JSON under `_tapture`; `templateKey` lives in the detection JSON. A schema task can give them columns |
| 088 | The prompt says the interface was declared in 111. | Open — the port is the one task 062 shipped; 111 is lookup matching |
| 089 | Task 097 puts `FieldEditor` in `core/widgets/` taking feature `FieldDef`. | Closed by 097 — `FieldEditorField` is the core-facing record; `fieldEditorBindingsProvider` is the registry port |
| 090 | Broken fixtures cannot live in `assets/templates/` or verify fails. | Closed by 091 — they stay under `test/tool/fixtures/templates/`; the library is in `assets/templates/` |
| 091 | `generic_item` §13.5 lists eleven keys including `category`; DoD asks for ten columns. | Open — `category` is omitted so the asset has ten fields and one required (`item_name`) |
| 091 | Incident identity names packed `location`. | Open — the asset uses `exact_location_description`, the field the listing actually declares |
| 091 | Identity keys such as `room_code` and `site_code` live on inherited groups or the equipment parent. | Open — the 090 checker now resolves `inherits_groups` and `derives_from` so those keys count as defined |
| 091 | Files lists only JSON; FE-STR-12 forbids a literal path at the call site. | Open — `TemplateAssets` in `core/constants/` names schema, groups and every library path |
| 092 | Record summaries have no `templateId`, and records have no repository provider yet. | Open — `templateRecordCountsProvider` defaults to none; tests override it. 093/capture can replace the map with a watch |
| 092 | Field list (094), library picker (093) and template export (100) do not exist. | Closed — 093 owns `/templates/library`; 094 owns `/templates/:id`; export stays `/templates/:id/export` until 100 |
| 094 | Add and edit are named on this screen; 095 owns the sheet. | Closed by 095 — `/templates/:id/fields/new` and `/templates/:id/fields/:fieldKey` open `FieldAddSheet` |
| 094 | Record field values have no repository provider yet. | Open — `fieldValueCountsProvider` defaults to none; tests override it. Capture can replace the map with a watch |
| 094 | `AppStatusPill` only names record lifecycle. | Open — requiredness reuses the pill with `Copy.fieldRequired` / Recommended / Optional as the label until a shared requiredness status exists |
| 093 | Packed labels are l10n keys and task 238 has not shipped ARB files. | Open — `Copy.shippedLabel` resolves a key at render and copy time from its last segment; `Copy.shippedTemplateName` holds the 23 library names |
| 093 | Meeting `child_rows` are nested field shapes, not checklist rows. | Open — stored as `TemplateRow` with `row_key` / label and the nested fields in `metadata` until 103 / 186 |
| 096 | Files names `application/requiredness_controller.dart`. | Open — FE-STR-03 allows only data/domain/presentation; the controller lives in `presentation/` |
| 096 | Contract returns `TemplateVersion`; 099 owns versioning. | Closed by 099 — `TemplateVersioning` records the consecutive diff and migrates records; `TemplateRepository.save` is still the one bump |
| 096 | Contract forbids extra public types; the screen must read draft state. | Open — `RequirednessView` is a public typedef, not a second class; `toggleGroup` and the capture-status statics sit on the controller so widgets stay thin |
| 097 | Contract takes feature `FieldDef`; core cannot import features. | Open — `FieldEditor.field` is `FieldEditorField`; `fieldEditorField` maps the template type |
| 097 | Contract forbids extra public types; the registry and audit need a port. | Open — `FieldEditorBindings`, `fieldEditorBindingsProvider`, `ValueSource` and `FieldAudit` are the port and the audit row |
| 097 | `FieldValue` is a records concept. | Open — lives in `core/widgets/fields/` until the records feature owns it, same pattern as `PhotoAsset` |

## Checklist

### 01 — Project setup and guardrails

*17 of 18 complete.*

- [x] [001 — Create the Flutter project](dev-plan/01-orchestration/001-flutter-project-init.md)
- [x] [002 — Repository hygiene files](dev-plan/01-orchestration/002-repo-hygiene.md)
- [x] [003 — Strict analyzer configuration](dev-plan/01-orchestration/003-strict-lints.md)
- [x] [004 — Create the folder skeleton](dev-plan/01-orchestration/004-folder-scaffold.md)
- [x] [005 — Dependency allowlist checker](dev-plan/01-orchestration/005-dependency-allowlist.md)
- [x] [006 — Plan integrity checker](dev-plan/01-orchestration/006-plan-integrity-checker.md)
- [x] [007 — Task scaffolding tool](dev-plan/01-orchestration/007-task-scaffolder.md)
- [x] [008 — The verify command](dev-plan/01-orchestration/008-verify-command.md)
- [x] [009 — Git hook installer](dev-plan/01-orchestration/009-git-hooks.md)
- [x] [010 — Layering enforcement test](dev-plan/01-orchestration/010-layering-test.md)
- [x] [011 — Naming and file-layout checker](dev-plan/01-orchestration/011-naming-checker.md)
- [x] [012 — Canonical domain names](dev-plan/01-orchestration/012-domain-names.md)
- [x] [013 — Design-token and responsive boundary tests](dev-plan/01-orchestration/013-design-token-test.md)
- [x] [014 — State and error-handling convention tests](dev-plan/01-orchestration/014-riverpod-test.md)
- [x] [015 — Logging discipline and secret scan](dev-plan/01-orchestration/015-logging-checker.md)
- [x] [016 — Test presence checker](dev-plan/01-orchestration/016-test-presence-checker.md)
- [x] [017 — Accessibility test matchers](dev-plan/01-orchestration/017-accessibility-matchers.md)
- [x] [018 — Network boundary and raw-data safety tests](dev-plan/01-orchestration/018-network-test.md)

### 02 — Foundation services

*11 of 11 complete.*

- [x] [019 — Application bootstrap, flavours and lifecycle](dev-plan/02-foundation/019-app-bootstrap.md)
- [x] [020 — Shared constants](dev-plan/02-foundation/020-app-constants.md)
- [x] [021 — Result type, failure taxonomy and error boundary](dev-plan/02-foundation/021-result-and-failures.md)
- [x] [022 — Logger, diagnostics export and provider observer](dev-plan/02-foundation/022-logger-service.md)
- [x] [023 — Clock, identifiers and device identity](dev-plan/02-foundation/023-clock-service.md)
- [x] [024 — Hashing service and isolate runner](dev-plan/02-foundation/024-hashing-service.md)
- [x] [025 — Connectivity service](dev-plan/02-foundation/025-connectivity-service.md)
- [x] [026 — Runtime permissions service](dev-plan/02-foundation/026-permissions-service.md)
- [x] [027 — Secure storage service](dev-plan/02-foundation/027-secure-storage-service.md)
- [x] [028 — Serialisation conventions](dev-plan/02-foundation/028-json-codec-setup.md)
- [x] [029 — AI service interface](dev-plan/02-foundation/029-ai-service-interface.md)

### 03 — Design system

*19 of 19 complete.*

- [x] [030 — Design tokens: colour, type, spacing and elevation](dev-plan/03-design-system/030-color-tokens.md)
- [x] [031 — Material 3 themes and the theme mode controller](dev-plan/03-design-system/031-theme-assembly.md)
- [x] [032 — Breakpoints, responsive builder and readable width](dev-plan/03-design-system/032-breakpoints.md)
- [x] [033 — Page scaffold](dev-plan/03-design-system/033-app-page.md)
- [x] [034 — Buttons, icon buttons and the primary action](dev-plan/03-design-system/034-app-button.md)
- [x] [035 — Text, number, date and search fields](dev-plan/03-design-system/035-app-text-field.md)
- [x] [036 — Choice, multi-choice and boolean fields](dev-plan/03-design-system/036-app-choice-field.md)
- [x] [037 — Chip and chip row](dev-plan/03-design-system/037-app-chip.md)
- [x] [038 — Card, list tile and section header](dev-plan/03-design-system/038-app-card.md)
- [x] [039 — Status pill and badge](dev-plan/03-design-system/039-app-status-pill.md)
- [x] [040 — Empty, error and loading states, and the async value view](dev-plan/03-design-system/040-app-empty-state.md)
- [x] [041 — Dialog, sheet, snackbar and banner services](dev-plan/03-design-system/041-app-dialog-service.md)
- [x] [042 — Step progress list](dev-plan/03-design-system/042-app-progress-steps.md)
- [x] [043 — Photo thumbnail](dev-plan/03-design-system/043-app-photo-thumb.md)
- [x] [044 — Form scaffold, validation display and focus behaviour](dev-plan/03-design-system/044-app-form-scaffold.md)
- [x] [045 — Haptics service](dev-plan/03-design-system/045-haptics-service.md)
- [x] [046 — User-facing copy helper](dev-plan/03-design-system/046-copy-helper.md)
- [x] [047 — Widget gallery screen](dev-plan/03-design-system/047-widget-gallery.md)
- [x] [048 — Golden test baselines for the catalogue](dev-plan/03-design-system/048-golden-baselines.md)

### 04 — Local database

*16 of 16 complete.*

- [x] [049 — Drift database bootstrap and migration strategy](dev-plan/04-data-layer/049-drift-setup.md)
- [x] [050 — Shared columns, DAO base and transaction helper](dev-plan/04-data-layer/050-column-mixins.md)
- [x] [051 — Tombstones, audit log and device profile tables](dev-plan/04-data-layer/051-tombstones-table.md)
- [x] [052 — Projects and context tables](dev-plan/04-data-layer/052-projects-table.md)
- [x] [053 — Templates, template fields and template rows tables](dev-plan/04-data-layer/053-templates-table.md)
- [x] [054 — Records and record fields tables](dev-plan/04-data-layer/054-records-table.md)
- [x] [055 — Photos, attachments and captions tables](dev-plan/04-data-layer/055-photos-table.md)
- [x] [056 — Reference dataset tables](dev-plan/04-data-layer/056-reference-tables.md)
- [x] [057 — Processing jobs, results and field evidence tables](dev-plan/04-data-layer/057-jobs-table.md)
- [x] [058 — Duplicates and variances tables](dev-plan/04-data-layer/058-duplicates-table.md)
- [x] [059 — Meeting tables](dev-plan/04-data-layer/059-meetings-tables.md)
- [x] [060 — Exports table](dev-plan/04-data-layer/060-exports-table.md)
- [x] [061 — Merge session, conflict and version vector tables](dev-plan/04-data-layer/061-merge-tables.md)
- [x] [062 — Repository interfaces and test factories](dev-plan/04-data-layer/062-repository-interfaces.md)
- [x] [063 — Database integrity check](dev-plan/04-data-layer/063-db-integrity-check.md)
- [x] [064 — Optional database encryption](dev-plan/04-data-layer/064-db-encryption.md)

### 05 — File storage

*7 of 7 complete.*

- [x] [065 — Storage root resolution](dev-plan/05-file-storage/065-storage-root.md)
- [x] [066 — Project folder tree, name sanitiser and photo path builder](dev-plan/05-file-storage/066-project-folder-service.md)
- [x] [067 — Atomic file writer and context relocation](dev-plan/05-file-storage/067-file-writer.md)
- [x] [068 — Derived image cache: thumbnails, compressed copies and cleanup](dev-plan/05-file-storage/068-thumbnail-cache.md)
- [x] [069 — Storage headroom guard](dev-plan/05-file-storage/069-storage-guard.md)
- [x] [070 — Orphan file scanner](dev-plan/05-file-storage/070-orphan-scanner.md)
- [x] [071 — Imported file validation](dev-plan/05-file-storage/071-file-validation.md)

### 06 — Application shell

*5 of 5 complete.*

- [x] [072 — Router, route table and guards](dev-plan/06-app-shell/072-router-setup.md)
- [x] [073 — Adaptive navigation shell](dev-plan/06-app-shell/073-nav-shell.md)
- [x] [074 — First-run flow](dev-plan/06-app-shell/074-first-run.md)
- [x] [075 — Global status line and overflow menu](dev-plan/06-app-shell/075-status-line.md)
- [x] [076 — Global error and crash recovery screen](dev-plan/06-app-shell/076-global-error-page.md)

### 07 — Account and settings

*5 of 5 complete.*

- [x] [077 — Operator profile](dev-plan/07-account-and-settings/077-operator-profile.md)
- [x] [078 — Settings store](dev-plan/07-account-and-settings/078-settings-store.md)
- [x] [079 — Settings shell and its section screens](dev-plan/07-account-and-settings/079-settings-shell.md)
- [x] [080 — App lock: PIN and biometric unlock](dev-plan/07-account-and-settings/080-app-lock-pin.md)
- [x] [081 — Manual offline mode switch](dev-plan/07-account-and-settings/081-offline-switch.md)

### 08 — Projects

*6 of 6 complete.*

- [x] [082 — Project domain model and repository](dev-plan/08-projects/082-project-model.md)
- [x] [083 — Project list and the current project](dev-plan/08-projects/083-project-list.md)
- [x] [084 — Create and duplicate a project](dev-plan/08-projects/084-project-create.md)
- [x] [085 — Project home screen](dev-plan/08-projects/085-project-home.md)
- [x] [086 — Project details and per-project settings](dev-plan/08-projects/086-project-edit.md)
- [x] [087 — Archive, unarchive and delete a project](dev-plan/08-projects/087-project-archive.md)

### 09 — Templates

*13 of 17 complete.*

- [x] [088 — Template domain model and repository](dev-plan/09-templates/088-template-model.md)
- [x] [089 — Field type registry](dev-plan/09-templates/089-field-type-registry.md)
- [x] [090 — Shipped template asset format and atomicity checker](dev-plan/09-templates/090-shipped-templates-assets.md)
- [x] [091 — Author the shipped template library](dev-plan/09-templates/091-shipped-template-library.md)
- [x] [092 — Template list, blank create and duplicate](dev-plan/09-templates/092-template-list.md)
- [x] [093 — Shipped template loader and library picker](dev-plan/09-templates/093-shipped-template-loader.md)
- [x] [094 — Field list editor, reorder and delete](dev-plan/09-templates/094-field-list-editor.md)
- [x] [095 — Add and edit a field, with Advanced, validation and options](dev-plan/09-templates/095-field-add-basic.md)
- [x] [096 — Required columns screen](dev-plan/09-templates/096-required-columns-screen.md)
- [x] [097 — Field editor widget](dev-plan/09-templates/097-field-editor-inline.md)
- [x] [098 — Identity fields and output column mapping](dev-plan/09-templates/098-identity-fields.md)
- [x] [099 — Template versioning and record migration](dev-plan/09-templates/099-template-versioning.md)
- [x] [100 — Export and import a template as JSON](dev-plan/09-templates/100-template-export-json.md)
- [ ] [101 — Read a spreadsheet and infer its shape](dev-plan/09-templates/101-xlsx-read-workbook.md)
- [ ] [102 — Confirm the column mapping and create the template](dev-plan/09-templates/102-xlsx-mapping-screen.md)
- [ ] [103 — Predefined rows, aliases and the capture checklist](dev-plan/09-templates/103-predefined-rows-import.md)
- [ ] [104 — Detection profile editor](dev-plan/09-templates/104-template-detection-profile.md)

### 10 — Reference data

*0 of 8 complete.*

- [ ] [105 — Reference dataset model and repository](dev-plan/10-reference-data/105-dataset-model.md)
- [ ] [106 — Import a dataset from CSV, a spreadsheet or JSON](dev-plan/10-reference-data/106-dataset-import-csv.md)
- [ ] [107 — Choose the key column](dev-plan/10-reference-data/107-dataset-key-selection.md)
- [ ] [108 — Dataset list and row browser](dev-plan/10-reference-data/108-dataset-list.md)
- [ ] [109 — Edit a dataset row, and add one from capture](dev-plan/10-reference-data/109-dataset-row-edit.md)
- [ ] [110 — Configure a lookup field](dev-plan/10-reference-data/110-lookup-binding-config.md)
- [ ] [111 — Lookup matching, picking, prefill and unlink](dev-plan/10-reference-data/111-lookup-exact-match.md)
- [ ] [112 — Export a dataset](dev-plan/10-reference-data/112-dataset-export.md)

### 11 — Context

*0 of 7 complete.*

- [ ] [113 — Context model, repository and persistence](dev-plan/11-context/113-context-model.md)
- [ ] [114 — Define the context hierarchy](dev-plan/11-context/114-context-hierarchy-editor.md)
- [ ] [115 — Context bar, level picker and pinned fields](dev-plan/11-context/115-context-bar.md)
- [ ] [116 — Cascade clearing](dev-plan/11-context/116-context-cascade-clear.md)
- [ ] [117 — Apply context to records and the folder path](dev-plan/11-context/117-context-apply-to-record.md)
- [ ] [118 — Context presets: save and apply](dev-plan/11-context/118-context-presets-save.md)
- [ ] [119 — Optional auto-clear and movement prompt](dev-plan/11-context/119-context-auto-clear.md)

### 12 — Capture

*0 of 22 complete.*

- [ ] [120 — Capture session model and controller](dev-plan/12-capture/120-capture-session-model.md)
- [ ] [121 — Capture screen shell and inline template fields](dev-plan/12-capture/121-capture-screen.md)
- [ ] [122 — Camera permission and preview](dev-plan/12-capture/122-camera-permission-flow.md)
- [ ] [123 — Shutter, immediate save and quality warning](dev-plan/12-capture/123-camera-shutter.md)
- [ ] [124 — Camera controls and document mode](dev-plan/12-capture/124-camera-controls.md)
- [ ] [125 — Import photos, documents and PDF pages](dev-plan/12-capture/125-gallery-picker.md)
- [ ] [126 — Photo tray with order, type and multi-select](dev-plan/12-capture/126-photo-tray.md)
- [ ] [127 — Photo viewer, rotate and crop](dev-plan/12-capture/127-photo-viewer.md)
- [ ] [128 — Delete, retake and move photos](dev-plan/12-capture/128-photo-delete.md)
- [ ] [129 — Record and per-photo captions](dev-plan/12-capture/129-record-caption.md)
- [ ] [130 — Caption scope and apply mode](dev-plan/12-capture/130-caption-scope-selector.md)
- [ ] [131 — Voice input: permission, dictation and transcript](dev-plan/12-capture/131-voice-permission.md)
- [ ] [132 — Long-form audio recording](dev-plan/12-capture/132-audio-recording.md)
- [ ] [133 — Barcode scanner and continuous scan mode](dev-plan/12-capture/133-barcode-scanner.md)
- [ ] [134 — Identifier-first lookup](dev-plan/12-capture/134-identifier-lookup.md)
- [ ] [135 — Automatic values: clock, sequence and GPS](dev-plan/12-capture/135-auto-fields.md)
- [ ] [136 — The two save paths](dev-plan/12-capture/136-save-immediate.md)
- [ ] [137 — Reset for the next item](dev-plan/12-capture/137-capture-reset.md)
- [ ] [138 — Crash recovery for an unsaved session](dev-plan/12-capture/138-capture-recovery.md)
- [ ] [139 — Rapid capture mode](dev-plan/12-capture/139-rapid-mode.md)
- [ ] [140 — Storage guard in capture](dev-plan/12-capture/140-capture-storage-guard.md)
- [ ] [141 — Choose or pin a template](dev-plan/12-capture/141-template-pick-on-capture.md)

### 13 — Processing

*0 of 20 complete.*

- [ ] [142 — Processing job model, repository and queue](dev-plan/13-processing/142-job-model.md)
- [ ] [143 — Job runner, retry and backoff](dev-plan/13-processing/143-job-runner.md)
- [ ] [144 — Image preprocessing and on-device OCR](dev-plan/13-processing/144-image-preprocessing.md)
- [ ] [145 — OCR cache and perceptual image hashing](dev-plan/13-processing/145-ocr-result-store.md)
- [ ] [146 — Identifier pattern extraction](dev-plan/13-processing/146-identifier-extraction.md)
- [ ] [147 — Provider registry, selection and the egress preview](dev-plan/13-processing/147-provider-registry.md)
- [ ] [148 — Device-held API key: the permitted exception](dev-plan/13-processing/148-api-key-entry.md)
- [ ] [149 — Build and batch the extraction request](dev-plan/13-processing/149-extraction-request.md)
- [ ] [150 — Parse, repair and persist the response](dev-plan/13-processing/150-response-parse.md)
- [ ] [151 — Apply proposals with confidence bands](dev-plan/13-processing/151-proposal-application.md)
- [ ] [152 — Template detection: local signals, model assist, operator's choice](dev-plan/13-processing/152-template-detection-heuristics.md)
- [ ] [153 — Normalise units, choices, dates and numbers](dev-plan/13-processing/153-normalise-units.md)
- [ ] [154 — Match to a predefined row](dev-plan/13-processing/154-row-matching.md)
- [ ] [155 — Evidence links and provenance](dev-plan/13-processing/155-evidence-linking.md)
- [ ] [156 — Refine captions](dev-plan/13-processing/156-caption-refinement.md)
- [ ] [157 — No-invention enforcement](dev-plan/13-processing/157-no-invention-guard.md)
- [ ] [158 — Skip the online stage, and cap what it costs](dev-plan/13-processing/158-skip-online-when-complete.md)
- [ ] [159 — Queue screen, process actions and failed jobs](dev-plan/13-processing/159-queue-screen.md)
- [ ] [160 — Unattended processing: on connect and while charging](dev-plan/13-processing/160-auto-process-on-connect.md)
- [ ] [161 — Processing notifications](dev-plan/13-processing/161-processing-notifications.md)

### 14 — Records

*0 of 8 complete.*

- [ ] [162 — Record model, repository and status lifecycle](dev-plan/14-records/162-record-model.md)
- [ ] [163 — Records list, filters and sort](dev-plan/14-records/163-records-list.md)
- [ ] [164 — Search records](dev-plan/14-records/164-records-search.md)
- [ ] [165 — Record detail screen](dev-plan/14-records/165-record-detail.md)
- [ ] [166 — Edit a saved record: fields, photos and template](dev-plan/14-records/166-record-edit-fields.md)
- [ ] [167 — Record history view](dev-plan/14-records/167-record-history.md)
- [ ] [168 — Delete, recycle bin and retention purge](dev-plan/14-records/168-record-delete.md)
- [ ] [169 — Bulk actions on records](dev-plan/14-records/169-record-bulk-actions.md)

### 15 — Data quality

*0 of 10 complete.*

- [ ] [170 — Validation engine and validators](dev-plan/15-data-quality/170-validation-engine.md)
- [ ] [171 — Validation display](dev-plan/15-data-quality/171-validation-display.md)
- [ ] [172 — Identity hash and duplicate detection](dev-plan/15-data-quality/172-identity-hash.md)
- [ ] [173 — Duplicate prompt and resolution](dev-plan/15-data-quality/173-duplicate-prompt.md)
- [ ] [174 — Duplicates review screen](dev-plan/15-data-quality/174-duplicates-screen.md)
- [ ] [175 — Source conflicts: detect and resolve](dev-plan/15-data-quality/175-source-conflict-detection.md)
- [ ] [176 — Verification mode and register prefill](dev-plan/15-data-quality/176-verification-mode.md)
- [ ] [177 — Variance and missing-item computation](dev-plan/15-data-quality/177-variance-computation.md)
- [ ] [178 — Variance screen](dev-plan/15-data-quality/178-variance-screen.md)
- [ ] [179 — Project quality summary](dev-plan/15-data-quality/179-quality-summary.md)

### 16 — Review

*0 of 6 complete.*

- [ ] [180 — Review screen and attention-first ordering](dev-plan/16-review/180-review-screen.md)
- [ ] [181 — Review row controls: raw, refined, confidence and gaps](dev-plan/16-review/181-raw-refined-toggle.md)
- [ ] [182 — Evidence viewer](dev-plan/16-review/182-evidence-viewer.md)
- [ ] [183 — Mark a field verified](dev-plan/16-review/183-verify-field.md)
- [ ] [184 — Approve and next, and the batch queue](dev-plan/16-review/184-approve-record.md)
- [ ] [185 — Re-analyse a record](dev-plan/16-review/185-reanalyse-record.md)

### 17 — Meetings

*0 of 7 complete.*

- [ ] [186 — Meeting template, model and creation](dev-plan/17-meetings/186-meeting-template.md)
- [ ] [187 — Agenda and attendee editors](dev-plan/17-meetings/187-agenda-editor.md)
- [ ] [188 — Attendance sheet: capture, read and match](dev-plan/17-meetings/188-attendance-photo.md)
- [ ] [189 — Record and transcribe the meeting](dev-plan/17-meetings/189-meeting-audio.md)
- [ ] [190 — Refine the minutes](dev-plan/17-meetings/190-minutes-refinement.md)
- [ ] [191 — Decisions and action items editors](dev-plan/17-meetings/191-decisions-editor.md)
- [ ] [192 — Meeting review and approval](dev-plan/17-meetings/192-meeting-review.md)

### 18 — Export

*0 of 15 complete.*

- [ ] [193 — Export request model and pre-export validation](dev-plan/18-export/193-export-model.md)
- [ ] [194 — Scope and options sections](dev-plan/18-export/194-export-scope.md)
- [ ] [195 — Export value formatter](dev-plan/18-export/195-value-formatter.md)
- [ ] [196 — Photo naming and renaming on identification](dev-plan/18-export/196-photo-naming-service.md)
- [ ] [197 — XLSX writer core, column pairs and sheets](dev-plan/18-export/197-xlsx-writer.md)
- [ ] [198 — Write into a copy of the client workbook](dev-plan/18-export/198-xlsx-template-copy.md)
- [ ] [199 — Photo columns and photo index sheet](dev-plan/18-export/199-xlsx-photo-references.md)
- [ ] [200 — CSV, JSON and data dictionary writers](dev-plan/18-export/200-csv-writer.md)
- [ ] [201 — PDF engine and shared layout](dev-plan/18-export/201-pdf-engine.md)
- [ ] [202 — Record and inspection reports](dev-plan/18-export/202-pdf-record-report.md)
- [ ] [203 — Project summary and variance reports](dev-plan/18-export/203-pdf-summary-report.md)
- [ ] [204 — Meeting minutes PDF](dev-plan/18-export/204-pdf-minutes.md)
- [ ] [205 — ZIP data package and manifest](dev-plan/18-export/205-zip-package.md)
- [ ] [206 — Export screen, progress and cancellation](dev-plan/18-export/206-export-screen.md)
- [ ] [207 — Export history, versioning and sharing](dev-plan/18-export/207-export-history.md)

### 19 — Bundles and merge

*0 of 12 complete.*

- [ ] [208 — Bundle format, manifest and writer](dev-plan/19-bundles-and-merge/208-bundle-format.md)
- [ ] [209 — Bundle scope, sharing and receiving](dev-plan/19-bundles-and-merge/209-bundle-scope.md)
- [ ] [210 — Bundle encryption and secret exclusion](dev-plan/19-bundles-and-merge/210-bundle-encryption.md)
- [ ] [211 — Bundle reader, validation and import as a new project](dev-plan/19-bundles-and-merge/211-bundle-reader.md)
- [ ] [212 — Version vectors and tombstone propagation](dev-plan/19-bundles-and-merge/212-version-vector-service.md)
- [ ] [213 — Entity and field merge with automatic settlement](dev-plan/19-bundles-and-merge/213-merge-entity-level.md)
- [ ] [214 — Merge photos, templates and reference data](dev-plan/19-bundles-and-merge/214-merge-photos.md)
- [ ] [215 — Relabel colliding record numbers](dev-plan/19-bundles-and-merge/215-merge-record-numbers.md)
- [ ] [216 — Merge preview screen](dev-plan/19-bundles-and-merge/216-merge-preview.md)
- [ ] [217 — Conflict resolution, one at a time and in bulk](dev-plan/19-bundles-and-merge/217-conflict-screen.md)
- [ ] [218 — Apply, record and undo a merge](dev-plan/19-bundles-and-merge/218-merge-apply.md)
- [ ] [219 — Post-merge duplicate scan](dev-plan/19-bundles-and-merge/219-post-merge-duplicates.md)

### 20 — Data import

*0 of 4 complete.*

- [ ] [220 — Map spreadsheet columns to template fields](dev-plan/20-data-import/220-import-records-mapping.md)
- [ ] [221 — Create records from rows, with duplicate handling](dev-plan/20-data-import/221-import-records-create.md)
- [ ] [222 — Import entry point and purpose step](dev-plan/20-data-import/222-import-entry.md)
- [ ] [223 — Import summary](dev-plan/20-data-import/223-import-summary.md)

### 21 — Cloud upload

*0 of 6 complete.*

- [ ] [224 — Destination abstraction and model](dev-plan/21-cloud-upload/224-destination-model.md)
- [ ] [225 — Destinations screen with test and removal](dev-plan/21-cloud-upload/225-destination-list.md)
- [ ] [226 — S3, WebDAV and folder destinations](dev-plan/21-cloud-upload/226-destination-s3.md)
- [ ] [227 — Google Drive, OneDrive and Dropbox destinations](dev-plan/21-cloud-upload/227-destination-google-drive.md)
- [ ] [228 — Upload confirmation](dev-plan/21-cloud-upload/228-upload-confirm.md)
- [ ] [229 — Upload runner, progress and history](dev-plan/21-cloud-upload/229-upload-runner.md)

### 22 — Privacy and security

*0 of 6 complete.*

- [ ] [230 — What leaves this device, and location control](dev-plan/22-privacy-and-security/230-egress-summary-screen.md)
- [ ] [231 — Per-project AI and image egress switches](dev-plan/22-privacy-and-security/231-ai-disable-per-project.md)
- [ ] [232 — Consent, face blurring and redaction](dev-plan/22-privacy-and-security/232-consent-flag.md)
- [ ] [233 — Treat imported text as data](dev-plan/22-privacy-and-security/233-untrusted-text-handling.md)
- [ ] [234 — Automated secret leak test](dev-plan/22-privacy-and-security/234-secret-scan-test.md)
- [ ] [235 — Permission minimisation review](dev-plan/22-privacy-and-security/235-permission-minimisation.md)

### 23 — Hardening

*0 of 9 complete.*

- [ ] [236 — Layout, accessibility and text-scale audit](dev-plan/23-hardening/236-responsive-audit.md)
- [ ] [237 — Landscape and foldables](dev-plan/23-hardening/237-orientation-support.md)
- [ ] [238 — Copy pass and localisation scaffolding](dev-plan/23-hardening/238-copy-review.md)
- [ ] [239 — Empty-state coverage test](dev-plan/23-hardening/239-empty-states-review.md)
- [ ] [240 — Performance pass: lists, indexes, start-up, memory and background work](dev-plan/23-hardening/240-list-performance.md)
- [ ] [241 — Failure injection suite](dev-plan/23-hardening/241-error-recovery-review.md)
- [ ] [242 — App icon, splash and store branding](dev-plan/23-hardening/242-branding-assets.md)
- [ ] [243 — Device matrix runner](dev-plan/23-hardening/243-device-matrix-testing.md)
- [ ] [244 — In-app friction log](dev-plan/23-hardening/244-field-trial.md)

### 24 — The minimal backend

*0 of 26 complete.*

- [ ] [245 — Initialise the backend project and its gate](dev-plan/24-backend/245-be-project-init.md)
- [ ] [246 — Configuration loading and validation](dev-plan/24-backend/246-be-config.md)
- [ ] [247 — Structured logger, typed errors and the error envelope](dev-plan/24-backend/247-be-logger.md)
- [ ] [248 — HTTP server, middleware chain and limits](dev-plan/24-backend/248-be-http-server.md)
- [ ] [249 — Database connection, pooling and migrations](dev-plan/24-backend/249-be-db-connection.md)
- [ ] [250 — Schema: organisations, users, devices, projects and members](dev-plan/24-backend/250-be-schema-identity.md)
- [ ] [251 — Schema: relay packages, acknowledgements, version vectors and audit](dev-plan/24-backend/251-be-schema-relay.md)
- [ ] [252 — Repository base and transactions](dev-plan/24-backend/252-be-repositories.md)
- [ ] [253 — Password hashing and the account lifecycle](dev-plan/24-backend/253-be-auth-passwords.md)
- [ ] [254 — Login with rate limiting and lockout](dev-plan/24-backend/254-be-auth-login.md)
- [ ] [255 — Tokens, authentication middleware and device enrolment](dev-plan/24-backend/255-be-auth-tokens.md)
- [ ] [256 — Role matrix and permission checks](dev-plan/24-backend/256-be-permissions.md)
- [ ] [257 — Organisation user endpoints](dev-plan/24-backend/257-be-users-api.md)
- [ ] [258 — Project and membership endpoints](dev-plan/24-backend/258-be-projects-api.md)
- [ ] [259 — Relay: accept, list and download packages](dev-plan/24-backend/259-be-relay-push.md)
- [ ] [260 — Relay: acknowledge, delete and report state](dev-plan/24-backend/260-be-relay-ack.md)
- [ ] [261 — Relay purge job and storage ceilings](dev-plan/24-backend/261-be-retention-job.md)
- [ ] [262 — AI provider abstraction and key custody](dev-plan/24-backend/262-be-ai-provider.md)
- [ ] [263 — AI proxy endpoints, quotas and resilience](dev-plan/24-backend/263-be-ai-proxy.md)
- [ ] [264 — Audit, security events and metrics](dev-plan/24-backend/264-be-audit-service.md)
- [ ] [265 — OpenAPI specification and contract tests](dev-plan/24-backend/265-be-openapi.md)
- [ ] [266 — Export, destroy, deploy and the pipeline](dev-plan/24-backend/266-be-admin-commands.md)
- [ ] [267 — App: backend connection, sign in and enrolment](dev-plan/24-backend/267-fe-backend-config.md)
- [ ] [268 — App: role affordances, cached grants and offline authority](dev-plan/24-backend/268-fe-role-affordances.md)
- [ ] [269 — App: change relay client and controls](dev-plan/24-backend/269-fe-relay-client.md)
- [ ] [270 — App: route AI through the backend](dev-plan/24-backend/270-fe-ai-proxy-client.md)

### 25 — Testing and release

*0 of 11 complete.*

- [ ] [271 — Test harnesses: unit, widget and integration](dev-plan/25-testing-and-release/271-test-harness-unit.md)
- [ ] [272 — End-to-end: capture to export, immediate and deferred](dev-plan/25-testing-and-release/272-e2e-capture-to-export.md)
- [ ] [273 — End-to-end: context inheritance and caption scope](dev-plan/25-testing-and-release/273-e2e-context-inheritance.md)
- [ ] [274 — End-to-end: known-asset verification and duplicate override](dev-plan/25-testing-and-release/274-e2e-known-asset.md)
- [ ] [275 — End-to-end: bundle merge and every export format](dev-plan/25-testing-and-release/275-e2e-merge.md)
- [ ] [276 — End-to-end: meeting](dev-plan/25-testing-and-release/276-e2e-meeting.md)
- [ ] [277 — Continuous integration pipelines](dev-plan/25-testing-and-release/277-ci-pipeline.md)
- [ ] [278 — Release build configuration](dev-plan/25-testing-and-release/278-release-build.md)
- [ ] [279 — Release gate program](dev-plan/25-testing-and-release/279-release-checklist.md)
- [ ] [280 — Backlog report generator](dev-plan/25-testing-and-release/280-post-release-backlog.md)
- [ ] [281 — End-to-end: sign in, proxy AI, then go offline](dev-plan/25-testing-and-release/281-e2e-signin-proxy-offline.md)
