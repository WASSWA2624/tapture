# 001 — Resolve capture, projects, and settings feedback

**Feedback:** FBK0000043, FBK0000044, FBK0000045, FBK0000046, FBK0000047, FBK0000048, FBK0000049, FBK0000050, FBK0000052, FBK0000054, FBK0000055, FBK0000056 · **Work items:** 9 · **Depends on:** none

## Goal

Make capture durable and operational, make project navigation preserve its source, expose template-driven context clearly, and make Projects and Settings concise and useful. Land the shared Flutter outcomes across supported native platforms, compact, medium, and expanded widths, portrait and landscape, light, dark, and outdoor themes, and 200 percent text.

## Run order

| Item | Title | Feedback | Type | Priority | Effort | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| W1 | Wire durable capture saves | FBK0000054 | Defect | P1 | XL | — |
| W2 | Fix shell hierarchy and back navigation | FBK0000043, FBK0000047, FBK0000048, FBK0000052 | Defect | P2 | L | W1 |
| W3 | Apply template context levels and pins | FBK0000048, FBK0000049, FBK0000050 | Defect | P2 | L | W1, W2 |
| W4 | Add reusable project search and filters | FBK0000044 | Gap | P3 | M | W3 |
| W5 | Mark pinned projects in the list | FBK0000045 | Improvement | P3 | S | W4 |
| W6 | Show project association counts | FBK0000046 | Improvement | P3 | M | W3, W5 |
| W7 | Compact the Settings index | FBK0000056 | Improvement | P3 | S | W2, W6 |
| W8 | Attach audio evidence to capture | FBK0000054 | Suggestion | P4 | XL | W1, W3 |
| W9 | Build registry-driven AI settings | FBK0000055 | Suggestion | P4 | L | W7 |

## Decisions

⛔ Stop here. Get an answer to every decision before step 1 of any work item. "Proceed" means the default.

- D1 (W1): What label replaces the ambiguous requested phrase “Save processes”? Options: (a) `Save and process`; (b) the exact phrase `Save processes`. Default: (a), because it is a grammatical action label and matches the existing processing vocabulary.
- D2 (W1): Where should interrupted capture-session state become durable? Options: (a) add a non-destructive Drift `capture_sessions` table in schema v17; (b) use a native project-side JSON file and leave browser recovery unsupported. Default: (a), because Drift already has native and browser backends and gives one restart-safe source of truth.
- D3 (W8): How should audio recording and ownership be added? Options: (a) approve `record: ^7.1.1` under its BSD-3-Clause licence and add a non-destructive schema-v18 `attachment_owners` link table; (b) support imported audio only and add the link table without a recorder dependency. Default: (a), because it delivers the requested in-capture recording while preserving one audio file that can belong to a record and several photos.
- D4 (W9): What does “any provider” mean at the security boundary? Options: (a) every provider and model registered by the organisation or application bootstrap, with the keyless backend proxy as default and device keys limited to explicitly admin-enabled descriptors; (b) arbitrary user-entered provider URLs and models with device-held keys. Default: (a), because it keeps provider-key custody and egress bounded while making the screen data-driven.
- D5 (W7): How far should Settings simplification go? Options: (a) remove Templates, Unprocessed, Language, and Files from the index while retaining every implemented route and deep link; (b) keep every row and add grouping only. Default: (a), because Templates and Unprocessed are operational destinations and Language and Files have no route.

## Rules

