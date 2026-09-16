# Tapture — development tracker

**11 of 522 tasks complete (2.1%)** · last updated 2026-09-09

`░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░`

## Phase progress

| Phase | Done | Total | Progress |
| :--- | ---: | ---: | :--- |
| 01 — Project setup and guardrails | 11 | 22 | `███████░░░░░░░` 50% |
| 02 — Foundation services | 0 | 19 | `░░░░░░░░░░░░░░` 0% |
| 03 — Design system | 0 | 42 | `░░░░░░░░░░░░░░` 0% |
| 04 — Local database | 0 | 31 | `░░░░░░░░░░░░░░` 0% |
| 05 — File storage | 0 | 12 | `░░░░░░░░░░░░░░` 0% |
| 06 — Application shell | 0 | 7 | `░░░░░░░░░░░░░░` 0% |
| 07 — Account and settings | 0 | 9 | `░░░░░░░░░░░░░░` 0% |
| 08 — Projects | 0 | 10 | `░░░░░░░░░░░░░░` 0% |
| 09 — Templates | 0 | 33 | `░░░░░░░░░░░░░░` 0% |
| 10 — Reference data | 0 | 16 | `░░░░░░░░░░░░░░` 0% |
| 11 — Context | 0 | 14 | `░░░░░░░░░░░░░░` 0% |
| 12 — Capture | 0 | 45 | `░░░░░░░░░░░░░░` 0% |
| 13 — Processing | 0 | 39 | `░░░░░░░░░░░░░░` 0% |
| 14 — Records | 0 | 15 | `░░░░░░░░░░░░░░` 0% |
| 15 — Data quality | 0 | 20 | `░░░░░░░░░░░░░░` 0% |
| 16 — Review | 0 | 10 | `░░░░░░░░░░░░░░` 0% |
| 17 — Meetings | 0 | 14 | `░░░░░░░░░░░░░░` 0% |
| 18 — Export | 0 | 30 | `░░░░░░░░░░░░░░` 0% |
| 19 — Bundles and merge | 0 | 24 | `░░░░░░░░░░░░░░` 0% |
| 20 — Data import | 0 | 6 | `░░░░░░░░░░░░░░` 0% |
| 21 — Cloud upload | 0 | 11 | `░░░░░░░░░░░░░░` 0% |
| 22 — Privacy and security | 0 | 10 | `░░░░░░░░░░░░░░` 0% |
| 23 — Hardening | 0 | 16 | `░░░░░░░░░░░░░░` 0% |
| 24 — The minimal backend | 0 | 49 | `░░░░░░░░░░░░░░` 0% |
| 25 — Testing and release | 0 | 18 | `░░░░░░░░░░░░░░` 0% |
| **Total** | **11** | **522** | `░░░░░░░░░░░░░░` 2.1% |

## Completed

| Task | Closed | What landed |
| :--- | :--- | :--- |
| 001 — Create the Flutter project | 2026-09-09 | App id `com.tapture.app`, label Tapture, demo code removed, `test/smoke_test.dart` green. |
| 002 — Repository hygiene files | 2026-09-09 | `.gitignore` + `.editorconfig`, guarded by `tool/check_repo_hygiene.dart` and 9 tests. |
| 003 — Strict analyzer configuration | 2026-09-09 | `strict-casts`/`-inference`/`-raw-types` on, all 171 enabled rules and diagnostics promoted to error, `public_member_api_docs` scoped to `lib/core/`; guarded by `tool/check_analyzer_config.dart`, 14 config tests and 29 analyzer fixtures. |
| 004 — Create the folder skeleton | 2026-09-09 | 99 directories under `lib/` — `app/`, 28 shared subsystems, 17 features × 3 layers — each owning a barrel; canonical list in `tool/paths.dart`, guarded by `tool/check_structure.dart` and 15 tests. |
| 005 — Dependency allowlist checker | 2026-09-09 | `tool/allowlist.yaml` approves 3 packages with pinned version, purpose and introducing task; `tool/check_dependencies.dart` reads additions and version drift as errors and removals as warnings, guarded by 12 tests. |
| 006 — Plan integrity checker | 2026-09-09 | `tool/check_plan.dart` validates all 522 task files — heading against filename, unique and contiguous numbers, unique slugs, required sections, a tickable Definition of done, and dependency links that resolve and point lower; guarded by 18 tests. |
| 010 — Layering enforcement test | 2026-09-09 | `test/architecture/import_graph.dart` builds the graph from every directive under `lib/` and reads it against all four clauses of FE-STR-04 plus FE-STR-08; a clean and a violating fixture under `test/architecture/fixtures/` prove both directions. Guarded by 20 tests. |
| 011 — Naming and file-layout checker | 2026-09-09 | `tool/check_naming.dart` reads every hand-written file under `lib/` and reports a file name that is not snake_case, a first public type that is not the one the file is named for, a second public class sharing a file, a provider that is not lowerCamelCase ending in `Provider`, and a type built out of a banned word — matched a whole camel-case word at a time, so `ReferenceDataset` passes where `RecordData` does not, and read from declarations only, so Flutter's `ThemeData` is never flagged. Guarded by 42 tests. |
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
| 004 | Task 004 calls its core list exhaustive. It is not: `lib/core/backend/` is required by tasks 020, 497, 498, 500 and 501 but is absent from it, and `lib/core/team/` is on it but is referenced nowhere in the plan. | Open — built the list exactly as written; `check_structure.dart` will fail task 497 until the list or those tasks give |
| 005 | `tool/` now holds two hand-rolled YAML readers — one in `check_analyzer_config.dart`, one in `check_dependencies.dart` — because a `yaml` package would need its own task under FE-FLOW-06. A third checker that reads YAML makes the duplication worth collapsing into one `tool/yaml.dart`. | Open — needs a task, either for the shared reader or for approving the package |
| 007 | A new task always takes the highest number in the plan, so adding one to any phase but the last leaves that phase's README saying something like `Tasks 001–523 (23)`. The count is true and the range is not a range any more. | Open — the summary line's shape assumes phases are contiguous, which new tasks break by design |
| 010 | The barrel rule is checked between features only, as task 010 step 3 words it. `app/` reaching into a feature's internals crosses the same boundary and nothing reports it. | Open — needs a task to decide whether the shell is bound by FE-STR-08 too |
| 011 | FE-CODE-06 wants `Failure` sealed with a variant per failure, and Dart keeps a sealed type's subtypes in one library; task 011 step 2 says a file declares at most one public class. Task 015 cannot satisfy both. | Open — implemented as step 2 says; the rule or the step has to give |
| 011 | A provider is recognised by sitting in a `_providers.dart` file or by a name that already ends in `Provider`, because Riverpod is not an approved dependency yet and there is no type to look for. A provider declared elsewhere under another name is invisible. | Open — needs a task once task 014 brings the package in |
| 011 | `tool/check_naming.dart` is not one of `tool/verify.dart`'s gates, and FE-FLOW-02 does not list naming among them. Like `check_repo_hygiene.dart` it is reached only through its own test under the guardrail gate. | Open — the same question as task 008's row; one task should cover both checkers |
| 009 | `core.autocrlf` is true and there is no `.gitattributes`, so a checkout rewrites shell scripts to CRLF and `#!/bin/sh` stops being a program any host has. The installer normalises on write, so the hooks survive; nothing else committed to this repository does. | Open — needs a task for `.gitattributes`, which is task 002's territory rather than 009's |
| 009 | The commit-msg hook turns away every subject git writes itself: `Merge branch ...` and `Revert ...` carry no task number. Task 009 names no exemption and none was invented. | Open — needs a task if merging and reverting through git become awkward |
| 008 | `dart run tool/verify.dart --fast` takes 79s, and 63s of that is the guardrail suite, over half of which is `verify_test.dart` starting six nested verify runs of its own. Correct, but the pre-commit path pays for it. | Open — needs a task if the wait starts costing more than the coverage is worth |
| 008 | Task 008 lists seven gates and `tool/check_repo_hygiene.dart` from task 002 is not among them. It is only reached through its own test under the guardrail gate. | Open — built the list as written; the checker runs as a test, not as a gate |

