# Tapture — development tracker

**41 of 281 tasks complete (14.6%)** · last updated 2026-09-17

`██████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░`

## Phase progress

| Phase | Done | Total | Progress |
| :--- | ---: | ---: | :--- |
| 01 — Project setup and guardrails | 18 | 18 | `██████████████` 100% |
| 02 — Foundation services | 11 | 11 | `██████████████` 100% |
| 03 — Design system | 12 | 19 | `█████████░░░░░` 63% |
| 04 — Local database | 0 | 16 | `░░░░░░░░░░░░░░` 0% |
| 05 — File storage | 0 | 7 | `░░░░░░░░░░░░░░` 0% |
| 06 — Application shell | 0 | 5 | `░░░░░░░░░░░░░░` 0% |
| 07 — Account and settings | 0 | 5 | `░░░░░░░░░░░░░░` 0% |
| 08 — Projects | 0 | 6 | `░░░░░░░░░░░░░░` 0% |
| 09 — Templates | 0 | 17 | `░░░░░░░░░░░░░░` 0% |
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
| **Total** | **41** | **281** | `██░░░░░░░░░░░░` 14.6% |

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
| 027 | Database encryption (064) needs a key in secure storage; `SecretKey` only lists the seven names already in `AppConstants.secrets`. | Open — 064 can add the encryption key; this task does not invent one |
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
| 035 | Catalogue copy (`Clear`, `Auto-filled`, `Out of range`) is still inline. | Open — task 046 is the copy helper that strips literals from `core/widgets/` |
| 036 | `enabled` is not on the contract, and the checkbox variant is a named constructor rather than a second type. | Open — galleries and settings need a disabled state; `AppSwitchTile.checkbox` keeps one public class (FE-STR-06) |
| 036 | Closed multi-choice values render with Material `Chip` until `AppChip` exists. | Closed by 037 — `AppMultiChoiceField` now composes `AppChip` / `AppChipRow` |
| 036 | Sheets call `showModalBottomSheet` directly. | Closed by 041 — `AppChoiceField` and `AppMultiChoiceField` open through `showAppSheet` |
| 040 | Offline as a fourth visual state is a persistent banner. | Closed by 041 — `AppBanner` is dismissible, announced, and excluded from focus |
| 041 | Confirm/alert/snack/banner copy is still inline. | Open — task 046 is the copy helper that strips literals from `core/widgets/` |
| 041 | `AppPage` has no banner slot. | Open — screens compose `AppBanner` under the app bar until a later scaffold pass |
| 036 | Catalogue copy (`Select all`, `Clear`) is still inline. | Open — task 046 is the copy helper that strips literals from `core/widgets/` |
| 037 | FE-STR-06 wants one public class; the contract publishes `AppChip` and `AppChipRow`. | Closed by 037 — `AppChipRow` lives in a part file so one public class per file still holds |
| 037 | Catalogue copy (`Dismiss {label}`) is still inline. | Open — task 046 is the copy helper that strips literals from `core/widgets/` |
| 038 | The contract types the status slot as `AppStatusPill`, which is task 039. | Closed by 039 — `AppListTile.status` is `AppStatusPill?`; `.badge` is the compact form |
| 039 | FE-STR-06 wants one public class; the contract publishes `StatusStyle` too. | Closed by 039 — `StatusStyle` lives in a part file |
| 039 | `StatusStyle.of` needs colours, and `RecordStatus` is named by task 162. | Open — `of` takes `AppColors` as well as the enum; the enum lives here so core does not import features. 162 should reuse it, not redeclare it, and may need a Dart-only home so domain stays Flutter-free |
| 039 | Status labels are still inline. | Open — task 046 is the copy helper that strips literals from `core/widgets/` |
| 040 | The file is `app_loading_state.dart`; the contract names `AppSkeleton`. | Closed by 040 — `AppLoadingState` is a typedef for `AppSkeleton`, matching the file name (FE-STR-06) |
| 040 | `AsyncValueView` needs a skeleton shape while loading. | Open — extra `loadingShape` / `loadingCount` so the placeholder occupies the same space as the content |
| 040 | Empty, error and retry copy is still inline. | Open — task 046 is the copy helper that strips literals from `core/widgets/` |

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

*12 of 19 complete.*

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
- [ ] [042 — Step progress list](dev-plan/03-design-system/042-app-progress-steps.md)
- [ ] [043 — Photo thumbnail](dev-plan/03-design-system/043-app-photo-thumb.md)
- [ ] [044 — Form scaffold, validation display and focus behaviour](dev-plan/03-design-system/044-app-form-scaffold.md)
- [ ] [045 — Haptics service](dev-plan/03-design-system/045-haptics-service.md)
- [ ] [046 — User-facing copy helper](dev-plan/03-design-system/046-copy-helper.md)
- [ ] [047 — Widget gallery screen](dev-plan/03-design-system/047-widget-gallery.md)
- [ ] [048 — Golden test baselines for the catalogue](dev-plan/03-design-system/048-golden-baselines.md)

### 04 — Local database

*0 of 16 complete.*