- FE-FLOW-01, FE-FLOW-02, FE-FLOW-03, FE-FLOW-06, FE-FLOW-08: use one plan task and branch, record dependency approval, and keep both gates green.
- FE-STR-02, FE-STR-03, FE-STR-04, FE-STR-05, FE-STR-09, FE-STR-10, FE-STR-11: keep routing declared, feature boundaries intact, and platform implementations behind shared interfaces.
- FE-CODE-01, FE-CODE-04, FE-CODE-07, FE-CODE-08, FE-CODE-09, FE-CODE-13: use strict typed models, immutable state, exhaustive states, and generated Drift output.
- FE-STATE-01, FE-STATE-04, FE-STATE-05, FE-STATE-06, FE-STATE-07, FE-STATE-08, FE-STATE-10, FE-STATE-11: Riverpod owns state, durable writes precede success, and failures stay visible and retryable.
- FE-CONS-01, FE-CONS-02, FE-CONS-03, FE-CONS-05, FE-CONS-06, FE-CONS-07, FE-CONS-08, FE-CONS-10, FE-CONS-11: reuse shared widgets, navigation, loading, empty, failure, and destructive patterns.
- FE-THEME-01, FE-THEME-02, FE-THEME-03, FE-THEME-05, FE-THEME-07, FE-THEME-08, FE-THEME-10: use theme tokens and preserve outdoor contrast without adding decorative corner radii.
- FE-RESP-01, FE-RESP-03, FE-RESP-05, FE-RESP-06, FE-RESP-07, FE-RESP-08, FE-RESP-10: verify all size classes, orientations, insets, input modes, and 200 percent text.
- FE-SIMP-01, FE-SIMP-02, FE-SIMP-05, FE-SIMP-06, FE-SIMP-07, FE-SIMP-08, FE-SIMP-09, FE-SIMP-10, FE-SIMP-11, FE-SIMP-12: keep the primary action obvious, disclose advanced controls progressively, and explain unavailable states.
- FE-L10N-01, FE-L10N-04, FE-L10N-05, FE-L10N-07, FE-L10N-08, FE-L10N-09, FE-L10N-10: put every user-facing string and plural in `Copy`.
- FE-A11Y-01, FE-A11Y-02, FE-A11Y-03, FE-A11Y-04, FE-A11Y-05, FE-A11Y-07, FE-A11Y-08, FE-A11Y-09, FE-A11Y-10: label controls and status, preserve focus order, tap targets, contrast, and large text.
- FE-PERF-01, FE-PERF-02, FE-PERF-03, FE-PERF-04, FE-PERF-05, FE-PERF-07, FE-PERF-10: keep rebuilds narrow, list work bounded, and evidence streaming.
- FE-SEC-01, FE-SEC-02, FE-SEC-04, FE-SEC-05, FE-SEC-06, FE-SEC-07, FE-SEC-08, FE-SEC-09, FE-SEC-10, FE-SEC-11: protect secrets, preserve raw evidence, keep offline capture complete, and make egress explicit.
- FE-TEST-01, FE-TEST-02, FE-TEST-03, FE-TEST-05, FE-TEST-06, FE-TEST-07, FE-TEST-09, FE-TEST-10: ship unit, repository, widget, golden, migration, failure, and accessibility coverage with the change.

## Before the work items

1. Record the archive as one hardening task with `cd frontend && dart run tool/new_task.dart 23-hardening resolve-feedback-23092026 "Resolve feedback archive 23092026-1635"` (FE-FLOW-08). Make it depend on tasks 011, 012, 013, and 061, and use its generated number in the dependency allowlist entry from D3.
2. Work on that task's `task/<number>-resolve-feedback-23092026` branch. Do not tick its checklist until every work item and the full Verification section pass (FE-FLOW-01, FE-FLOW-03).

## W1 — Wire durable capture saves

**Feedback:** FBK0000054 · **Type:** Defect · **Priority:** P1 · **Effort:** XL · **After:** —

### Evidence

- FBK0000054: the capture screen reports that both save actions do nothing; `screenshots/FBK0000054.png` shows both actions disabled beneath a photo tray on Android, compact, portrait, dark.
- Root cause: `frontend/lib/features/capture/presentation/capture_screen.dart:154` passes nullable constructor callbacks directly to both buttons, while `frontend/lib/app/router.dart:568` and `frontend/lib/app/router.dart:575` construct the screen without callbacks.
- Root cause: `frontend/lib/features/capture/presentation/capture_controller.dart:17` defaults photos to `_MemoryPhotoRepository`, `:23` defaults session state to `TextStore.memory()`, and `frontend/lib/main.dart:91` supplies neither production override.
- Root cause: `frontend/lib/features/capture/presentation/capture_screen.dart:317` retains selected photo bytes only in widget-local `_bytes`; the database and project file tree never receive those bytes.

### Scope

- Reach: the shared controller and screen on Android, iOS, macOS, Windows, and Linux. Keep the web build at its existing capability level; project-evidence file writes remain excluded because `FileWriter` has no browser implementation.
- Change: `frontend/lib/core/db/app_database.dart`, `migrations.dart`, new `tables/capture_sessions.dart`, capture domain/data/controller/screen files, `frontend/lib/app/router.dart`, `frontend/lib/main.dart`, `frontend/lib/core/copy/copy.dart`, and generated Drift output.
- Change: add `CaptureRecordWriter` in `frontend/lib/features/capture/data/capture_record_writer.dart` as the single transaction boundary for records, photos, captions, raw field values, and frozen context.
- Do not change: original photo bytes, existing OCR/processing stage order, record review semantics, and offline defaults.

### Rules

- FE-STATE-06, FE-STATE-07, FE-SEC-04, FE-SEC-08: one durable source of truth confirms success only after evidence and rows are committed.
- FE-STR-05, FE-STR-11, FE-CODE-13: Drift stays in `data/`, file access stays behind `FileWriter`, and generated code is committed.
- FE-SIMP-01, FE-SIMP-09, FE-L10N-01: actions expose busy, success, and retryable failure states in plain copy.

### Steps