## Checklist

### 01 — Project setup and guardrails

*10 of 22 complete.*

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
- [ ] [012 — Canonical domain names](dev-plan/01-orchestration/012-domain-names.md)
- [ ] [013 — Design-token enforcement test](dev-plan/01-orchestration/013-design-token-test.md)
- [ ] [014 — Riverpod convention test](dev-plan/01-orchestration/014-riverpod-test.md)
- [ ] [015 — Error-handling enforcement test](dev-plan/01-orchestration/015-error-handling-test.md)
- [ ] [016 — Logging discipline checker](dev-plan/01-orchestration/016-logging-checker.md)
- [ ] [017 — Test presence checker](dev-plan/01-orchestration/017-test-presence-checker.md)
- [ ] [018 — Responsive boundary test](dev-plan/01-orchestration/018-responsive-test.md)
- [ ] [019 — Accessibility test matchers](dev-plan/01-orchestration/019-accessibility-matchers.md)
- [ ] [020 — Network boundary test](dev-plan/01-orchestration/020-network-test.md)
- [ ] [021 — Raw-data safety test](dev-plan/01-orchestration/021-raw-data-test.md)
- [ ] [022 — Hardcoded secret scan](dev-plan/01-orchestration/022-secret-scan.md)

### 02 — Foundation services

*0 of 19 complete.*

- [ ] [023 — Application bootstrap](dev-plan/02-foundation/023-app-bootstrap.md)
- [ ] [024 — Build flavours and environment](dev-plan/02-foundation/024-env-flavors.md)
- [ ] [025 — Shared constants](dev-plan/02-foundation/025-app-constants.md)
- [ ] [026 — Result type and failure taxonomy](dev-plan/02-foundation/026-result-and-failures.md)
- [ ] [027 — Logger service](dev-plan/02-foundation/027-logger-service.md)
- [ ] [028 — Diagnostics log export](dev-plan/02-foundation/028-log-export-action.md)
- [ ] [029 — Error boundary widget](dev-plan/02-foundation/029-error-boundary-widget.md)
- [ ] [030 — Injectable clock](dev-plan/02-foundation/030-clock-service.md)
- [ ] [031 — UUIDv7 identifier service](dev-plan/02-foundation/031-uuid-service.md)
- [ ] [032 — Hashing service](dev-plan/02-foundation/032-hashing-service.md)
- [ ] [033 — Isolate runner](dev-plan/02-foundation/033-isolate-runner.md)
- [ ] [034 — Device identity](dev-plan/02-foundation/034-device-identity.md)
- [ ] [035 — Connectivity service](dev-plan/02-foundation/035-connectivity-service.md)
- [ ] [036 — Runtime permissions service](dev-plan/02-foundation/036-permissions-service.md)
- [ ] [037 — Secure storage service](dev-plan/02-foundation/037-secure-storage-service.md)
- [ ] [038 — Lifecycle observer](dev-plan/02-foundation/038-app-lifecycle-observer.md)
- [ ] [039 — Riverpod observer](dev-plan/02-foundation/039-provider-observer.md)
- [ ] [040 — Serialisation conventions](dev-plan/02-foundation/040-json-codec-setup.md)
- [ ] [041 — AI service interface](dev-plan/02-foundation/041-ai-service-interface.md)

### 03 — Design system

*0 of 42 complete.*

- [ ] [042 — Colour tokens for light and dark](dev-plan/03-design-system/042-color-tokens.md)
- [ ] [043 — Typography scale](dev-plan/03-design-system/043-typography-scale.md)
- [ ] [044 — Spacing, radius and size tokens](dev-plan/03-design-system/044-spacing-tokens.md)
- [ ] [045 — Elevation and surface treatment](dev-plan/03-design-system/045-elevation-tokens.md)
- [ ] [046 — Assemble the Material 3 theme](dev-plan/03-design-system/046-theme-assembly.md)
- [ ] [047 — High-contrast outdoor theme](dev-plan/03-design-system/047-outdoor-theme.md)
- [ ] [048 — Theme mode controller](dev-plan/03-design-system/048-theme-controller.md)
- [ ] [049 — Breakpoints and responsive helpers](dev-plan/03-design-system/049-breakpoints.md)
- [ ] [050 — Responsive layout builder](dev-plan/03-design-system/050-responsive-builder.md)
- [ ] [051 — Readable width constraint](dev-plan/03-design-system/051-content-constraint.md)
- [ ] [052 — Page scaffold](dev-plan/03-design-system/052-app-page.md)
- [ ] [053 — Buttons](dev-plan/03-design-system/053-app-button.md)
- [ ] [054 — Icon button](dev-plan/03-design-system/054-app-icon-button.md)
- [ ] [055 — Large primary action button](dev-plan/03-design-system/055-app-primary-action.md)
- [ ] [056 — Text field](dev-plan/03-design-system/056-app-text-field.md)
- [ ] [057 — Number field](dev-plan/03-design-system/057-app-number-field.md)
- [ ] [058 — Date, time and date-time field](dev-plan/03-design-system/058-app-date-field.md)
- [ ] [059 — Single choice field](dev-plan/03-design-system/059-app-choice-field.md)
- [ ] [060 — Multi-choice field](dev-plan/03-design-system/060-app-multi-choice-field.md)
- [ ] [061 — Switch and checkbox tiles](dev-plan/03-design-system/061-app-switch-tile.md)
- [ ] [062 — Search field](dev-plan/03-design-system/062-app-search-field.md)
- [ ] [063 — Chip and chip row](dev-plan/03-design-system/063-app-chip.md)
- [ ] [064 — Card](dev-plan/03-design-system/064-app-card.md)
- [ ] [065 — List tile](dev-plan/03-design-system/065-app-list-tile.md)
- [ ] [066 — Section header](dev-plan/03-design-system/066-app-section-header.md)
- [ ] [067 — Status pill and badge](dev-plan/03-design-system/067-app-status-pill.md)
- [ ] [068 — Empty state](dev-plan/03-design-system/068-app-empty-state.md)
- [ ] [069 — Error state](dev-plan/03-design-system/069-app-error-state.md)
- [ ] [070 — Loading and skeletons](dev-plan/03-design-system/070-app-loading-state.md)
- [ ] [071 — Async value view](dev-plan/03-design-system/071-async-value-view.md)
- [ ] [072 — Dialog service](dev-plan/03-design-system/072-app-dialog-service.md)
- [ ] [073 — Bottom sheet service](dev-plan/03-design-system/073-app-bottom-sheet.md)
- [ ] [074 — Snackbar and toast service](dev-plan/03-design-system/074-app-snackbar.md)
- [ ] [075 — Persistent banner](dev-plan/03-design-system/075-app-banner.md)
- [ ] [076 — Step progress list](dev-plan/03-design-system/076-app-progress-steps.md)
- [ ] [077 — Photo thumbnail](dev-plan/03-design-system/077-app-photo-thumb.md)
- [ ] [078 — Form scaffold and validation display](dev-plan/03-design-system/078-app-form-scaffold.md)
- [ ] [079 — Keyboard dismissal and focus traversal](dev-plan/03-design-system/079-keyboard-focus.md)
- [ ] [080 — Haptics service](dev-plan/03-design-system/080-haptics-service.md)
- [ ] [081 — User-facing copy helper](dev-plan/03-design-system/081-copy-helper.md)
- [ ] [082 — Widget gallery screen](dev-plan/03-design-system/082-widget-gallery.md)
- [ ] [083 — Golden test baselines for the catalogue](dev-plan/03-design-system/083-golden-baselines.md)

### 04 — Local database

*0 of 31 complete.*

