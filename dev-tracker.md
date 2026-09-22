# Tapture — development tracker

**42 of 60 tasks complete (70.0%)** · last updated 2026-09-22

`█████████████████████████░░░░░░░░░░░`

On 2026-09-22 completed phases 01–09 became tasks 001–009, remaining phases became 010–025, and leftover
field-feedback extras became 026–060. Old numbers are in [RETIRED.md](dev-plan/RETIRED.md).

## Phase progress

| Phase | Done | Total | Progress |
| :--- | ---: | ---: | :--- |
| 01 — Project setup and guardrails | 1 | 1 | `██████████████` 100% |
| 02 — Foundation services | 1 | 1 | `██████████████` 100% |
| 03 — Design system | 1 | 1 | `██████████████` 100% |
| 04 — Local database | 1 | 1 | `██████████████` 100% |
| 05 — File storage | 1 | 1 | `██████████████` 100% |
| 06 — Application shell | 1 | 1 | `██████████████` 100% |
| 07 — Account and settings | 1 | 1 | `██████████████` 100% |
| 08 — Projects | 1 | 1 | `██████████████` 100% |
| 09 — Templates | 1 | 1 | `██████████████` 100% |
| 10 — Reference data | 0 | 1 | `░░░░░░░░░░░░░░` 0% |
| 11 — Context | 0 | 1 | `░░░░░░░░░░░░░░` 0% |
| 12 — Capture | 0 | 1 | `░░░░░░░░░░░░░░` 0% |
| 13 — Processing | 0 | 1 | `░░░░░░░░░░░░░░` 0% |
| 14 — Records | 0 | 1 | `░░░░░░░░░░░░░░` 0% |
| 15 — Data quality | 0 | 1 | `░░░░░░░░░░░░░░` 0% |
| 16 — Review | 0 | 1 | `░░░░░░░░░░░░░░` 0% |
| 17 — Meetings | 0 | 1 | `░░░░░░░░░░░░░░` 0% |
| 18 — Export | 0 | 1 | `░░░░░░░░░░░░░░` 0% |
| 19 — Bundles and merge | 0 | 1 | `░░░░░░░░░░░░░░` 0% |
| 20 — Data import | 0 | 1 | `░░░░░░░░░░░░░░` 0% |
| 21 — Cloud upload | 0 | 1 | `░░░░░░░░░░░░░░` 0% |
| 22 — Privacy and security | 0 | 1 | `░░░░░░░░░░░░░░` 0% |
| 23 — Hardening | 33 | 36 | `█████████████░` 92% |
| 24 — The minimal backend | 0 | 1 | `░░░░░░░░░░░░░░` 0% |
| 25 — Testing and release | 0 | 1 | `░░░░░░░░░░░░░░` 0% |
| **Total** | **42** | **60** | `█████████████████████████░░░░░░░░░░░` 70.0% |

## Completed

| Task | Closed | What landed |
| :--- | :--- | :--- |
| 001 — Project setup and guardrails | 2026-09-17 | Flutter app, hygiene, strict analyzer, folder skeleton, allowlist, plan checker, scaffolder, verify, hooks, and the architecture suites. |
| 002 — Foundation services | 2026-09-17 | Bootstrap, constants, Result/Failure, logger, clock, hashing, connectivity, permissions, secure storage, codecs, AI port. |
| 003 — Design system | 2026-09-22 | Tokens, themes, catalogue widgets, gallery, goldens, plus later button padding, requiredness-in-label and borderless overflow. |
| 004 — Local database | 2026-09-17 | Drift tables, mixins, repositories, integrity check and optional encryption. |
| 005 — File storage | 2026-09-22 | Storage root, project folders, writer, cache, guard, orphan scanner, validation, share_plus and storage volume. |
| 006 — Application shell | 2026-09-22 | Router, adaptive nav, first-run, status line, error page, plus later shell and list-pane feedback. |
| 007 — Account and settings | 2026-09-17 | Operator profile, settings store, settings shell, app lock, offline switch. |
| 008 — Projects | 2026-09-22 | Model, list, create, home, details, archive, plus pinning, dictation, list actions and home-card work. |
| 009 — Templates | 2026-09-17 | Model, registry, shipped library, editors, requiredness, versioning, JSON and spreadsheet import, detection profile. |

Task numbers in this table are the original atomic numbers from before the 2026-09-22 merge. [RETIRED.md](dev-plan/RETIRED.md) says which live task absorbed each one.

## Carried decisions