1. Per D2, add the append-only v17 migration and a project-keyed `CaptureSessions` table that stores validated session JSON, update `kSchemaVersion`, `kUpgradeSteps`, `AppDatabase`, and migration tests from v16 with populated rows.
2. Implement a Drift-backed `PhotoRepository` that writes the complete `PhotoDraft` metadata. Route selected bytes through `FileWriter` into the owning project's `photos/` directory, use its hash and byte count, then persist the photo row and session before `CaptureController` emits the new tray state.
3. Replace `TextStore.memory()` in production with Drift capture persistence while retaining memory fakes for tests. Recovery is project-scoped, restart-safe, and removes only the completed session row after a successful save.
4. Implement `CaptureRecordWriter.persist(CaptureSession)` as one Drift transaction: allocate the record, set status `CAPTURED`, attach existing photo rows, insert independent immutable raw captions, insert manual/context `RecordFields.valueRaw`, and freeze the session context JSON. Preserve every `valueRaw` when later processing writes proposals and provenance beside it.
5. Make `CaptureScreen` own non-null save handlers. Save raw calls `CaptureController.saveRaw`; per D1, the second action calls `saveAndAnalyse`, then `ProcessingRepository.enqueue` only after W1's transaction succeeds. Show one busy state and one retryable failure, and reset only session-scoped evidence after success.
6. Wire `PhotoRepository`, capture persistence, `CaptureRecordWriter`, clock, ids, device, storage root, and processing repository in `frontend/lib/main.dart`; keep tests injectable through providers.
7. Add repository tests for photo and session durability, a transaction rollback test at each table boundary, controller restart tests, widget tests for enabled/busy/failure states, and an integration test proving Save raw makes zero network and AI calls while Save and process enqueues exactly one job.
8. Run `cd frontend && dart run tool/verify.dart --fast` and keep it green.

### Acceptance criteria

- [ ] A captured photo exists under the project tree and in `photos` before it appears as durably saved in the tray.
- [ ] Save raw creates one complete `CAPTURED` record with photos, raw captions, raw typed values, and frozen context, with zero processing and zero egress.
- [ ] Save and process creates the same raw record, enqueues one processing job, and leaves raw values unchanged when OCR and AI proposals are stored.
- [ ] Restarting restores each project's interrupted session without mixing project state; a completed save clears only that session.
- [ ] A file, database, and enqueue failure never reports success, never loses committed raw evidence, and exposes one retry action.
- [ ] The two action labels and semantics remain readable at compact, medium, and expanded widths and at 200 percent text.

## W2 — Fix shell hierarchy and back navigation

**Feedback:** FBK0000043, FBK0000047, FBK0000048, FBK0000052 · **Type:** Defect · **Priority:** P2 · **Effort:** L · **After:** W1

### Evidence

- FBK0000043: four screenshots show Projects, Capture, Records, and Settings as text-only root titles and ask for correct back behavior. Android, compact, portrait, dark.
- FBK0000047 and FBK0000048: project home and Context screenshots show only a generic title instead of route and context hierarchy.
- FBK0000052: Back can land on Settings. `frontend/lib/features/projects/presentation/project_home_screen.dart:162` opens global `/more/templates`, whose route is nested beneath Settings; `frontend/test/app/router_test.dart:258` currently asserts that Settings sits beneath Templates.
- Root cause: `frontend/lib/app/widgets/status_line.dart:81` renders only a back control plus one text title; `frontend/lib/app/shell_title.dart:87` collapses every project-scoped path to the project name.

### Scope

- Reach: shared shell navigation on every platform, compact, medium, and expanded widths, portrait and landscape, light, dark, and outdoor themes, and 200 percent text. No applicable surface is excluded.
- Change: `frontend/lib/app/nav_shell.dart`, `shell_title.dart`, `router.dart`, `widgets/status_line.dart`, a new app-level shell-destination metadata file, project home navigation, `Copy`, and shell/router/status tests.
- Do not change: route URLs already used by Settings, deep-link compatibility, the four root destinations, and per-project state restoration.

### Rules

- FE-STR-02, FE-CONS-01, FE-CONS-02: one declared route table and one shared title/destination model drive icons, breadcrumbs, and back behavior.
- FE-RESP-03, FE-RESP-05, FE-A11Y-02, FE-A11Y-03, FE-A11Y-04: the header reflows without hiding meaning and exposes a logical semantic path.
- FE-TEST-05, FE-TEST-09: test direct links, source-preserving back, Android system back, and large-text layouts.

### Steps