- [ ] [084 — Drift database bootstrap](dev-plan/04-data-layer/084-drift-setup.md)
- [ ] [085 — Migration strategy and schema version](dev-plan/04-data-layer/085-migration-strategy.md)
- [ ] [086 — Shared column mixins](dev-plan/04-data-layer/086-column-mixins.md)
- [ ] [087 — DAO base and conventions](dev-plan/04-data-layer/087-dao-conventions.md)
- [ ] [088 — Transaction helper](dev-plan/04-data-layer/088-transaction-helper.md)
- [ ] [089 — Tombstones table](dev-plan/04-data-layer/089-tombstones-table.md)
- [ ] [090 — Audit log table](dev-plan/04-data-layer/090-audit-table.md)
- [ ] [091 — Device profile table](dev-plan/04-data-layer/091-device-profile-table.md)
- [ ] [092 — Projects table](dev-plan/04-data-layer/092-projects-table.md)
- [ ] [093 — Templates table](dev-plan/04-data-layer/093-templates-table.md)
- [ ] [094 — Template fields table](dev-plan/04-data-layer/094-template-fields-table.md)
- [ ] [095 — Template rows table](dev-plan/04-data-layer/095-template-rows-table.md)
- [ ] [096 — Context definition and state tables](dev-plan/04-data-layer/096-context-tables.md)
- [ ] [097 — Records table](dev-plan/04-data-layer/097-records-table.md)
- [ ] [098 — Record fields table](dev-plan/04-data-layer/098-record-fields-table.md)
- [ ] [099 — Photos table](dev-plan/04-data-layer/099-photos-table.md)
- [ ] [100 — Documents and audio tables](dev-plan/04-data-layer/100-documents-table.md)
- [ ] [101 — Captions table](dev-plan/04-data-layer/101-captions-table.md)
- [ ] [102 — Reference dataset tables](dev-plan/04-data-layer/102-reference-tables.md)
- [ ] [103 — Processing jobs and results tables](dev-plan/04-data-layer/103-jobs-table.md)
- [ ] [104 — Field evidence table](dev-plan/04-data-layer/104-evidence-table.md)
- [ ] [105 — Duplicates table](dev-plan/04-data-layer/105-duplicates-table.md)
- [ ] [106 — Variances table](dev-plan/04-data-layer/106-variances-table.md)
- [ ] [107 — Meeting tables](dev-plan/04-data-layer/107-meetings-tables.md)
- [ ] [108 — Exports table](dev-plan/04-data-layer/108-exports-table.md)
- [ ] [109 — Merge session and conflict tables](dev-plan/04-data-layer/109-merge-tables.md)
- [ ] [110 — Version vector table](dev-plan/04-data-layer/110-sync-state-table.md)
- [ ] [111 — Repository interfaces](dev-plan/04-data-layer/111-repository-interfaces.md)
- [ ] [112 — Test fixtures and object factories](dev-plan/04-data-layer/112-test-fixtures.md)
- [ ] [113 — Database integrity check](dev-plan/04-data-layer/113-db-integrity-check.md)
- [ ] [114 — Optional database encryption](dev-plan/04-data-layer/114-db-encryption.md)

### 05 — File storage

*0 of 12 complete.*

- [ ] [115 — Storage root resolution](dev-plan/05-file-storage/115-storage-root.md)
- [ ] [116 — Project folder service](dev-plan/05-file-storage/116-project-folder-service.md)
- [ ] [117 — Path and name sanitiser](dev-plan/05-file-storage/117-path-sanitizer.md)
- [ ] [118 — Context-based photo path builder](dev-plan/05-file-storage/118-photo-path-builder.md)
- [ ] [119 — Safe file writer](dev-plan/05-file-storage/119-file-writer.md)
- [ ] [120 — Relocate files when context changes](dev-plan/05-file-storage/120-file-relocation.md)
- [ ] [121 — Thumbnail cache](dev-plan/05-file-storage/121-thumbnail-cache.md)
- [ ] [122 — Compressed upload copy](dev-plan/05-file-storage/122-compressed-copy.md)
- [ ] [123 — Cache cleanup](dev-plan/05-file-storage/123-cache-cleanup.md)
- [ ] [124 — Storage headroom guard](dev-plan/05-file-storage/124-storage-guard.md)
- [ ] [125 — Orphan file scanner](dev-plan/05-file-storage/125-orphan-scanner.md)
- [ ] [126 — Imported file validation](dev-plan/05-file-storage/126-file-validation.md)

### 06 — Application shell

*0 of 7 complete.*

- [ ] [127 — Router setup](dev-plan/06-app-shell/127-router-setup.md)
- [ ] [128 — Adaptive navigation shell](dev-plan/06-app-shell/128-nav-shell.md)
- [ ] [129 — Route guards](dev-plan/06-app-shell/129-route-guards.md)
- [ ] [130 — First-run flow](dev-plan/06-app-shell/130-first-run.md)
- [ ] [131 — Global status line](dev-plan/06-app-shell/131-status-line.md)
- [ ] [132 — Offline banner wiring](dev-plan/06-app-shell/132-offline-banner.md)
- [ ] [133 — Global error and crash recovery screen](dev-plan/06-app-shell/133-global-error-page.md)

### 07 — Account and settings

*0 of 9 complete.*

- [ ] [134 — Operator profile](dev-plan/07-account-and-settings/134-operator-profile.md)
- [ ] [135 — Settings screen shell](dev-plan/07-account-and-settings/135-settings-shell.md)
- [ ] [136 — Settings store](dev-plan/07-account-and-settings/136-settings-store.md)
- [ ] [137 — Capture settings screen](dev-plan/07-account-and-settings/137-capture-settings.md)
- [ ] [138 — Storage settings screen](dev-plan/07-account-and-settings/138-storage-settings.md)
- [ ] [139 — App lock with PIN](dev-plan/07-account-and-settings/139-app-lock-pin.md)
- [ ] [140 — Biometric unlock](dev-plan/07-account-and-settings/140-app-lock-biometric.md)
- [ ] [141 — Manual offline mode switch](dev-plan/07-account-and-settings/141-offline-switch.md)
- [ ] [142 — About and licences](dev-plan/07-account-and-settings/142-about-screen.md)

### 08 — Projects

*0 of 10 complete.*

- [ ] [143 — Project domain model and repository](dev-plan/08-projects/143-project-model.md)
- [ ] [144 — Project list screen](dev-plan/08-projects/144-project-list.md)
- [ ] [145 — Create a project](dev-plan/08-projects/145-project-create.md)
- [ ] [146 — Open a project and current-project provider](dev-plan/08-projects/146-project-open.md)
- [ ] [147 — Project home screen](dev-plan/08-projects/147-project-home.md)
- [ ] [148 — Edit project details](dev-plan/08-projects/148-project-edit.md)
- [ ] [149 — Per-project settings](dev-plan/08-projects/149-project-settings.md)
- [ ] [150 — Archive and unarchive a project](dev-plan/08-projects/150-project-archive.md)
- [ ] [151 — Delete a project](dev-plan/08-projects/151-project-delete.md)
- [ ] [152 — Duplicate a project structure](dev-plan/08-projects/152-project-duplicate.md)

### 09 — Templates

*0 of 33 complete.*