Things a finished task surfaced that are not yet resolved. Each needs a numbered task file
(`dart run tool/new_task.dart`, available since task 001, which absorbed the old scaffolder) rather than a note here — FE-FLOW-08.

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

*1 of 1 complete.*

- [x] [001 — Project setup and guardrails](dev-plan/01-orchestration/001-project-setup.md)

### 02 — Foundation services

*1 of 1 complete.*

- [x] [002 — Foundation services](dev-plan/02-foundation/002-foundation-services.md)

### 03 — Design system

*1 of 1 complete.*

- [x] [003 — Design system: tokens, themes and the whole widget vocabulary](dev-plan/03-design-system/003-design-system.md)

### 04 — Local database

*1 of 1 complete.*

- [x] [004 — Local database: every table, with merge columns from the first migration](dev-plan/04-data-layer/004-local-database.md)

### 05 — File storage

*1 of 1 complete.*

- [x] [005 — File storage: the organised folder tree and every service that writes into it](dev-plan/05-file-storage/005-file-storage.md)

### 06 — Application shell

*1 of 1 complete.*

- [x] [006 — Application shell: navigation, the status line and the frame every feature plugs into](dev-plan/06-app-shell/006-application-shell.md)

### 07 — Account and settings

*1 of 1 complete.*

- [x] [007 — Account and settings: local identity, the app lock and the switches later features read](dev-plan/07-account-and-settings/007-account-and-settings.md)

### 08 — Projects

*1 of 1 complete.*

- [x] [008 — Projects: the container that owns everything else](dev-plan/08-projects/008-projects.md)

### 09 — Templates

*1 of 1 complete.*

- [x] [009 — Templates: record shapes with atomic columns, and requiredness the user owns](dev-plan/09-templates/009-templates.md)

### 10 — Reference data

*0 of 1 complete.*

- [ ] [010 — Reference data: datasets, lookups and prefill](dev-plan/10-reference-data/010-reference-data.md)

### 11 — Context

*0 of 1 complete.*

- [ ] [011 — Context: hierarchy, bar and inheritance](dev-plan/11-context/011-context.md)

### 12 — Capture

*0 of 1 complete.*

- [ ] [012 — Capture: evidence in, saved before anything else](dev-plan/12-capture/012-capture.md)

### 13 — Processing

*0 of 1 complete.*

- [ ] [013 — Processing: on-device first, online only when it earns its place](dev-plan/13-processing/013-processing.md)

### 14 — Records

*0 of 1 complete.*

- [ ] [014 — Records: find, read and change what was captured](dev-plan/14-records/014-records.md)

### 15 — Data quality

*0 of 1 complete.*

- [ ] [015 — Data quality: validation, duplicates, conflicts and variance](dev-plan/15-data-quality/015-data-quality.md)

### 16 — Review

*0 of 1 complete.*

- [ ] [016 — Review: turning proposals into approved data](dev-plan/16-review/016-review.md)

### 17 — Meetings

*0 of 1 complete.*

- [ ] [017 — Meetings: minutes, attendance and actions](dev-plan/17-meetings/017-meetings.md)

### 18 — Export

*0 of 1 complete.*

- [ ] [018 — Export: XLSX, CSV, JSON, PDF and ZIP, all produced on device](dev-plan/18-export/018-export.md)

### 19 — Bundles and merge

*0 of 1 complete.*

- [ ] [019 — Bundles and merge: a project leaves whole and rejoins safely](dev-plan/19-bundles-and-merge/019-bundles-and-merge.md)

### 20 — Data import

*0 of 1 complete.*

- [ ] [020 — Data import: continue an inventory someone else started](dev-plan/20-data-import/020-data-import.md)

### 21 — Cloud upload

*0 of 1 complete.*

- [ ] [021 — Cloud upload: a destination the user chooses, never a sync channel](dev-plan/21-cloud-upload/021-cloud-upload.md)

### 22 — Privacy and security

*0 of 1 complete.*

- [ ] [022 — Privacy and security: what leaves this device, and what never does](dev-plan/22-privacy-and-security/022-privacy-and-security.md)

### 23 — Hardening

*33 of 36 complete.*