1. Extract the four shell destinations into one app-level immutable metadata source containing path, label, selected icon, and unselected icon; make `NavShell` and `StatusLine` consume it.
2. Add a small root icon before each root title. Preserve the existing back control on non-root screens and label every icon semantically through `Copy` and `MaterialLocalizations`.
3. Extend `ShellTitle` with route-aware breadcrumb segments. Project descendants render `Projects › <project name> › <screen>` and Context values remain in `ContextBar`; Settings descendants render `Settings › <screen>`.
4. Add `AppRoutes.projectTemplates(projectId)` and a project-branch Templates route. Open Context and project Templates with `push` from project home, while the global Settings Templates route remains available and returns to Settings.
5. Make visible Back and platform system Back pop the actual navigation stack first. Use `ShellTitle.parentOf` only for a direct deep link with no history, and reset a tapped top-level destination to its root so a stale Settings child cannot reappear.
6. Update router, shell, and status-line tests for project home → Templates → Back, Settings → Templates → Back, project home → Context → Back, all four root icons, deep-link fallback, and system Back at 400, 800, and 1200 dp with 200 percent text.
7. Run `cd frontend && dart run tool/verify.dart --fast` and keep it green.

### Acceptance criteria

- [ ] Projects, Capture, Records, and Settings each show the same icon used by navigation and expose one accessible title.
- [ ] Every project descendant shows the project hierarchy and its specific screen name without replacing the context-value bar.
- [ ] Back from project Templates and Context returns to the exact project screen that opened them; Back from Settings Templates returns to Settings.
- [ ] Platform system Back and the visible Back button produce the same route result.
- [ ] Direct deep links have one deterministic parent and never land on an unrelated branch.
- [ ] The header has no overflow, no clipped actionable label, and no duplicate app bar across the required widths, orientations, themes, and 200 percent text.

## W3 — Apply template context levels and pins

**Feedback:** FBK0000048, FBK0000049, FBK0000050 · **Type:** Defect · **Priority:** P2 · **Effort:** L · **After:** W1, W2

### Evidence

- FBK0000048: the Context screenshot asks for ordered broad-to-narrow levels from template fields and automatic reuse of broader values during capture.
- FBK0000049: Add level appears to do nothing even with project templates. `frontend/lib/features/context/presentation/context_hierarchy_screen.dart:165` swallows template-load failure and `:183` silently returns when no field is available.
- FBK0000050: the pin sheet says no stickable fields and does not explain relevance. The mechanism exists: `frontend/lib/features/context/presentation/pinned_fields_sheet.dart:126` loads stickable fields, and `frontend/test/features/context/presentation/context_screens_test.dart:359` proves a pin saves.
- Existing capability: `frontend/lib/features/templates/domain/field_def.dart:53` already stores `stickable` and `contextLevel`; `frontend/lib/features/templates/presentation/field_advanced_section.dart:168` already exposes both controls.

### Scope

- Reach: shared template, context, and capture code on every platform and size class. Verify context layout across portrait and landscape, light, dark, and outdoor themes, and 200 percent text. No applicable surface is excluded.
- Change: add a pure template-context proposal helper, update context hierarchy and pinned-field presentation, expose pin/level metadata in template field rows, synchronize current context into capture sessions, and add `Copy` keys and tests.
- Do not change: stored `FieldDef.contextLevel` and `stickable` wire names, saved project hierarchy order without explicit user action, context cascade rules, and immutable record snapshots.

### Rules

- FE-STATE-05, FE-STATE-06, FE-STATE-07: derive proposals from one template source and persist project hierarchy before confirmation.
- FE-SIMP-05, FE-SIMP-07, FE-SIMP-09, FE-CONS-06: explain advanced context controls, empty states, and failures instead of silently returning.
- FE-SEC-08, FE-SEC-09: carry context forward without rewriting older records and audit later overrides beside raw values.

### Steps

1. Add a pure `TemplateContextProposal` helper that combines project-owned template fields, keeps positive `contextLevel` values, detects duplicate level numbers and conflicting field keys, and returns stable broad-to-narrow proposals sorted by level then template field order.
2. Show proposed levels separately when the saved hierarchy is empty, with one `Use template levels` action. Add level opens a sheet even when empty, lists declared fields first with `Level N` subtitles, lists remaining eligible fields after them, and renders explicit loading, no-template, no-field, conflict, and failure states.
3. Render saved rows as `Level 1`, `Level 2`, through `Level n` with label and field key. Keep drag order authoritative after save and renumber contiguously after reordering and removal.
4. Replace remaining user-facing “stickable” wording with “pinned context”. Give the empty pin state an action to W2's project Templates route, show pin relevance copy, and mark pinnable and hierarchy fields in template field rows without exposing raw implementation terms.
5. At capture-session creation and context change, merge current level values and pinned values into `CaptureSession.contextSnapshot` through the controller. W1's writer stores them as source `CONTEXT`; `CaptureReset` retains them for the next item while `ContextCascade` clears narrower values after a broader change.
6. Add pure proposal tests, repository failure tests, context-screen widget tests for proposals and all empty states, template-field metadata tests, and a capture integration test proving a Level 2 capture carries the current Level 1 value into the record without rewriting a prior record.
7. Run `cd frontend && dart run tool/verify.dart --fast` and keep it green.