- [ ] [153 — Template domain model and repository](dev-plan/09-templates/153-template-model.md)
- [ ] [154 — Field type registry](dev-plan/09-templates/154-field-type-registry.md)
- [ ] [155 — Shipped template asset format and atomicity checker](dev-plan/09-templates/155-shipped-templates-assets.md)
- [ ] [156 — Author the shipped template library](dev-plan/09-templates/156-shipped-template-library.md)
- [ ] [157 — Shipped template loader](dev-plan/09-templates/157-shipped-template-loader.md)
- [ ] [158 — Template list screen](dev-plan/09-templates/158-template-list.md)
- [ ] [159 — Create a template from the library](dev-plan/09-templates/159-template-create-from-shipped.md)
- [ ] [160 — Create a blank template](dev-plan/09-templates/160-template-create-blank.md)
- [ ] [161 — Duplicate a template](dev-plan/09-templates/161-template-duplicate.md)
- [ ] [162 — Field list editor](dev-plan/09-templates/162-field-list-editor.md)
- [ ] [163 — Add a field: label, type, required](dev-plan/09-templates/163-field-add-basic.md)
- [ ] [164 — Field advanced attributes](dev-plan/09-templates/164-field-advanced-attributes.md)
- [ ] [165 — Required columns screen](dev-plan/09-templates/165-required-columns-screen.md)
- [ ] [166 — Reorder fields](dev-plan/09-templates/166-field-reorder.md)
- [ ] [167 — Delete a field](dev-plan/09-templates/167-field-delete.md)
- [ ] [168 — Field validation rules editor](dev-plan/09-templates/168-field-validation-editor.md)
- [ ] [169 — Choice options editor](dev-plan/09-templates/169-field-options-editor.md)
- [ ] [170 — Field editor widget](dev-plan/09-templates/170-field-editor-inline.md)
- [ ] [171 — Identity field selection](dev-plan/09-templates/171-identity-fields.md)
- [ ] [172 — Output column mapping](dev-plan/09-templates/172-output-column-mapping.md)
- [ ] [173 — Template version bump](dev-plan/09-templates/173-template-versioning.md)
- [ ] [174 — Migrate records to a new template version](dev-plan/09-templates/174-template-migration-preview.md)
- [ ] [175 — Export a template as JSON](dev-plan/09-templates/175-template-export-json.md)
- [ ] [176 — Import a template from JSON](dev-plan/09-templates/176-template-import-json.md)
- [ ] [177 — Read a spreadsheet workbook](dev-plan/09-templates/177-xlsx-read-workbook.md)
- [ ] [178 — Detect the header row](dev-plan/09-templates/178-xlsx-header-detection.md)
- [ ] [179 — Infer field types from columns](dev-plan/09-templates/179-xlsx-type-inference.md)
- [ ] [180 — Confirm the column mapping](dev-plan/09-templates/180-xlsx-mapping-screen.md)
- [ ] [181 — Create a template from the mapping](dev-plan/09-templates/181-xlsx-template-create.md)
- [ ] [182 — Import predefined rows](dev-plan/09-templates/182-predefined-rows-import.md)
- [ ] [183 — Row alias editor](dev-plan/09-templates/183-row-aliases-editor.md)
- [ ] [184 — Predefined row checklist view](dev-plan/09-templates/184-checklist-progress.md)
- [ ] [185 — Detection profile editor](dev-plan/09-templates/185-template-detection-profile.md)

### 10 — Reference data

*0 of 16 complete.*

- [ ] [186 — Reference dataset model and repository](dev-plan/10-reference-data/186-dataset-model.md)
- [ ] [187 — Import a dataset from CSV](dev-plan/10-reference-data/187-dataset-import-csv.md)
- [ ] [188 — Import a dataset from a spreadsheet](dev-plan/10-reference-data/188-dataset-import-xlsx.md)
- [ ] [189 — Import a dataset from JSON](dev-plan/10-reference-data/189-dataset-import-json.md)
- [ ] [190 — Choose the key column](dev-plan/10-reference-data/190-dataset-key-selection.md)
- [ ] [191 — Dataset list screen](dev-plan/10-reference-data/191-dataset-list.md)
- [ ] [192 — Browse and search dataset rows](dev-plan/10-reference-data/192-dataset-browser.md)
- [ ] [193 — Edit a dataset row](dev-plan/10-reference-data/193-dataset-row-edit.md)
- [ ] [194 — Add a row from capture](dev-plan/10-reference-data/194-dataset-add-row.md)
- [ ] [195 — Configure a lookup field](dev-plan/10-reference-data/195-lookup-binding-config.md)
- [ ] [196 — Exact and case-insensitive matching](dev-plan/10-reference-data/196-lookup-exact-match.md)
- [ ] [197 — Fuzzy matching](dev-plan/10-reference-data/197-lookup-fuzzy-match.md)
- [ ] [198 — Multiple match picker](dev-plan/10-reference-data/198-lookup-multi-match.md)
- [ ] [199 — Apply a lookup prefill](dev-plan/10-reference-data/199-lookup-prefill-apply.md)
- [ ] [200 — Break the link on edit](dev-plan/10-reference-data/200-lookup-unlink.md)
- [ ] [201 — Export a dataset](dev-plan/10-reference-data/201-dataset-export.md)

### 11 — Context

*0 of 14 complete.*

- [ ] [202 — Context domain model and repository](dev-plan/11-context/202-context-model.md)
- [ ] [203 — Define the context hierarchy](dev-plan/11-context/203-context-hierarchy-editor.md)
- [ ] [204 — Persist and restore context](dev-plan/11-context/204-context-persistence.md)
- [ ] [205 — Context bar widget](dev-plan/11-context/205-context-bar.md)
- [ ] [206 — Context level picker](dev-plan/11-context/206-context-level-picker.md)
- [ ] [207 — Cascade clearing](dev-plan/11-context/207-context-cascade-clear.md)
- [ ] [208 — Apply context to a new record](dev-plan/11-context/208-context-apply-to-record.md)
- [ ] [209 — Per-record override](dev-plan/11-context/209-context-per-record-override.md)
- [ ] [210 — Pinned non-hierarchical fields](dev-plan/11-context/210-context-pinned-fields.md)
- [ ] [211 — Save a context preset](dev-plan/11-context/211-context-presets-save.md)
- [ ] [212 — Apply a context preset](dev-plan/11-context/212-context-presets-apply.md)
- [ ] [213 — Optional auto-clear timer](dev-plan/11-context/213-context-auto-clear.md)
- [ ] [214 — Optional movement prompt](dev-plan/11-context/214-context-gps-prompt.md)
- [ ] [215 — Wire context into the folder path](dev-plan/11-context/215-context-folder-wiring.md)

### 12 — Capture

*0 of 45 complete.*