- [ ] [049 — Drift database bootstrap and migration strategy](dev-plan/04-data-layer/049-drift-setup.md)
- [ ] [050 — Shared columns, DAO base and transaction helper](dev-plan/04-data-layer/050-column-mixins.md)
- [ ] [051 — Tombstones, audit log and device profile tables](dev-plan/04-data-layer/051-tombstones-table.md)
- [ ] [052 — Projects and context tables](dev-plan/04-data-layer/052-projects-table.md)
- [ ] [053 — Templates, template fields and template rows tables](dev-plan/04-data-layer/053-templates-table.md)
- [ ] [054 — Records and record fields tables](dev-plan/04-data-layer/054-records-table.md)
- [ ] [055 — Photos, attachments and captions tables](dev-plan/04-data-layer/055-photos-table.md)
- [ ] [056 — Reference dataset tables](dev-plan/04-data-layer/056-reference-tables.md)
- [ ] [057 — Processing jobs, results and field evidence tables](dev-plan/04-data-layer/057-jobs-table.md)
- [ ] [058 — Duplicates and variances tables](dev-plan/04-data-layer/058-duplicates-table.md)
- [ ] [059 — Meeting tables](dev-plan/04-data-layer/059-meetings-tables.md)
- [ ] [060 — Exports table](dev-plan/04-data-layer/060-exports-table.md)
- [ ] [061 — Merge session, conflict and version vector tables](dev-plan/04-data-layer/061-merge-tables.md)
- [ ] [062 — Repository interfaces and test factories](dev-plan/04-data-layer/062-repository-interfaces.md)
- [ ] [063 — Database integrity check](dev-plan/04-data-layer/063-db-integrity-check.md)
- [ ] [064 — Optional database encryption](dev-plan/04-data-layer/064-db-encryption.md)

### 05 — File storage

*0 of 7 complete.*

- [ ] [065 — Storage root resolution](dev-plan/05-file-storage/065-storage-root.md)
- [ ] [066 — Project folder tree, name sanitiser and photo path builder](dev-plan/05-file-storage/066-project-folder-service.md)
- [ ] [067 — Atomic file writer and context relocation](dev-plan/05-file-storage/067-file-writer.md)
- [ ] [068 — Derived image cache: thumbnails, compressed copies and cleanup](dev-plan/05-file-storage/068-thumbnail-cache.md)
- [ ] [069 — Storage headroom guard](dev-plan/05-file-storage/069-storage-guard.md)
- [ ] [070 — Orphan file scanner](dev-plan/05-file-storage/070-orphan-scanner.md)
- [ ] [071 — Imported file validation](dev-plan/05-file-storage/071-file-validation.md)

### 06 — Application shell

*0 of 5 complete.*

- [ ] [072 — Router, route table and guards](dev-plan/06-app-shell/072-router-setup.md)
- [ ] [073 — Adaptive navigation shell](dev-plan/06-app-shell/073-nav-shell.md)
- [ ] [074 — First-run flow](dev-plan/06-app-shell/074-first-run.md)
- [ ] [075 — Global status line and offline banner](dev-plan/06-app-shell/075-status-line.md)
- [ ] [076 — Global error and crash recovery screen](dev-plan/06-app-shell/076-global-error-page.md)

### 07 — Account and settings

*0 of 5 complete.*

- [ ] [077 — Operator profile](dev-plan/07-account-and-settings/077-operator-profile.md)
- [ ] [078 — Settings store](dev-plan/07-account-and-settings/078-settings-store.md)
- [ ] [079 — Settings shell and its section screens](dev-plan/07-account-and-settings/079-settings-shell.md)
- [ ] [080 — App lock: PIN and biometric unlock](dev-plan/07-account-and-settings/080-app-lock-pin.md)
- [ ] [081 — Manual offline mode switch](dev-plan/07-account-and-settings/081-offline-switch.md)

### 08 — Projects

*0 of 6 complete.*

- [ ] [082 — Project domain model and repository](dev-plan/08-projects/082-project-model.md)
- [ ] [083 — Project list and the current project](dev-plan/08-projects/083-project-list.md)
- [ ] [084 — Create and duplicate a project](dev-plan/08-projects/084-project-create.md)
- [ ] [085 — Project home screen](dev-plan/08-projects/085-project-home.md)
- [ ] [086 — Project details and per-project settings](dev-plan/08-projects/086-project-edit.md)
- [ ] [087 — Archive, unarchive and delete a project](dev-plan/08-projects/087-project-archive.md)

### 09 — Templates

*0 of 17 complete.*

- [ ] [088 — Template domain model and repository](dev-plan/09-templates/088-template-model.md)
- [ ] [089 — Field type registry](dev-plan/09-templates/089-field-type-registry.md)
- [ ] [090 — Shipped template asset format and atomicity checker](dev-plan/09-templates/090-shipped-templates-assets.md)
- [ ] [091 — Author the shipped template library](dev-plan/09-templates/091-shipped-template-library.md)
- [ ] [092 — Template list, blank create and duplicate](dev-plan/09-templates/092-template-list.md)
- [ ] [093 — Shipped template loader and library picker](dev-plan/09-templates/093-shipped-template-loader.md)
- [ ] [094 — Field list editor, reorder and delete](dev-plan/09-templates/094-field-list-editor.md)
- [ ] [095 — Add and edit a field, with Advanced, validation and options](dev-plan/09-templates/095-field-add-basic.md)
- [ ] [096 — Required columns screen](dev-plan/09-templates/096-required-columns-screen.md)
- [ ] [097 — Field editor widget](dev-plan/09-templates/097-field-editor-inline.md)
- [ ] [098 — Identity fields and output column mapping](dev-plan/09-templates/098-identity-fields.md)
- [ ] [099 — Template versioning and record migration](dev-plan/09-templates/099-template-versioning.md)
- [ ] [100 — Export and import a template as JSON](dev-plan/09-templates/100-template-export-json.md)
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