### Acceptance criteria

- [ ] Template fields marked with context levels produce a stable Level 1 through Level n proposal without a new schema change.
- [ ] Add level always opens a meaningful state and never fails silently.
- [ ] Accepting proposals persists the project hierarchy; reopening restores exactly the saved order.
- [ ] Pinned context explains its capture effect, links to field setup, saves marked fields, and remains visually distinct from hierarchy levels.
- [ ] A narrower capture inherits current broader and pinned values, then preserves those raw values on the saved record.
- [ ] Context and pin controls remain operable at every required size, orientation, theme, and 200 percent text.

## W4 — Add reusable project search and filters

**Feedback:** FBK0000044 · **Type:** Gap · **Priority:** P3 · **Effort:** M · **After:** W3

### Evidence

- FBK0000044: `screenshots/FBK0000044.png` shows the compact Projects list with no search field and asks for comprehensive filters.
- Root cause: `frontend/lib/features/projects/presentation/project_list_screen.dart:62` renders an unfiltered `ProjectListView` outside expanded mode, while `frontend/lib/app/nav_shell.dart` owns a separate expanded-only search field.
- Existing filter: `frontend/lib/features/projects/presentation/project_list_filter.dart:35` searches only project name, and `:8` stores only the archived toggle.

### Scope

- Reach: Android, iOS, macOS, Windows, Linux, and web at compact, medium, and expanded widths, both orientations, every theme, pointer and touch input, and 200 percent text. No applicable surface is excluded.
- Change: add immutable `ProjectListCriteria`, one `ProjectListToolbar`, one filter sheet, and one derived provider shared by the landing list and expanded pane.
- Do not change: repository ordering, pinned-first semantics, archive persistence, project rows, and list pagination behavior.

### Rules

- FE-CONS-01, FE-CONS-02, FE-STATE-01, FE-STATE-06: one toolbar and one criteria provider serve every responsive branch.
- FE-SIMP-02, FE-SIMP-06, FE-RESP-06, FE-A11Y-05: keep search visible and move secondary filters into one keyboard-accessible sheet.
- FE-PERF-03, FE-PERF-04: debounce text input and keep filtering linear over the already-loaded page.

### Steps

1. Replace the boolean archived filter with immutable `ProjectListCriteria`: query, status set, pin state `all/pinned/unpinned`, and organisation set. Keep criteria across size-class changes and clear it with one action.
2. Search case-insensitively and accent-insensitively across project name, description, and organisation. Apply status, pin, and organisation predicates in the same derived provider, then preserve repository order.
3. Build `ProjectListToolbar` from `AppSearchField`, a plain Filters action with active-count semantics, and a clear action. Use it above compact and medium lists and inside the expanded project pane.
4. Build one `AppBottomSheet` filter form using existing choice, switch, and list primitives. Derive organisation choices from loaded projects and show a no-results state that distinguishes search from filters.
5. Add provider tests for every field and combined criteria, widget tests at all three widths, keyboard-focus tests, and a golden for compact dark and outdoor plus expanded light at default and 200 percent text.
6. Run `cd frontend && dart run tool/verify.dart --fast` and keep it green.

### Acceptance criteria

- [ ] Search is visible on compact, medium, and expanded Projects surfaces and matches name, description, and organisation.
- [ ] Status, pinned state, and organisation filters combine deterministically and report their active count.
- [ ] Clearing restores the repository's pinned-first order and the standard empty state.
- [ ] Search and filters survive rotation and width changes without duplicated state.
- [ ] Touch, pointer, keyboard, screen-reader, theme, and 200 percent text checks pass on every named surface.

## W5 — Mark pinned projects in the list

**Feedback:** FBK0000045 · **Type:** Improvement · **Priority:** P3 · **Effort:** S · **After:** W4

### Evidence

- FBK0000045: the Projects list and its overflow menu show that a project can be unpinned, but the closed list row has no pinned indicator.
- Root cause: `frontend/lib/features/projects/presentation/project_list_view.dart:118` reads `pinnedAt` only to build the overflow action; the row at `:52` renders no pin state.

### Scope

- Reach: the shared `ProjectListView` on every platform, all size classes, both orientations, every theme, and 200 percent text. No applicable surface is excluded.
- Change: the reusable project-row trailing area, `Copy`, list semantics, widget tests, and intended project-list goldens.
- Do not change: pin ordering, pin timestamps, overflow actions, row numbering, and tap behavior.

### Rules

- FE-CONS-03, FE-THEME-01, FE-A11Y-01, FE-A11Y-02: use the standard pin icon, token color, and a semantic status label.
- FE-RESP-10, FE-TEST-05: retain row readability and update only intended goldens.

### Steps