- [ ] [023 — Hardening: fast, legible, reachable and unbreakable in the field](dev-plan/23-hardening/023-hardening.md)
- [x] [026 — In-app feedback: floating button, capture, download and delete](dev-plan/23-hardening/026-in-app-feedback.md)
- [x] [027 — Feedback screens: compact layout, dictation and reopen safety](dev-plan/23-hardening/027-feedback-dictation-and-layout.md)
- [x] [028 — Feedback archive: ship the prompts generator](dev-plan/23-hardening/028-feedback-prompts-generator.md)
- [ ] [029 — Enable AppDatabase on web](dev-plan/23-hardening/029-enable-app-database-on-web.md)
- [ ] [030 — Fix storage settings on web](dev-plan/23-hardening/030-fix-storage-settings-on-web.md)
- [x] [031 — Dock feedback panel beside app](dev-plan/23-hardening/031-dock-feedback-panel-beside-app.md)
- [x] [032 — Rename More nav to Settings](dev-plan/23-hardening/032-rename-more-nav-to-settings.md)
- [x] [033 — Fix feedback search remount](dev-plan/23-hardening/033-fix-feedback-search-remount.md)
- [x] [034 — Fix feedback camera browse](dev-plan/23-hardening/034-fix-feedback-camera-browse.md)
- [x] [035 — Mark required optional fields](dev-plan/23-hardening/035-mark-required-optional-fields.md)
- [x] [036 — Add email phone fields](dev-plan/23-hardening/036-add-email-phone-fields.md)
- [x] [037 — Add feedback close control](dev-plan/23-hardening/037-add-feedback-close-control.md)
- [x] [038 — Split operator contact fields](dev-plan/23-hardening/038-split-operator-contact-fields.md)
- [x] [039 — Include feedback UI screenshot](dev-plan/23-hardening/039-include-feedback-ui-screenshot.md)
- [x] [040 — Add other window screenshot](dev-plan/23-hardening/040-add-other-window-screenshot.md)
- [x] [041 — Warn before closing the tab with a draft](dev-plan/23-hardening/041-warn-before-closing-tab-with-draft.md)
- [x] [042 — Confirm desktop exit with a draft](dev-plan/23-hardening/042-confirm-desktop-exit-with-draft.md)
- [x] [043 — Align the feedback shot controls](dev-plan/23-hardening/043-align-feedback-shot-controls.md)
- [x] [044 — Soften input placeholder text](dev-plan/23-hardening/044-soften-input-placeholder-text.md)
- [x] [045 — Number feedback rows with their message](dev-plan/23-hardening/045-number-feedback-rows-with-message.md)
- [x] [046 — Add a window share session to screen capture](dev-plan/23-hardening/046-add-window-share-session-api.md)
- [x] [047 — Add repeat external window screenshots](dev-plan/23-hardening/047-add-repeat-external-window-screenshots.md)
- [x] [048 — Fix the storage root on Android](dev-plan/23-hardening/048-fix-storage-root-on-android.md)
- [x] [049 — Save downloads to a public Tapture folder](dev-plan/23-hardening/049-save-downloads-to-public-tapture-folder.md)
- [x] [050 — Keep the feedback bar above the keyboard](dev-plan/23-hardening/050-keep-feedback-bar-above-keyboard.md)
- [x] [051 — Move the storage root to public Documents](dev-plan/23-hardening/051-move-storage-root-to-public-documents.md)
- [x] [052 — Unify the confirmation dialog design](dev-plan/23-hardening/052-unify-confirmation-dialog-design.md)
- [x] [053 — Add screenshot help for other screens](dev-plan/23-hardening/053-add-screenshot-help-for-other-screens.md)
- [x] [054 — Persist the theme mode in the settings store](dev-plan/23-hardening/054-persist-theme-mode-in-settings-store.md)
- [x] [055 — Add the Appearance settings screen](dev-plan/23-hardening/055-add-appearance-settings-screen.md)
- [x] [056 — Show the feedback download location](dev-plan/23-hardening/056-show-feedback-download-location.md)
- [x] [057 — Add a Save to a folder option](dev-plan/23-hardening/057-add-save-to-folder-option.md)
- [x] [058 — Show a collapse icon on the feedback form](dev-plan/23-hardening/058-show-collapse-icon-on-feedback-form.md)
- [x] [059 — Show a single feedback image as a thumbnail](dev-plan/23-hardening/059-show-single-feedback-image-as-thumbnail.md)
- [x] [060 — Borderless overflow menus](dev-plan/23-hardening/060-borderless-overflow-menus.md)

### 24 — The minimal backend

*0 of 1 complete.*

- [ ] [024 — The minimal backend, and the app that runs on it](dev-plan/24-backend/024-minimal-backend.md)

### 25 — Testing and release

*0 of 1 complete.*

- [ ] [025 — Testing and release: the suites, the pipeline and the gate over both artefacts](dev-plan/25-testing-and-release/025-testing-and-release.md)