- [ ] [216 — Capture session model](dev-plan/12-capture/216-capture-session-model.md)
- [ ] [217 — Capture session controller](dev-plan/12-capture/217-capture-session-controller.md)
- [ ] [218 — Capture screen shell](dev-plan/12-capture/218-capture-screen.md)
- [ ] [219 — Camera permission flow](dev-plan/12-capture/219-camera-permission-flow.md)
- [ ] [220 — Camera preview](dev-plan/12-capture/220-camera-preview.md)
- [ ] [221 — Shutter and immediate save](dev-plan/12-capture/221-camera-shutter.md)
- [ ] [222 — Flash, focus, zoom and grid](dev-plan/12-capture/222-camera-controls.md)
- [ ] [223 — Document mode with edge detection](dev-plan/12-capture/223-camera-document-mode.md)
- [ ] [224 — Pick photos from the gallery](dev-plan/12-capture/224-gallery-picker.md)
- [ ] [225 — Attach documents](dev-plan/12-capture/225-document-picker.md)
- [ ] [226 — Extract PDF pages as evidence](dev-plan/12-capture/226-pdf-page-extraction.md)
- [ ] [227 — Photo tray](dev-plan/12-capture/227-photo-tray.md)
- [ ] [228 — Full-screen photo viewer](dev-plan/12-capture/228-photo-viewer.md)
- [ ] [229 — Reorder photos](dev-plan/12-capture/229-photo-reorder.md)
- [ ] [230 — Delete a photo](dev-plan/12-capture/230-photo-delete.md)
- [ ] [231 — Retake a photo](dev-plan/12-capture/231-photo-retake.md)
- [ ] [232 — Rotate a photo](dev-plan/12-capture/232-photo-rotate.md)
- [ ] [233 — Crop a photo](dev-plan/12-capture/233-photo-crop.md)
- [ ] [234 — Assign a photo type](dev-plan/12-capture/234-photo-type-assign.md)
- [ ] [235 — Multi-select mode](dev-plan/12-capture/235-photo-multi-select.md)
- [ ] [236 — Move photos to another record](dev-plan/12-capture/236-photo-move-record.md)
- [ ] [237 — Record caption field](dev-plan/12-capture/237-record-caption.md)
- [ ] [238 — Per-photo caption](dev-plan/12-capture/238-photo-caption.md)
- [ ] [239 — Caption scope: this, selected, all](dev-plan/12-capture/239-caption-scope-selector.md)
- [ ] [240 — Append or replace](dev-plan/12-capture/240-caption-apply-mode.md)
- [ ] [241 — Microphone permission flow](dev-plan/12-capture/241-voice-permission.md)
- [ ] [242 — Speech-to-text service](dev-plan/12-capture/242-stt-service.md)
- [ ] [243 — Voice input button](dev-plan/12-capture/243-voice-input-button.md)
- [ ] [244 — Preserve the raw transcript](dev-plan/12-capture/244-transcript-preservation.md)
- [ ] [245 — Long-form audio recording](dev-plan/12-capture/245-audio-recording.md)
- [ ] [246 — Barcode and QR scanner](dev-plan/12-capture/246-barcode-scanner.md)
- [ ] [247 — Continuous scan mode](dev-plan/12-capture/247-barcode-continuous.md)
- [ ] [248 — Identifier-first lookup](dev-plan/12-capture/248-identifier-lookup.md)
- [ ] [249 — Automatic field application](dev-plan/12-capture/249-auto-fields.md)
- [ ] [250 — Per-project record numbering](dev-plan/12-capture/250-record-number-sequence.md)
- [ ] [251 — Optional GPS capture](dev-plan/12-capture/251-gps-capture.md)
- [ ] [252 — Inline template fields on capture](dev-plan/12-capture/252-inline-field-entry.md)
- [ ] [253 — Capture and analyse](dev-plan/12-capture/253-save-immediate.md)
- [ ] [254 — Save raw, analyse later](dev-plan/12-capture/254-save-raw.md)
- [ ] [255 — Reset for the next item](dev-plan/12-capture/255-capture-reset.md)
- [ ] [256 — Crash recovery for an unsaved session](dev-plan/12-capture/256-capture-recovery.md)
- [ ] [257 — Image quality warnings](dev-plan/12-capture/257-image-quality-check.md)
- [ ] [258 — Rapid capture mode](dev-plan/12-capture/258-rapid-mode.md)
- [ ] [259 — Storage guard in capture](dev-plan/12-capture/259-capture-storage-guard.md)
- [ ] [260 — Choose or pin a template](dev-plan/12-capture/260-template-pick-on-capture.md)

### 13 — Processing

*0 of 39 complete.*

- [ ] [261 — Processing job model and repository](dev-plan/13-processing/261-job-model.md)
- [ ] [262 — Queue service](dev-plan/13-processing/262-job-queue.md)
- [ ] [263 — Job runner](dev-plan/13-processing/263-job-runner.md)
- [ ] [264 — Retry and backoff](dev-plan/13-processing/264-job-retry.md)
- [ ] [265 — Image preprocessing](dev-plan/13-processing/265-image-preprocessing.md)
- [ ] [266 — On-device OCR](dev-plan/13-processing/266-ocr-on-device.md)
- [ ] [267 — Store OCR results](dev-plan/13-processing/267-ocr-result-store.md)
- [ ] [268 — Perceptual hash and duplicate image detection](dev-plan/13-processing/268-perceptual-hash.md)
- [ ] [269 — Identifier pattern extraction](dev-plan/13-processing/269-identifier-extraction.md)
- [ ] [270 — Provider registry and selection](dev-plan/13-processing/270-provider-registry.md)
- [ ] [271 — Device-held API key: the permitted exception](dev-plan/13-processing/271-api-key-entry.md)
- [ ] [272 — Test connection](dev-plan/13-processing/272-provider-test-connection.md)
- [ ] [273 — Data egress preview](dev-plan/13-processing/273-egress-preview.md)
- [ ] [274 — Build the extraction request](dev-plan/13-processing/274-extraction-request.md)
- [ ] [275 — Parse and validate the response](dev-plan/13-processing/275-response-parse.md)
- [ ] [276 — Repair and retry a bad response](dev-plan/13-processing/276-response-repair.md)
- [ ] [277 — Persist raw provider responses](dev-plan/13-processing/277-response-persist.md)
- [ ] [278 — Apply proposals to a record](dev-plan/13-processing/278-proposal-application.md)
- [ ] [279 — Template detection: local signals](dev-plan/13-processing/279-template-detection-heuristics.md)
- [ ] [280 — Template detection: model assist](dev-plan/13-processing/280-template-detection-model.md)
- [ ] [281 — Ask the operator which template](dev-plan/13-processing/281-template-detection-prompt.md)
- [ ] [282 — Normalise units and measures](dev-plan/13-processing/282-normalise-units.md)
- [ ] [283 — Normalise to choice options](dev-plan/13-processing/283-normalise-choices.md)
- [ ] [284 — Normalise dates and numbers](dev-plan/13-processing/284-normalise-dates.md)
- [ ] [285 — Match to a predefined row](dev-plan/13-processing/285-row-matching.md)
- [ ] [286 — Confidence bands](dev-plan/13-processing/286-confidence-banding.md)
- [ ] [287 — Link values to their evidence](dev-plan/13-processing/287-evidence-linking.md)
- [ ] [288 — Record provenance](dev-plan/13-processing/288-provenance-recording.md)
- [ ] [289 — Refine captions](dev-plan/13-processing/289-caption-refinement.md)
- [ ] [290 — No-invention enforcement](dev-plan/13-processing/290-no-invention-guard.md)
- [ ] [291 — Skip the online stage when possible](dev-plan/13-processing/291-skip-online-when-complete.md)
- [ ] [292 — Group images into one request](dev-plan/13-processing/292-batching-and-grouping.md)
- [ ] [293 — Budget guard and request counter](dev-plan/13-processing/293-cost-guard.md)
- [ ] [294 — Processing queue screen](dev-plan/13-processing/294-queue-screen.md)
- [ ] [295 — Process all and process selected](dev-plan/13-processing/295-process-actions.md)
- [ ] [296 — Failed jobs and retry](dev-plan/13-processing/296-failed-jobs-view.md)
- [ ] [297 — Automatic processing when connected](dev-plan/13-processing/297-auto-process-on-connect.md)
- [ ] [298 — Opportunistic on-device OCR](dev-plan/13-processing/298-background-ocr.md)
- [ ] [299 — Processing notifications](dev-plan/13-processing/299-processing-notifications.md)

### 14 — Records

*0 of 15 complete.*