1. Add a compact pin icon before the overflow menu only when `Project.pinnedAt` is non-null. Exclude the decorative glyph from duplicate speech and give the trailing group one `Pinned project` semantic label.
2. Use existing icon size, spacing, and foreground tokens; introduce no chip, badge container, card, and corner radius.
3. Extend list widget tests for pin and unpin state changes, semantics, overflow behavior, and stable numbering. Regenerate only project-list goldens whose rows intentionally gain the pin icon.
4. Run `cd frontend && dart run tool/verify.dart --fast` and keep it green.

### Acceptance criteria

- [ ] Every pinned row has one immediately visible pin indicator before its overflow action.
- [ ] Every unpinned row has no pin indicator and retains the same alignment.
- [ ] Screen readers announce pinned state once and preserve the row action order.
- [ ] Pinning and unpinning updates the indicator and existing pinned-first ordering without reopening the screen.
- [ ] Rows remain unclipped across every required width, orientation, theme, and 200 percent text.

## W6 — Show project association counts

**Feedback:** FBK0000046 · **Type:** Improvement · **Priority:** P3 · **Effort:** M · **After:** W3, W5

### Evidence

- FBK0000046: the project-home screenshot asks for left-aligned Context levels and Templates rows plus a visible indication of attached counts.
- Already present: `frontend/lib/features/projects/presentation/project_home_screen.dart:141` stretches the column and `:157` uses left-aligned shared list rows. The missing part is association count data and copy.
- Root cause: `ProjectHomeView` at `frontend/lib/features/projects/presentation/project_home_screen.dart:76` contains project, context, and work counts only; the two rows at `:157` have no subtitles.

### Scope

- Reach: project home on every platform, compact, medium, and expanded widths, both orientations, every theme, and 200 percent text. No applicable surface is excluded.
- Change: project-home derived view/providers, the two existing `AppListTile` rows, `Copy` plural helpers, and project-home tests and goldens.
- Do not change: the existing left alignment, four pending-work cards, context status line, and Continue capturing priority.

### Rules

- FE-STATE-06, FE-CONS-01, FE-L10N-09: derive live counts from context and template repositories and use plural-aware shared copy.
- FE-SIMP-01, FE-SIMP-02, FE-A11Y-03: keep the primary capture action dominant and counts secondary but readable.

### Steps

1. Add a derived `ProjectHomeAssociations` provider that combines the open project's saved context-level count and project-owned template count without storing duplicate totals.
2. Extend `ProjectHomeView` with association loading, data, empty, and failure states. Keep project-home failure recovery able to invalidate all contributing providers.
3. Add subtitles `No context levels` / `1 context level` / `<n> context levels` and `No templates attached` / `1 template attached` / `<n> templates attached` through `Copy` plural helpers.
4. Keep both rows flush to the same left edge, retain chevrons, and open W2's project-scoped routes.
5. Add provider and widget tests for zero, one, many, loading, and failure; update only intended project-home goldens at compact dark, expanded light, outdoor, and 200 percent text.
6. Run `cd frontend && dart run tool/verify.dart --fast` and keep it green.

### Acceptance criteria

- [ ] Project home shows live context-level and attached-template counts without a manual refresh.
- [ ] Zero, singular, and plural copy is correct and screen-reader friendly.
- [ ] Context levels and Templates stay left aligned and retain their existing navigation actions.
- [ ] Loading and repository failure never display a stale count as current.
- [ ] The primary capture action and work cards retain their visual priority on every required layout.

## W7 — Compact the Settings index

**Feedback:** FBK0000056 · **Type:** Improvement · **Priority:** P3 · **Effort:** S · **After:** W2, W6

### Evidence

- FBK0000056: two Settings screenshots show a long index containing operational destinations and inactive placeholders already represented elsewhere.
- Root cause: `frontend/lib/features/settings/presentation/settings_screen.dart:126` mixes actual preferences with Templates, Unprocessed, Language, and Files; Language and Files have null routes at `:153` and `:168`.

### Scope

- Reach: the Settings root on every platform and size class, both orientations, every theme, and 200 percent text. No applicable surface is excluded.
- Change: Settings section data and rendering, Settings copy, and widget/golden tests.
- Do not change: the underlying Templates and Queue routes, deep links, project-home destinations, saved settings, and browser history.

### Rules

- FE-SIMP-01, FE-SIMP-02, FE-SIMP-05, FE-CONS-05: show only useful settings and group them with existing section/list primitives.
- FE-THEME-10, FE-A11Y-02, FE-A11Y-03: use separators and hierarchy without decorative cards or rounded containers.

### Steps

1. Per D5, keep Operator, Capture, AI, Appearance, Storage, Security, and About in the Settings index; remove Templates, Unprocessed, Language, and Files from this index only.
2. Group remaining rows under plain section headers: `Profile and capture`, `Intelligence and appearance`, `Storage and security`, and `About`. Use existing `AppListTile`, divider, and typography tokens.
3. Preserve global Templates and Queue deep links for compatibility and direct access; W2's project screens remain their primary contextual entry points.
4. Add widget tests for exact row order, absence of inactive rows, working routes, keyboard order, and no overflow; update intended Settings goldens for all themes and 200 percent text.
5. Run `cd frontend && dart run tool/verify.dart --fast` and keep it green.

### Acceptance criteria

- [ ] Settings contains seven working preference destinations in four clear sections under D5's default.
- [ ] The index contains zero null-route placeholders, zero operational Templates rows, and zero operational Unprocessed rows.
- [ ] Existing Templates and Queue deep links still resolve and their back behavior follows W2.
- [ ] The index fits compact portrait with less scrolling and remains complete at expanded width and 200 percent text.
- [ ] The screen uses shared rows and separators without new card treatment and decorative corner radii.

## W8 — Attach audio evidence to capture

**Feedback:** FBK0000054 · **Type:** Suggestion · **Priority:** P4 · **Effort:** XL · **After:** W1, W3

### Evidence

- FBK0000054 asks capture to record audio, associate a clip with photos like captions, and use its transcript as extraction evidence.
- Partial implementation: `frontend/lib/features/capture/presentation/audio_recorder.dart:12` renders recording controls, but `frontend/lib/core/audio/audio_recorder_service.dart:31` provides only unavailable and fake implementations and `frontend/lib/main.dart` supplies no production recorder.
- Storage gap: `frontend/lib/core/db/tables/attachments.dart:16` stores audio metadata at project level only, with no record or photo ownership; `frontend/lib/features/processing/data/processing_stage_worker.dart` loads photos and captions but no audio.

### Scope

- Reach: Android, iOS, macOS, Windows, and Linux where the approved recorder supports microphone capture. Web recording is excluded because project evidence currently has no browser `FileWriter`; keep the shared screen's unavailable state explicit and the web build green.
- Change: per D3, dependency files and allowlist; audio recorder adapter/provider; capture session/domain/UI; attachment ownership table and v18 migration; W1 writer; processing bundle/transcription; platform permission copy; `Copy`; tests and generated Drift output.
- Do not change: existing dictation behavior, raw audio bytes, raw transcripts, photo captions, backend key custody, and offline Save raw behavior.

### Rules

- FE-FLOW-06, FE-STR-11: approve the pinned recorder dependency in the hardening task and isolate plugin calls behind `AudioRecorderService`.
- FE-SEC-04, FE-SEC-07, FE-SEC-08, FE-STATE-07: request microphone access on tap, stream locally, preserve raw evidence, and confirm only durable writes.
- FE-PERF-02, FE-PERF-07: stream audio chunks and hashes without retaining a full recording in memory.

### Steps

1. Per D3, add `record: ^7.1.1` to `pubspec.yaml` and `tool/allowlist.yaml` with BSD-3-Clause, the hardening task number, its purpose, and the unavailable production recorder it replaces; update lockfiles through Flutter tooling.
2. Implement the production `AudioRecorderService` adapter with explicit idle, permission, recording, paused, finalizing, failed, and completed states. Feed recorder chunks into `FileWriter` under the project's `audio/` directory and publish metadata only after the file is flushed and hashed.
3. Add the non-destructive v18 `AttachmentOwners` table with `attachmentId`, `ownerType` (`record`, `photo`), `ownerId`, and `sortOrder`, plus a uniqueness constraint and owner lookup index. Test v16 → v17 → v18 with existing attachment and capture data intact.
4. Add `AudioDraft` to `CaptureSession`; render the existing `AudioRecorder` in capture; after stop, open a scope sheet for this photo, selected photos, and all photos using the same count semantics as captions. Always link the clip to the saved record and independently link each selected photo.
5. Extend W1's transaction to insert audio `Attachments`, owner links, duration, MIME type, size, hash, and path. Session reset clears draft references only and never deletes the saved file.
6. Extend the processing bundle to load record audio and its photo links, transcribe each clip once through the selected `AiService`, preserve provider output as raw processing evidence, and include transcript text in extraction without overwriting captions and manual values. Save and process queues offline when transcription needs the network.
7. Wire the recorder in `frontend/lib/main.dart`, retain fake injection, and add unit/widget/integration tests for permission denied, pause/resume, app interruption, disk full, association scopes, migration, one transcription per clip, zero transcription on Save raw, and raw-evidence preservation.
8. Run `cd frontend && dart run tool/verify.dart --fast` and keep it green.

### Acceptance criteria

- [ ] A user can record, pause, resume, stop, and retry audio from Capture without blocking typing and photos.
- [ ] A stopped clip is durable under the project audio tree and linked to its record plus every selected photo.
- [ ] Denied permission, interruption, and disk failure leave the rest of capture usable and never announce a saved clip.
- [ ] Save raw stores audio with zero transcription, zero AI, and zero egress.
- [ ] Save and process transcribes each clip once, uses the transcript as evidence, preserves raw audio and raw text, and never overwrites a manual field.
- [ ] Recorder UI and semantics pass on supported native platforms across all required layouts, themes, and 200 percent text; web explains unavailability.