- [ ] [300 — Record domain model and repository](dev-plan/14-records/300-record-model.md)
- [ ] [301 — Record status lifecycle](dev-plan/14-records/301-record-lifecycle.md)
- [ ] [302 — Records list screen](dev-plan/14-records/302-records-list.md)
- [ ] [303 — Search records](dev-plan/14-records/303-records-search.md)
- [ ] [304 — Filter records](dev-plan/14-records/304-records-filters.md)
- [ ] [305 — Sort records](dev-plan/14-records/305-records-sort.md)
- [ ] [306 — Record detail screen](dev-plan/14-records/306-record-detail.md)
- [ ] [307 — Edit a saved record's fields](dev-plan/14-records/307-record-edit-fields.md)
- [ ] [308 — Add and remove photos after save](dev-plan/14-records/308-record-photos-edit.md)
- [ ] [309 — Change a record's template](dev-plan/14-records/309-record-template-change.md)
- [ ] [310 — Record history view](dev-plan/14-records/310-record-history.md)
- [ ] [311 — Delete a record](dev-plan/14-records/311-record-delete.md)
- [ ] [312 — Recycle bin](dev-plan/14-records/312-recycle-bin.md)
- [ ] [313 — Retention purge job](dev-plan/14-records/313-purge-job.md)
- [ ] [314 — Bulk actions on records](dev-plan/14-records/314-record-bulk-actions.md)

### 15 — Data quality

*0 of 20 complete.*

- [ ] [315 — Validation engine](dev-plan/15-data-quality/315-validation-engine.md)
- [ ] [316 — Field validators](dev-plan/15-data-quality/316-field-validators.md)
- [ ] [317 — Record validators](dev-plan/15-data-quality/317-record-validators.md)
- [ ] [318 — Validation display](dev-plan/15-data-quality/318-validation-display.md)
- [ ] [319 — Identity hash computation](dev-plan/15-data-quality/319-identity-hash.md)
- [ ] [320 — Duplicate detection service](dev-plan/15-data-quality/320-duplicate-detection.md)
- [ ] [321 — Duplicate prompt on save](dev-plan/15-data-quality/321-duplicate-prompt.md)
- [ ] [322 — Duplicate comparison view](dev-plan/15-data-quality/322-duplicate-compare.md)
- [ ] [323 — Override an existing record](dev-plan/15-data-quality/323-duplicate-override.md)
- [ ] [324 — Merge fields between duplicates](dev-plan/15-data-quality/324-duplicate-merge-fields.md)
- [ ] [325 — Keep both and link](dev-plan/15-data-quality/325-duplicate-keep-both.md)
- [ ] [326 — Duplicates review screen](dev-plan/15-data-quality/326-duplicates-screen.md)
- [ ] [327 — Detect source conflicts](dev-plan/15-data-quality/327-source-conflict-detection.md)
- [ ] [328 — Resolve a source conflict](dev-plan/15-data-quality/328-source-conflict-ui.md)
- [ ] [329 — Verification mode switch](dev-plan/15-data-quality/329-verification-mode.md)
- [ ] [330 — Prefill from the register](dev-plan/15-data-quality/330-verification-prefill.md)
- [ ] [331 — Compute variance](dev-plan/15-data-quality/331-variance-computation.md)
- [ ] [332 — Variance screen](dev-plan/15-data-quality/332-variance-screen.md)
- [ ] [333 — Missing and not-found reporting](dev-plan/15-data-quality/333-missing-items.md)
- [ ] [334 — Project quality summary](dev-plan/15-data-quality/334-quality-summary.md)

### 16 — Review

*0 of 10 complete.*

- [ ] [335 — Review screen](dev-plan/16-review/335-review-screen.md)
- [ ] [336 — Attention-first field ordering](dev-plan/16-review/336-attention-ordering.md)
- [ ] [337 — Raw and refined toggle](dev-plan/16-review/337-raw-refined-toggle.md)
- [ ] [338 — Evidence viewer](dev-plan/16-review/338-evidence-viewer.md)
- [ ] [339 — Confidence display](dev-plan/16-review/339-confidence-display.md)
- [ ] [340 — Not detected affordances](dev-plan/16-review/340-not-detected-affordance.md)
- [ ] [341 — Mark a field verified](dev-plan/16-review/341-verify-field.md)
- [ ] [342 — Approve and next](dev-plan/16-review/342-approve-record.md)
- [ ] [343 — Re-analyse a record](dev-plan/16-review/343-reanalyse-record.md)
- [ ] [344 — Batch review flow](dev-plan/16-review/344-batch-review.md)

### 17 — Meetings

*0 of 14 complete.*

- [ ] [345 — Meeting template and model](dev-plan/17-meetings/345-meeting-template.md)
- [ ] [346 — Create a meeting](dev-plan/17-meetings/346-meeting-create.md)
- [ ] [347 — Agenda items editor](dev-plan/17-meetings/347-agenda-editor.md)
- [ ] [348 — Attendees editor](dev-plan/17-meetings/348-attendee-editor.md)
- [ ] [349 — Attendance sheet photo](dev-plan/17-meetings/349-attendance-photo.md)
- [ ] [350 — Read the attendance sheet](dev-plan/17-meetings/350-attendance-ocr.md)
- [ ] [351 — Match attendees to staff data](dev-plan/17-meetings/351-attendee-matching.md)
- [ ] [352 — Record the meeting](dev-plan/17-meetings/352-meeting-audio.md)
- [ ] [353 — Transcribe the recording](dev-plan/17-meetings/353-meeting-transcription.md)
- [ ] [354 — Refine the minutes](dev-plan/17-meetings/354-minutes-refinement.md)
- [ ] [355 — Decisions editor](dev-plan/17-meetings/355-decisions-editor.md)
- [ ] [356 — Action items editor](dev-plan/17-meetings/356-actions-editor.md)
- [ ] [357 — Meeting attachments](dev-plan/17-meetings/357-meeting-attachments.md)
- [ ] [358 — Meeting review and approval](dev-plan/17-meetings/358-meeting-review.md)

### 18 — Export

*0 of 30 complete.*

- [ ] [359 — Export request model](dev-plan/18-export/359-export-model.md)
- [ ] [360 — Export scope selection](dev-plan/18-export/360-export-scope.md)
- [ ] [361 — Column and extras options](dev-plan/18-export/361-export-options.md)
- [ ] [362 — Pre-export validation](dev-plan/18-export/362-export-validation-gate.md)
- [ ] [363 — Export value formatter](dev-plan/18-export/363-value-formatter.md)
- [ ] [364 — Photo naming service](dev-plan/18-export/364-photo-naming-service.md)
- [ ] [365 — Rename photos when identity is known](dev-plan/18-export/365-photo-rename-on-identity.md)
- [ ] [366 — XLSX writer core](dev-plan/18-export/366-xlsx-writer.md)
- [ ] [367 — Write into a copy of the original workbook](dev-plan/18-export/367-xlsx-template-copy.md)
- [ ] [368 — Write into predefined rows](dev-plan/18-export/368-xlsx-predefined-rows.md)
- [ ] [369 — Raw and refined column pairs](dev-plan/18-export/369-xlsx-raw-refined-columns.md)
- [ ] [370 — One sheet per template](dev-plan/18-export/370-xlsx-multi-sheet.md)
- [ ] [371 — Photo reference modes](dev-plan/18-export/371-xlsx-photo-references.md)
- [ ] [372 — Photo index sheet](dev-plan/18-export/372-photo-index-sheet.md)
- [ ] [373 — CSV writer](dev-plan/18-export/373-csv-writer.md)
- [ ] [374 — JSON writer](dev-plan/18-export/374-json-writer.md)
- [ ] [375 — Data dictionary writer](dev-plan/18-export/375-data-dictionary.md)
- [ ] [376 — PDF engine and shared layout](dev-plan/18-export/376-pdf-engine.md)
- [ ] [377 — Record report](dev-plan/18-export/377-pdf-record-report.md)
- [ ] [378 — Project summary report](dev-plan/18-export/378-pdf-summary-report.md)
- [ ] [379 — Variance report](dev-plan/18-export/379-pdf-variance-report.md)
- [ ] [380 — Meeting minutes PDF](dev-plan/18-export/380-pdf-minutes.md)
- [ ] [381 — ZIP data package](dev-plan/18-export/381-zip-package.md)
- [ ] [382 — Export manifest](dev-plan/18-export/382-export-manifest.md)
- [ ] [383 — Export screen](dev-plan/18-export/383-export-screen.md)
- [ ] [384 — Export progress and cancellation](dev-plan/18-export/384-export-progress.md)
- [ ] [385 — Export history](dev-plan/18-export/385-export-history.md)
- [ ] [386 — Export versioning and folders](dev-plan/18-export/386-export-versioning.md)
- [ ] [387 — Share an export](dev-plan/18-export/387-export-share.md)
- [ ] [522 — Inspection report PDF](dev-plan/18-export/522-pdf-inspection-report.md)

### 19 — Bundles and merge

*0 of 24 complete.*

- [ ] [388 — Bundle format and manifest model](dev-plan/19-bundles-and-merge/388-bundle-format.md)
- [ ] [389 — Bundle writer](dev-plan/19-bundles-and-merge/389-bundle-writer.md)
- [ ] [390 — Bundle scope options](dev-plan/19-bundles-and-merge/390-bundle-scope.md)
- [ ] [391 — Optional bundle encryption](dev-plan/19-bundles-and-merge/391-bundle-encryption.md)
- [ ] [392 — Exclude secrets from bundles](dev-plan/19-bundles-and-merge/392-bundle-secret-exclusion.md)
- [ ] [393 — Bundle reader and validation](dev-plan/19-bundles-and-merge/393-bundle-reader.md)
- [ ] [394 — Import as a new project](dev-plan/19-bundles-and-merge/394-bundle-import-new.md)
- [ ] [395 — Version vector service](dev-plan/19-bundles-and-merge/395-version-vector-service.md)
- [ ] [396 — Tombstone propagation](dev-plan/19-bundles-and-merge/396-tombstone-merge.md)
- [ ] [397 — Entity-level merge](dev-plan/19-bundles-and-merge/397-merge-entity-level.md)
- [ ] [398 — Field-level merge](dev-plan/19-bundles-and-merge/398-merge-field-level.md)
- [ ] [399 — Automatic settlement rules](dev-plan/19-bundles-and-merge/399-merge-auto-rules.md)
- [ ] [400 — Merge photos by content hash](dev-plan/19-bundles-and-merge/400-merge-photos.md)
- [ ] [401 — Merge templates](dev-plan/19-bundles-and-merge/401-merge-templates.md)
- [ ] [402 — Merge reference datasets](dev-plan/19-bundles-and-merge/402-merge-reference.md)
- [ ] [403 — Relabel colliding record numbers](dev-plan/19-bundles-and-merge/403-merge-record-numbers.md)
- [ ] [404 — Merge preview screen](dev-plan/19-bundles-and-merge/404-merge-preview.md)
- [ ] [405 — Conflict resolution screen](dev-plan/19-bundles-and-merge/405-conflict-screen.md)
- [ ] [406 — Bulk conflict resolution](dev-plan/19-bundles-and-merge/406-conflict-bulk.md)
- [ ] [407 — Apply the merge atomically](dev-plan/19-bundles-and-merge/407-merge-apply.md)
- [ ] [408 — Merge history](dev-plan/19-bundles-and-merge/408-merge-history.md)
- [ ] [409 — Undo a merge](dev-plan/19-bundles-and-merge/409-merge-undo.md)
- [ ] [410 — Post-merge duplicate scan](dev-plan/19-bundles-and-merge/410-post-merge-duplicates.md)
- [ ] [411 — Share and receive bundles](dev-plan/19-bundles-and-merge/411-bundle-share.md)

### 20 — Data import

*0 of 6 complete.*

- [ ] [412 — Import entry point](dev-plan/20-data-import/412-import-entry.md)
- [ ] [413 — Map spreadsheet columns to template fields](dev-plan/20-data-import/413-import-records-mapping.md)
- [ ] [414 — Create records from rows](dev-plan/20-data-import/414-import-records-create.md)
- [ ] [415 — Duplicate check during import](dev-plan/20-data-import/415-import-duplicate-check.md)
- [ ] [416 — Import summary](dev-plan/20-data-import/416-import-summary.md)
- [ ] [417 — Import as a verification register](dev-plan/20-data-import/417-import-as-register.md)

### 21 — Cloud upload

*0 of 11 complete.*

- [ ] [418 — Cloud destination model](dev-plan/21-cloud-upload/418-destination-model.md)
- [ ] [419 — Destinations screen](dev-plan/21-cloud-upload/419-destination-list.md)
- [ ] [420 — Amazon S3 and compatible stores](dev-plan/21-cloud-upload/420-destination-s3.md)
- [ ] [421 — Google Drive](dev-plan/21-cloud-upload/421-destination-google-drive.md)
- [ ] [422 — OneDrive and Dropbox](dev-plan/21-cloud-upload/422-destination-onedrive-dropbox.md)
- [ ] [423 — WebDAV and generic HTTPS](dev-plan/21-cloud-upload/423-destination-webdav.md)
- [ ] [424 — Local or removable folder](dev-plan/21-cloud-upload/424-destination-local-folder.md)
- [ ] [425 — Upload confirmation](dev-plan/21-cloud-upload/425-upload-confirm.md)
- [ ] [426 — Upload with progress and resume](dev-plan/21-cloud-upload/426-upload-runner.md)
- [ ] [427 — Upload history](dev-plan/21-cloud-upload/427-upload-history.md)
- [ ] [428 — Remove a destination](dev-plan/21-cloud-upload/428-destination-remove.md)

### 22 — Privacy and security

*0 of 10 complete.*

- [ ] [429 — What leaves this device](dev-plan/22-privacy-and-security/429-egress-summary-screen.md)
- [ ] [430 — Disable AI per project](dev-plan/22-privacy-and-security/430-ai-disable-per-project.md)
- [ ] [431 — Do not send images](dev-plan/22-privacy-and-security/431-do-not-send-images.md)
- [ ] [432 — Consent flag for personal data](dev-plan/22-privacy-and-security/432-consent-flag.md)
- [ ] [433 — Face blurring on export](dev-plan/22-privacy-and-security/433-face-blur-export.md)
- [ ] [434 — Redact regions before sending](dev-plan/22-privacy-and-security/434-redaction-before-send.md)
- [ ] [435 — GPS consent and control](dev-plan/22-privacy-and-security/435-gps-privacy.md)
- [ ] [436 — Treat imported text as data](dev-plan/22-privacy-and-security/436-untrusted-text-handling.md)
- [ ] [437 — Automated secret leak test](dev-plan/22-privacy-and-security/437-secret-scan-test.md)
- [ ] [438 — Permission minimisation review](dev-plan/22-privacy-and-security/438-permission-minimisation.md)

### 23 — Hardening

*0 of 16 complete.*

- [ ] [439 — Responsive audit](dev-plan/23-hardening/439-responsive-audit.md)
- [ ] [440 — Landscape and foldables](dev-plan/23-hardening/440-orientation-support.md)
- [ ] [441 — Accessibility audit](dev-plan/23-hardening/441-accessibility-audit.md)
- [ ] [442 — Large text audit](dev-plan/23-hardening/442-text-scale-audit.md)
- [ ] [443 — Copy and message review](dev-plan/23-hardening/443-copy-review.md)
- [ ] [444 — Empty-state coverage test](dev-plan/23-hardening/444-empty-states-review.md)
- [ ] [445 — List and image performance](dev-plan/23-hardening/445-list-performance.md)
- [ ] [446 — Database index review](dev-plan/23-hardening/446-db-index-review.md)
- [ ] [447 — Cold start optimisation](dev-plan/23-hardening/447-cold-start.md)
- [ ] [448 — Memory ceiling test](dev-plan/23-hardening/448-memory-review.md)
- [ ] [449 — Background work policy](dev-plan/23-hardening/449-battery-review.md)
- [ ] [450 — Failure injection suite](dev-plan/23-hardening/450-error-recovery-review.md)
- [ ] [451 — Localisation scaffolding](dev-plan/23-hardening/451-localisation-scaffold.md)
- [ ] [452 — App icon, splash and store branding](dev-plan/23-hardening/452-branding-assets.md)
- [ ] [453 — Device matrix runner](dev-plan/23-hardening/453-device-matrix-testing.md)
- [ ] [454 — In-app friction log](dev-plan/23-hardening/454-field-trial.md)

### 24 — The minimal backend

*0 of 49 complete.*

- [ ] [455 — Initialise the backend project](dev-plan/24-backend/455-be-project-init.md)
- [ ] [456 — Lint, format and the verify command](dev-plan/24-backend/456-be-lint-format.md)
- [ ] [457 — Configuration loading and validation](dev-plan/24-backend/457-be-config.md)
- [ ] [458 — Structured logger with redaction](dev-plan/24-backend/458-be-logger.md)
- [ ] [459 — Typed errors and the error envelope](dev-plan/24-backend/459-be-error-model.md)
- [ ] [460 — HTTP server and middleware chain](dev-plan/24-backend/460-be-http-server.md)
- [ ] [461 — Request context and identifiers](dev-plan/24-backend/461-be-request-context.md)
- [ ] [462 — Database connection and pooling](dev-plan/24-backend/462-be-db-connection.md)
- [ ] [463 — Migration runner](dev-plan/24-backend/463-be-migrations.md)
- [ ] [464 — Schema: organisations, users and devices](dev-plan/24-backend/464-be-schema-identity.md)
- [ ] [465 — Schema: projects, members and roles](dev-plan/24-backend/465-be-schema-projects.md)
- [ ] [466 — Schema: relay packages and acknowledgements](dev-plan/24-backend/466-be-schema-relay.md)
- [ ] [467 — Schema: audit and security events](dev-plan/24-backend/467-be-schema-audit.md)
- [ ] [468 — Repository base and transactions](dev-plan/24-backend/468-be-repositories.md)
- [ ] [469 — Password hashing](dev-plan/24-backend/469-be-auth-passwords.md)
- [ ] [470 — Account creation, invitation and password lifecycle](dev-plan/24-backend/470-be-auth-register.md)
- [ ] [471 — Login with rate limiting and lockout](dev-plan/24-backend/471-be-auth-login.md)
- [ ] [472 — Access and refresh tokens](dev-plan/24-backend/472-be-auth-tokens.md)
- [ ] [473 — Authentication middleware](dev-plan/24-backend/473-be-auth-middleware.md)
- [ ] [474 — Device enrolment](dev-plan/24-backend/474-be-device-enrol.md)
- [ ] [475 — Role matrix and permission checks](dev-plan/24-backend/475-be-permissions.md)
- [ ] [476 — Organisation user endpoints](dev-plan/24-backend/476-be-users-api.md)
- [ ] [477 — Project and membership endpoints](dev-plan/24-backend/477-be-projects-api.md)
- [ ] [478 — Relay: accept a package](dev-plan/24-backend/478-be-relay-push.md)
- [ ] [479 — Relay: list and download packages](dev-plan/24-backend/479-be-relay-fetch.md)
- [ ] [480 — Relay: acknowledge and delete](dev-plan/24-backend/480-be-relay-ack.md)
- [ ] [481 — Relay: version vector state](dev-plan/24-backend/481-be-relay-state.md)
- [ ] [482 — Relay package purge job](dev-plan/24-backend/482-be-retention-job.md)
- [ ] [483 — Storage ceilings and reporting](dev-plan/24-backend/483-be-storage-limits.md)
- [ ] [484 — AI provider abstraction](dev-plan/24-backend/484-be-ai-provider.md)
- [ ] [485 — Provider key custody](dev-plan/24-backend/485-be-ai-keys.md)
- [ ] [486 — AI proxy endpoints](dev-plan/24-backend/486-be-ai-proxy.md)
- [ ] [487 — Budgets, quotas and usage](dev-plan/24-backend/487-be-ai-quota.md)
- [ ] [488 — Timeouts, retries and circuit breaker](dev-plan/24-backend/488-be-ai-resilience.md)
- [ ] [489 — Rate limiting](dev-plan/24-backend/489-be-rate-limiting.md)
- [ ] [490 — Audit and security event recording](dev-plan/24-backend/490-be-audit-service.md)
- [ ] [491 — Metrics endpoint](dev-plan/24-backend/491-be-metrics.md)
- [ ] [492 — OpenAPI specification](dev-plan/24-backend/492-be-openapi.md)
- [ ] [493 — Contract tests against the specification](dev-plan/24-backend/493-be-contract-tests.md)
- [ ] [494 — Export and destroy server state](dev-plan/24-backend/494-be-admin-commands.md)
- [ ] [495 — Container, compose and runbook](dev-plan/24-backend/495-be-deployment.md)
- [ ] [496 — Backend pipeline](dev-plan/24-backend/496-be-ci.md)
- [ ] [497 — App: backend connection and enrolment state](dev-plan/24-backend/497-fe-backend-config.md)
- [ ] [498 — App: sign in and enrol](dev-plan/24-backend/498-fe-signin-enrol.md)
- [ ] [499 — App: role-aware affordances](dev-plan/24-backend/499-fe-role-affordances.md)
- [ ] [500 — App: offline authority and cached grants](dev-plan/24-backend/500-fe-offline-authority.md)
- [ ] [501 — App: change relay client](dev-plan/24-backend/501-fe-relay-client.md)
- [ ] [502 — App: relay controls and visibility](dev-plan/24-backend/502-fe-relay-settings.md)
- [ ] [503 — App: route AI through the backend](dev-plan/24-backend/503-fe-ai-proxy-client.md)

### 25 — Testing and release

*0 of 18 complete.*

- [ ] [504 — Unit test harness](dev-plan/25-testing-and-release/504-test-harness-unit.md)
- [ ] [505 — Widget test harness](dev-plan/25-testing-and-release/505-test-harness-widget.md)
- [ ] [506 — Integration test harness](dev-plan/25-testing-and-release/506-test-harness-integration.md)
- [ ] [507 — End-to-end: capture to export](dev-plan/25-testing-and-release/507-e2e-capture-to-export.md)
- [ ] [508 — End-to-end: offline and deferred](dev-plan/25-testing-and-release/508-e2e-offline-deferred.md)
- [ ] [509 — End-to-end: context inheritance](dev-plan/25-testing-and-release/509-e2e-context-inheritance.md)
- [ ] [510 — End-to-end: caption scope](dev-plan/25-testing-and-release/510-e2e-caption-scope.md)
- [ ] [511 — End-to-end: known asset verification](dev-plan/25-testing-and-release/511-e2e-known-asset.md)
- [ ] [512 — End-to-end: duplicate override](dev-plan/25-testing-and-release/512-e2e-duplicate-override.md)
- [ ] [513 — End-to-end: bundle merge](dev-plan/25-testing-and-release/513-e2e-merge.md)
- [ ] [514 — End-to-end: meeting](dev-plan/25-testing-and-release/514-e2e-meeting.md)
- [ ] [515 — End-to-end: every export format](dev-plan/25-testing-and-release/515-e2e-export-formats.md)
- [ ] [516 — Continuous integration pipeline](dev-plan/25-testing-and-release/516-ci-pipeline.md)
- [ ] [517 — Integration tests in the pipeline](dev-plan/25-testing-and-release/517-ci-integration-job.md)
- [ ] [518 — Release build configuration](dev-plan/25-testing-and-release/518-release-build.md)
- [ ] [519 — Release gate program](dev-plan/25-testing-and-release/519-release-checklist.md)
- [ ] [520 — Backlog report generator](dev-plan/25-testing-and-release/520-post-release-backlog.md)
- [ ] [521 — End-to-end: sign in, proxy AI, then go offline](dev-plan/25-testing-and-release/521-e2e-signin-proxy-offline.md)

## Updating this file

1. Finish a task and get its Definition of done fully ticked.
2. Tick the box in the **Checklist**, add a row to **Completed**, and raise anything the task
   surfaced under **Carried decisions**.
3. Update the counts in **Phase progress** and the header, and set the last-updated date.
4. Tick the same task in [dev-plan/INDEX.md](dev-plan/INDEX.md), which carries its own copy of
   the checklist.