## W9 — Build registry-driven AI settings

**Feedback:** FBK0000055 · **Type:** Suggestion · **Priority:** P4 · **Effort:** L · **After:** W7

### Evidence

- FBK0000055: two screenshots show one credential field and a disabled test state; the report asks for provider and model configuration driven by an updateable list.
- Root cause: `frontend/lib/features/settings/presentation/api_key_screen.dart:75` stores one undifferentiated credential and hardcodes provider id `device`; `frontend/lib/app/router.dart:832` supplies no test callback.
- Root cause: `frontend/lib/core/ai/provider_registry.dart:30` exposes only a keyless backend entry and no presentation metadata or models; `frontend/lib/main.dart:104` constructs that registry with an unavailable service.

### Scope

- Reach: AI Settings and shared processing selection on every platform and size class, both orientations, every theme, offline and online states, and 200 percent text. No applicable surface is excluded.
- Change: per D4, evolve `ProviderRegistry` with typed descriptors and model metadata; add provider/model selection keys; replace `ApiKeyScreen` with `AiProviderSettingsScreen`; wire route, registry, test action, `Copy`, and tests.
- Do not change: `AiService` request contracts, backend task 024, raw evidence rules, the default keyless backend selection, and the rule that an unavailable provider queues processing.

### Rules

- FE-SEC-01, FE-SEC-02, FE-SEC-06, FE-SEC-07, FE-SEC-10: credentials stay in secure storage, provider egress is explicit, and offline work remains complete.
- FE-STATE-06, FE-CONS-01, FE-SIMP-05: the registry catalog is the sole provider/model source and advanced credentials use progressive disclosure.
- FE-STR-09, FE-TEST-02, FE-TEST-10: callers keep resolving `AiService`; registry, settings, and secure-storage failures have focused tests.

### Steps

1. Per D4, replace the private `RegistryEntry` record with immutable `ProviderDescriptor` and `ModelDescriptor` types that carry stable ids, labels, supported `AiOperation` values, key custody, device-key permission, availability, and service resolution. Expose an ordered read-only catalog and reject duplicate ids and invalid selections.
2. Add typed `SettingKeys.aiModel` plus operation selection state that validates saved ids against the current catalog and falls back to backend without erasing an unavailable saved choice.
3. Build `AiProviderSettingsScreen` with provider choice, model choice filtered by operation, custody and availability explanation, Save, Remove device credential, and Test connection. Render device credential input only for an admin-enabled device-key descriptor.
4. Preserve `/more/provider-key` as a redirect and make `AppRoutes.settingsAi` the canonical route. Wire the selected descriptor's real `AiService` into `ProviderTestAction` and report success, authentication, network, unavailable, and validation states distinctly.
5. Make `ProcessingStageWorker` resolve provider and model from settings for each operation, stamp the selected ids on provenance, and queue rather than drop work across absent, unavailable, offline, and over-quota descriptor states.
6. Add registry unit tests, SettingsStore round-trip and fallback tests, secure-storage leak tests, widget tests with injected multi-provider catalogs, route compatibility tests, and worker tests proving selection changes behavior without feature-code changes.
7. Run `cd frontend && dart run tool/verify.dart --fast` and keep it green.

### Acceptance criteria

- [ ] AI Settings renders every injected provider and supported model without hardcoded provider branches in presentation code.
- [ ] The backend proxy remains the default and requires no device key.
- [ ] Device credential controls appear only for descriptors explicitly allowed by D4 and store no secret outside secure storage.
- [ ] Saving provider and model changes processing resolution and provenance; an invalid saved id degrades to backend with a visible explanation.
- [ ] Test connection invokes the selected service and renders every typed outcome with a retry path.
- [ ] Adding a descriptor in a test updates the provider list without changing Settings presentation code.
- [ ] Offline capture, Save raw, and queued processing remain fully functional across every required surface.

## Verification

- After the last item, the full `cd frontend && dart run tool/verify.dart` is green.
- Run the focused migration suite from schema v16 through v18 with populated projects, templates, sessions, photos, attachments, captions, records, and processing jobs.
- Run the capture integration suite once with connectivity forced offline and assert zero outbound calls on Save raw.
- Run Android back, microphone-permission, process-death recovery, and durable-file integration tests on an Android emulator.
- Regenerate goldens with `--update-goldens` only for the project list, project home, Settings index, context hierarchy, AI Settings, and shell header visuals intentionally changed above; list every regenerated file in the hardening task.
- Run accessibility checks at 200 percent text for compact, medium, and expanded surfaces in light, dark, and outdoor themes.
