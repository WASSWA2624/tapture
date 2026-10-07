# 001 — Resolve field workflow feedback

**Feedback:** FBK0000165–FBK0000187 · **Work items:** 16 · **Depends on:** none (feedback prompts); repository prerequisite checks below still apply.

## Goal
Resolve this archive’s project, template, navigation, recycling, meeting-review and settings feedback through the existing shared components and local-first services. Deliver the specified behavior on Android, iOS, Windows, macOS, Linux and web, across compact, medium and expanded layouts, portrait and landscape, light, dark and outdoor themes, at normal and 200 percent text size.

## Run order
| Item | Title | Feedback | Type | Priority | Effort | After |
| --- | --- | --- | --- | --- | --- | --- |
| W1 | Preserve and clarify meeting review edits | FBK0000187 | Defect | P0 | M | — |
| W2 | Offer template setup without blocking capture | FBK0000185 | Gap | P1 | S | — |
| W3 | Validate project names while editing | FBK0000184 | Defect | P2 | S | — |
| W4 | Return through home screens before exit | FBK0000169 | Gap | P2 | M | — |
| W5 | Group project commands in the shared menu | FBK0000186 | Improvement | P3 | M | — |
| W6 | Remove Projects filter controls | FBK0000165, FBK0000166, FBK0000167, FBK0000174, FBK0000175 | Improvement | P4 | M | — |
| W7 | Remove global queue and transcript shortcuts | FBK0000171, FBK0000172 | Improvement | P4 | S | W4 |
| W8 | Open project packages directly and compact import | FBK0000168, FBK0000173 | Improvement | P4 | M | W6 |
| W9 | Remove repository links from About | FBK0000183 | Improvement | P4 | S | — |
| W10 | Remove the Organisation settings shortcut | FBK0000179 | Improvement | P4 | S | W7 |
| W11 | Move relay access into project settings | FBK0000180 | Improvement | P4 | M | W10 |
| W12 | Collapse advanced capture defaults | FBK0000181 | Improvement | P4 | M | — |
| W13 | Compact language and speech controls | FBK0000182 | Improvement | P4 | M | W12 |
| W14 | Expose shipped and custom templates globally | FBK0000170 | Gap | P4 | L | W2 |
| W15 | Include deleted projects and files in recycling | FBK0000176 | Gap | P4 | L | — |
| W16 | Configure supported AI providers in a compact flow | FBK0000177, FBK0000178 | Suggestion | P5 | L | W10, W13 |

P0 protects entered content; P1 unblocks capture; P2 covers correctness; P3 changes shared visuals before their consumers; P4 covers existing flows; P5 adds capability. S/M/L describe relative work, not completion percentages.

## Decisions
⛔ Stop here. Obtain an answer to every decision before making implementation, plan, specification or progress changes. **“Proceed” means all defaults.** The steps below specify those defaults. A non-default answer requires replacing the affected steps and acceptance criteria with an equally concrete specification before W1; the runner must not improvise the missing design.

- **D1 (W1): Approve durable meeting editing and the pictured layout change?** (a) Preserve editable notes/minutes with serialized local saves, add immutable `originalNotes` beside working `notes` in the existing agenda JSON, reuse `MeetingTextField`, label summary counts and compact the empty idle transcript area; (b) make notes/minutes read-only and retain stored text. Default **(a)**: the route presents editable fields without save callbacks. This explicitly authorizes the additive stored-JSON and `MeetingRecord.originalNotes` contracts, their legacy reader compatibility, audit entries and raw-notes export mapping; it never authorizes overwriting original notes, audio or transcript versions. A default-preserving presentation flag on `LiveTranscriptPanel` may implement the meeting-only idle layout.
- **D2 (W2): What is the no-template primary action?** (a) **Add template**, with a secondary **Capture now** action using the existing raw-capture path; (b) enabled **Start capturing**, with secondary template setup. Default **(a)**: it follows the report while honoring the repository’s rule that missing templates never block capture.
- **D3 (W4): Which root Back convention applies?** (a) Close overlays, honor the child/form pop guard, return to the branch home, return from other branch homes to Projects, then allow native system Back to exit; web retains normal browser history, iOS retains native stack gestures, desktop window close retains its existing exit guard; (b) traverse previously visited branch homes before Projects. Default **(a)**: it is deterministic and does not create navigation cycles.
- **D4 (W5): Approve project-menu grouping and the additive shared-menu API?** (a) Add optional section labels to `AppOverflowAction`, then group existing commands under **Capture and review**, **Project setup**, **Exchange**, **Manage project**; (b) reorder the existing ungrouped list only. Default **(a)**: visible groups address the pictured long undifferentiated menu without adding destinations.
- **D5 (W6): What replaces the removed filter controls?** (a) Keep the active-project default, text search, pin sorting and the existing **Show archived** command; remove status/pinned/organisation filter fields and redirect the old filters route to Projects; (b) show active and archived projects together by default. Default **(a)**: archive recovery remains available without silently changing the established default.
- **D6 (W7): Where should the two shortcuts disappear?** (a) Remove Unprocessed and Transcripts from the shared global More/Settings list at every width, retaining their routes and project entry points; (b) remove them from the compact More popup only. Default **(a)**: the same global menu should stay consistent across devices. No transcript, recording or queued job is deleted.
- **D7 (W8): Approve the file-picker scope and import layout?** (a) Label the Projects action exactly **Import a Project**, select existing project-package `.zip` files through the platform document picker, leave folders as navigable containers, and collapse generic import-format help; (b) add selectable folder import with a separately specified folder contract. Default **(a)**: the current repository supports ZIP project packages and has no project-folder importer. Native pickers and browser file inputs express the same supported-file intent; the importer remains the validation authority when a picker cannot hide every unsupported file.
- **D8 (W9): Which About links should be removed?** (a) Remove Development plan and Specification; retain Version, Build and Licences; (b) retain the repository links under a collapsed development section. Default **(a)**: these are the two repository links shown in the image.
- **D9 (W10): What does Organisation removal mean?** (a) Remove its Settings shortcut, keep `/more/account` available for explicit server/account setup and recovery; (b) retire the standalone page after specifying a replacement account-management flow. Default **(a)**: the backend, first sign-in, cached grants and key custody remain required product contracts.
- **D10 (W11): What does Change relay removal mean?** (a) Remove its global Settings shortcut, expose its existing controls from the current project’s settings, and preserve legacy links and queued encrypted packages; (b) retire relay after defining enabled-project and queued-package handling. Default **(a)**: it removes the pictured no-project detour without hiding ongoing transfers or purging evidence.
- **D11 (W12, W13): Approve disclosure defaults?** (a) Capture keeps camera, dates and location visible with Photo files and Project contexts collapsed; Language keeps language, quality and speech-health summaries visible with Speech models collapsed; (b) retain all sections expanded and compact only their selectors. Default **(a)**: secondary settings stay accessible with one disclosure action. Stored settings, permission defaults and speech behavior are unchanged.
- **D12 (W14): What owns templates created from global Templates?** (a) An editable global custom library, using the existing nullable `TemplateDef.projectId`, beside immutable shipped assets; project attachment makes an independent versioned copy; (b) the current project, requiring project selection before creation/customization. Default **(a)**: global Templates should be useful before a project exists. This authorizes additive repository/loader contracts, not relocation of existing project-owned templates or alteration of bundle formats.
- **D13 (W15): Approve the recycling scope and restoration rules?** (a) List deleted projects, records, independently deleted managed photos and all database-owned attachment kinds, including audio/documents; restore through their owning repositories, requiring deleted parents to be restored first; leave permanent deletion record-only under its existing policy; (b) add read-only project/file listings and retain only record restoration. Default **(a)**: recovery preserves raw files until the existing purge policy allows removal. This authorizes additive typed watch/restore and `ProjectFolders.restore` APIs plus future project-deletion status audits, not a new evidence format. “Files” excludes arbitrary files found on disk.
- **D14 (W16): What does support for any AI provider mean?** (a) Administrator-configured providers implementing the repository’s existing Gemini generateContent and OpenAI Responses protocols, with configured models and key-required/keyless authentication; (b) additional named native protocols supplied before implementation. Default **(a)**: an API key alone cannot define an arbitrary protocol. The UI must say **Supported providers**, never imply universal vendor compatibility.
- **D15 (W16): Approve the provider contract, persistence and egress changes?** (a) Add nonsecret catalogue metadata, widen the provider-ID constraint through a forward migration, preserve existing credentials/receipts/selections, and permit only administrator-configured HTTPS endpoints while keeping backend custody and offline gates; (b) defer provider expansion and perform only the compact existing-provider UI. Default **(a)**: these changes are prerequisites for D14. This also authorizes the additive shared catalogue/registry API. Production deployment and production migration execution are outside this prompt.

## Rules
- Read `AGENTS.md`, `frontend/.rules/README.md` and all 13 linked files; for W16 read every file listed by `backend/.rules/README.md`. Recheck nested agent guidance. This prompt is based on commit `18949f21` plus the inspected working tree, not a clean-checkout claim.
- FE-CONS-01/02/03/05/06, FE-STR-04/08/09/11: use catalogue widgets, feature barrels and platform services. Extend shared code once. Shared visual additions require gallery states and goldens.
- FE-THEME-01/02/03/07, FE-A11Y-01/02/03/04/06/07: token styling, existing minimum nonzero `Radii`, 48dp targets, accessible labels/focus, visible and announced state. Outdoor geometry matches light/dark.
- FE-RESP-03/04/05/06/07/08/10, FE-L10N-01/03/05/06: all three widths, both orientations, 100/200 percent text, scrollable keyboard-safe forms and pseudo-locale expansion. Keep strings in `Copy.of(context)`/the localization catalogue.
- FE-STATE-04/05/06/07/08, FE-SEC-01/02/03/04/05/06/08/09: typed boundaries, durable local writes, one source of truth, quoted untrusted evidence, validated imports, no secret disclosure, no raw-evidence overwrite, offline capture remains available.
- FE-SIMP-01/02/03/06/07/08/09/11: one primary action, four primary destinations, collapsed secondary settings, input-preserving failure paths. No setup requirement on raw capture.
- FE-TEST-01/02/03/05/06/10, FE-FLOW-03/04/06/07/08: tests ship with changes, use fakes, no live AI requests, do not weaken guardrails, add no dependencies and do not change rules. Unrelated discoveries become separate backlog tasks.
- BE-AI-01–10, BE-SEC-01/05/06/11, BE-FLOW-02/03/04: server-only keys, bounded configured egress, preserved quotas and request identity, versioned contract changes together, explicit independent security review.

## Before the work items
1. Record the answered decisions in the implementation task. From `frontend/`, create **one** follow-up task with `dart run tool/new_task.dart 24-product-refinements "Resolve October field workflow feedback"`. The current tool accepts exactly `<step> "<title>"`; do not pass the obsolete third slug argument. Use the next ID allocated by the tool, copy these 16 items into its Implement/Files/Definition of done, and record the public contracts explicitly. Keep this archive in one task/branch/PR under FE-FLOW-01; never fold unrelated task progress into it.
2. Read the owner tasks and their dependencies/Definition of done: 006 shell, 007 settings, 008 projects, 009 templates, 014 records/recycling, 017 meetings, 019 packages, 024 backend, and 060/061/074/075/076/079/123/124/126/132 in `dev-plan/24-product-refinements.md`. Record actual prerequisites before implementation. Several owner tasks and transitive prerequisites are incomplete in `dev-tracker.md`; historical Complete labels are not fresh verification. Finish declared prerequisites before dependent work. Report a blocked prerequisite explicitly and leave the dependent acceptance open; do not silently implement unrelated prerequisite scope.
3. Preserve existing local edits and all archive evidence. Mark the new task `**Implementation started:** Yes` when implementation begins. Update `app-write-up.md` only for the accepted contracts changed here, preserve stable section anchors, and annotate superseded historical requirements (notably 079/123 global navigation) without claiming old checks have been rerun. Never edit `dev-tracker.md` manually.
4. Reuse `AppChoiceField(alwaysSheet: true)`, `AppSectionHeader(expanded:, onToggle:)`, `AppListTile`, `AppBanner`, `AsyncValueView`, `AppForm`, `AppPage` and the existing responsive helpers. No new visual system. Add new copy keys to `frontend/lib/core/copy/l10n/app_en.arb` with translator metadata, expose them through `frontend/lib/core/copy/localized_copy.dart` and `frontend/lib/core/copy/copy.dart`, then run `dart run tool/generate_pseudo_locale.dart`, `flutter gen-l10n` and `dart run tool/generate_copy_messages.dart`.
5. The matrix below is mandatory for every UI item: Android/iOS/Windows/macOS/Linux/web; compact/medium/expanded; portrait/landscape; light/dark/outdoor; text scales 1 and 2. Use existing `frontend/test/responsive/` harnesses and named corner goldens, plus relevant native/browser integration checks. Every Reach below inherits this entire matrix. Native system exit and document-provider limitations have explicit item exclusions; there are no silent visual exclusions.
6. Test files exist locally under ignored directories. Search those directories with `rg --files --no-ignore`. Ship each changed/new regression, fixture and required support file with narrow `.gitignore` exceptions, following the existing task132 exceptions; do not unignore entire test trees. Scope test selection to each item’s behavior, then run the combined verification below.

## W1 — Preserve and clarify meeting review edits
**Feedback:** FBK0000187 · **Type:** Defect · **Priority:** P0 · **Effort:** M · **After:** —

### Evidence
- The report asks for a clearer Review meeting UI. `screenshots/FBK0000187.png` shows a large idle transcript panel, unlabelled numeric summary and compact notes/minutes fields; observed Android/compact/portrait/light at text scale 1.
- `frontend/lib/features/meetings/presentation/meeting_review_screen.dart:163` and `:169` construct text controllers during rendering; `:217` renders bare counts. `frontend/lib/app/router.dart:628` supplies no notes/minutes save callbacks to the production review route. `frontend/lib/features/transcripts/presentation/live_transcript_panel.dart` renders the idle transcript surface.

### Scope
- Reach: full matrix, existing project meeting-review routes, live and saved transcripts; no platform exclusion.
- Change: `frontend/lib/features/meetings/presentation/meeting_review_screen.dart`, existing `frontend/lib/features/meetings/presentation/meeting_text_field.dart`, `frontend/lib/features/meetings/data/meeting_repository_impl.dart`, `frontend/lib/features/meetings/domain/meeting_repository.dart`, route wiring in `frontend/lib/app/router.dart`, the meeting caller of `LiveTranscriptPanel` and the raw-notes reader in `frontend/lib/features/exports/data/deliverable_reports.dart`; add `frontend/lib/features/meetings/presentation/meeting_review_controller.dart` for serialized edit intents.
- Do not change: raw audio, transcript-version history, AI proposal approval rules, global transcript-pane dimensions, unrelated transcription screens.

### Rules
- FE-STATE-04/07/09, FE-SEC-08/09, FE-SIMP-09, FE-CONS-01, FE-A11Y-07: edits survive rebuilds and save failures; summaries carry meaningful labels.

### Steps
1. Per D1, add `originalNotes` to the existing agenda JSON and `MeetingRecord`. Legacy reads use current `notes` as the original until the first write; that write snapshots the prior notes inside its transaction before applying the edit. New meetings initialize both values together. Every agenda writer preserves an existing original exactly. Delayed writers, including transcription, reload the latest meeting inside their final write transaction and patch only their owned field, preserving concurrent notes/minutes edits. Keep working notes in the existing `notes` field, append explicit before/after notes/minutes audit entries in the same transaction, and use `originalNotes` for export sections labelled raw notes. Never derive current notes from audit timestamps: merge unions audit independently of the chosen meeting row.
2. Connect production edits to `MeetingRepository.save` through the controller. Read the latest meeting before applying each edit, serialize writes, retain pending text on failure, and preserve the unchanged counterpart field plus transcript/audio references. Announce saved only after persistence; prevent navigation from silently discarding a failed/pending save.
3. Replace render-created controllers with existing `MeetingTextField` instances; retain caret and text across provider refresh, rotation and resize. Keep injected test callbacks as explicit test seams without bypassing production persistence.
4. Use existing `meetingSummary`, `meetingDecisionsCount`, `meetingActionsCount` and `meetingNotesAndMinutes` copy. Put labelled summary first, recording/status next, then multiline Notes and Minutes. Show the transcript pane for active sessions and for any stored transcript content; hide only the empty idle pane, retaining start-recording and missing-model recovery. Keep the existing Approve footer as the page primary; scope the compact idle presentation to the meeting caller.
5. Update `frontend/test/features/meetings/presentation/meeting_review_screen_test.dart`; add controller/repository regressions and extend `frontend/integration_test/meeting_test.dart` with production-route type → save → reopen. Test legacy initialization, repeated/interleaved edits, failed transactions, transcription completing during typing, rebuild, idle/active/finished transcripts, source hashes, raw-notes export, package roundtrip and merge undo. Add intended review-screen corner goldens.

### Acceptance criteria
- [ ] Notes/minutes entered through the production route survive reopen, rotation and asynchronous updates; failed saves preserve text and expose retry.
- [ ] Summary counts are labelled, idle space is compact, and live/stored transcripts remain reachable throughout the full matrix.
- [ ] Original notes, raw audio and transcript versions remain unchanged; legacy/package/merge/export and production-route integration tests pass.
- [ ] FBK0000187 is resolved under the approved D1 interpretation.

## W2 — Offer template setup without blocking capture
**Feedback:** FBK0000185 · **Type:** Gap · **Priority:** P1 · **Effort:** S · **After:** —

### Evidence
- `screenshots/FBK0000185.png` shows an empty project with a disabled Start capturing button. The report requests Add template when no template has been added.
- `frontend/lib/features/projects/presentation/project_home_screen.dart:50` gates `canCapture` on a nonempty template list; `:65` uses it for the capture button.

### Scope
- Reach: full matrix, empty-template project homes; the existing global/raw capture flow remains reachable on all platforms.
- Change: `ProjectHomeScreen`, its existing template route helper and capture callback, and the associated localized action keys.
- Do not change: project creation requirements, raw-capture persistence, template defaults, existing projects’ primary capture action.

### Rules
- FE-SIMP-01/03/11, FE-STATE-07, FE-CONS-01: provide one useful primary action while preserving capture without setup.

### Steps
1. Per D2, use existing `templatesAdd` copy for the primary Add template action when the observed template collection is empty; open `RoutePaths.projectTemplates(project.id)`.
2. Add secondary `projectCaptureNow` copy/action that opens the existing raw capture route with this project selected. Remove the template-count restriction from that route’s capture availability; keep real device/permission failures in their existing recoverable flow.
3. While templates load and after a template-query failure, show Capture now as the primary action, with existing recoverable failure UI in the failed state. Only confirmed-empty data selects Add template. After durable attachment, derive the normal capture primary from the same stream; removal of the last template reverses that state without losing project selection.
4. Update `frontend/test/features/projects/presentation/project_home_screen_test.dart` for empty/loading/failure/attached states and `frontend/integration_test/capture_raw_offline_test.dart` for a no-template offline capture; include the full layout matrix.

### Acceptance criteria
- [ ] No-template projects offer Add template as primary and an enabled raw-capture entry as secondary.
- [ ] Attaching a template restores the normal capture primary action without manual refresh, preserving project selection.
- [ ] Offline capture succeeds before template setup; all named states and matrix tests pass.
- [ ] FBK0000185 is resolved without adding a capture prerequisite.

## W3 — Validate project names while editing
**Feedback:** FBK0000184 · **Type:** Defect · **Priority:** P2 · **Effort:** S · **After:** —

### Evidence
- `screenshots/FBK0000184.png` shows Create project with a populated name and a lingering required-name error; the report asks for live validation.
- `frontend/lib/features/projects/presentation/project_create_screen.dart:88` supplies `errorText` without a name-change validation callback; `:194` validates only on submit.

### Scope
- Reach: full matrix, Create project; reuse validation in Edit project where it enforces the identical name contract. No platform exclusion.
- Change: `ProjectCreateScreen`, `frontend/lib/features/projects/presentation/project_edit_screen.dart`, their form controllers and new `frontend/lib/features/projects/domain/project_name.dart`; reuse `AppTextField.errorText`/`onChanged` and the form-owned text-controller listener.
- Do not change: accepted name rules, uniqueness policy, IDs, persisted naming patterns, other forms’ validation timing.

### Rules
- FE-STATE-04/06, FE-CONS-01/11, FE-A11Y-07, FE-SIMP-09: one validation rule, inline localized feedback, retained input.

### Steps
1. Extract the current inline `name.trim().isEmpty` rule from Create/Edit into pure `ProjectName.isValid(String)`. Track touched/submitted state in the form’s auto-disposed Riverpod controller. Leave untouched fields quiet; validate on every text mutation and at submit, including keyboard, dictation and controller updates; a reopen resets stale validation state without deleting a retained draft.
2. Clear the stale required-name error immediately when the current trimmed value satisfies the rule. Preserve server/storage failures separately from field validation. Apply identical behavior to the existing edit-name field.
3. Retain the final validation before save and durable-save error recovery. Keep all other entered fields intact.
4. Update `frontend/test/features/projects/presentation/project_create_screen_test.dart` and `frontend/test/features/projects/presentation/project_edit_screen_test.dart` for untouched, whitespace-only, valid, cleared, failed-save and keyboard/200-percent cases. Test dictation through the same change path.

### Acceptance criteria
- [ ] A valid edit clears the pictured stale error before submission; clearing a touched name shows the correct inline error.
- [ ] Submit uses the same rule and never loses entered values on failure.
- [ ] Create/Edit name tests and the matrix pass; FBK0000184 is resolved.

## W4 — Return through home screens before exit
**Feedback:** FBK0000169 · **Type:** Gap · **Priority:** P2 · **Effort:** M · **After:** —

### Evidence
- The report asks for home screens in Back navigation before app exit; `screenshots/FBK0000169.png` shows the Projects root, without a marked navigation sequence.
- `frontend/lib/app/nav_shell.dart:185` and `:264` switch branches with `initialLocation: true`; the shell has no root Back handler. `frontend/lib/app/widgets/status_line.dart:266` handles only the visible header Back action.

### Scope
- Reach: full matrix, branch roots and project child stacks. Android system Back uses D3; iOS gestures pop existing routes; browser Back follows browser history; desktop window close keeps its existing guard. Browsers must never attempt to close their window.
- Change: `frontend/lib/app/nav_shell.dart`, `frontend/lib/app/router.dart`, `frontend/lib/app/widgets/status_line.dart`, existing shell route-parent helpers; add a single shell-owned root-pop policy.
- Do not change: the four primary destinations, route identities, form/capture discard guards, overlay dismissal and browser history semantics.

### Rules
- FE-RESP-03/07/08, FE-CONS-10, FE-SIMP-09, FE-STATE-06: shared route state and native Back conventions.

### Steps
1. Per D3, let overlays and child navigators consume Back first. Honor a refused form/capture pop before applying any shell fallback.
2. Handle a non-Projects branch root by returning to Projects. From a project child return through project home, then Projects; permit native system exit only at Projects root with nothing left to dismiss.
3. Make header Back and native root-pop handling share the same parent resolution. Preserve branch selection, drafts and expanded list/detail state during resize; do not manufacture browser history cycles.
4. Extend `frontend/test/app/router_test.dart`, `frontend/test/app/nav_shell_test.dart` and `frontend/test/app/widgets/status_line_test.dart`; add `frontend/test/app/shell_title_test.dart` for the existing parent resolver. Exercise `handlePopRoute`, cold deep links, restored state, overlays, guarded dirty forms, and each root. Add Android Back and browser-history integration coverage to the existing harnesses.

### Acceptance criteria
- [ ] Project detail → project home → Projects → native exit is deterministic; other branch roots first return to Projects.
- [ ] Dirty input and capture guards take precedence; cancelling a discard keeps the route and content.
- [ ] iOS/browser/desktop exclusions behave exactly as described; resize and matrix coverage pass.
- [ ] FBK0000169 is resolved under D3.

## W5 — Group project commands in the shared menu
**Feedback:** FBK0000186 · **Type:** Improvement · **Priority:** P3 · **Effort:** M · **After:** —

### Evidence
- `screenshots/FBK0000186.png` shows a long project overflow list without groups; the report requests organization.
- `frontend/lib/features/projects/presentation/project_home_screen.dart` builds a flat `_projectHomeMenu`; `frontend/lib/core/widgets/app_overflow_menu.dart` renders every action as an identical row and truncates each label to one line.

### Scope
- Reach: full matrix; shared menu rendering serves all existing callers, with section labels used by project home only. No platform exclusion.
- Change: `frontend/lib/core/widgets/app_overflow_action.dart`, `frontend/lib/core/widgets/app_overflow_menu.dart`, `ProjectHomeScreen`, shared gallery, Copy keys `projectMenuCaptureReview`, `projectMenuSetup`, `projectMenuExchange`, `projectMenuManage`.
- Do not change: command callbacks, permission predicates, platform-specific external-open availability, destructive confirmations and undo.

### Rules
- FE-CONS-01/02/03/05, FE-STR-09, FE-A11Y-01/02/03/06, FE-THEME-01: group once in the shared component with accessible, token-styled headings.

### Steps
1. Per D4, add nullable `sectionLabel` to `AppOverflowAction`, default null. Render a nonselectable semantic heading before a changed section label in both `AppOverflowMenu` and `showAppOverflowActions`. Keep action indices correct; ungrouped callers retain their behavior. Let labels wrap at 200 percent text.
2. Order existing actions: Capture and review = Transcribe, Start meeting, Quality summary; Project setup = Templates, Datasets, Pinned fields, Context hierarchy; Exchange = Export, Merge package, Merge history, available Open externally; Manage project = Project details, Project settings, Duplicate, Archive/Unarchive, Delete. Use the actual existing labels/callbacks; include each action exactly once and Delete last.
3. Add grouped, ungrouped, keyboard and large-text states to `frontend/lib/core/widgets/gallery/widget_gallery_screen.dart`. Test heading semantics, callback indices and menu dismissal.
4. Update `frontend/test/features/projects/presentation/project_home_screen_test.dart` and shared overflow tests; add grouped menu goldens in all three themes and both normal/200-percent text, including a narrow landscape viewport.

### Acceptance criteria
- [ ] Every existing permitted project action appears once in the specified order and executes the unchanged callback.
- [ ] Shared menu headings are not selectable; keyboard traversal, touch targets and wrapped labels pass the matrix.
- [ ] Ungrouped callers retain their behavior; gallery and shared goldens pass.
- [ ] FBK0000186 is resolved.

## W6 — Remove Projects filter controls
**Feedback:** FBK0000165, FBK0000166, FBK0000167, FBK0000174, FBK0000175 · **Type:** Improvement · **Priority:** P4 · **Effort:** M · **After:** —

### Evidence
- FBK0000167 explicitly requests removing Projects filters; its first image shows the Project filters sheet and `FBK0000167-2.png` shows the full empty Projects page. FBK0000166/FBK0000174 repeat the filter sheet; FBK0000165/FBK0000175 show its Status picker. These are one removal, not five changes.
- `frontend/lib/features/projects/presentation/project_list_toolbar.dart:29` opens the sheet; `frontend/lib/features/projects/presentation/project_list_filter.dart:49` owns it and `:143` applies status/pin/organisation predicates. `frontend/lib/app/router.dart:527` also exposes the old full-page filter route.

### Scope
- Reach: full matrix, empty and populated Projects; remove all entry points to the same filter UI. No platform exclusion.
- Change: `frontend/lib/features/projects/presentation/project_list_toolbar.dart`, `frontend/lib/features/projects/presentation/project_list_filter.dart`, `frontend/lib/features/projects/presentation/project_filters_screen.dart`, `frontend/lib/features/projects/presentation/project_list_criteria.dart`, `frontend/lib/features/projects/presentation/project_list_criteria_controller.dart`, list state/selectors in `frontend/lib/features/projects/presentation/project_list_screen.dart` and `frontend/lib/features/projects/presentation/project_list_view.dart`, filter-route wiring in `frontend/lib/app/router.dart`.
- Do not change: shared `AppSearchField`/choice widgets, project search, pin/unpin, pin ordering, archive data, unrelated record/template filters.

### Rules
- FE-CONS-01, FE-STATE-06, FE-SIMP-01/11, FE-FLOW-04: remove the feature’s controls and hidden predicates without redesigning shared search.

### Steps
1. Per D5, remove the toolbar filter affordance/badge, Projects filter sheets and their status-set/pinned/organisation facet state. Replace criteria with `query` plus `showArchived: false`; false matches active projects, true matches active and archived projects. Ignore obsolete facet values on a restored route; do not migrate project rows.
2. Keep the existing Show archived command in `frontend/lib/features/projects/presentation/project_list_actions.dart`, bound to the single shared `showArchived` flag. Preserve text search and pinned-first ordering. Redirect `/projects/filters` to `/projects` without a broken route. Annotate task063's superseded filter-control requirement while preserving its historical evidence.
3. Remove project-only copy only after checking every reference; retain generic filter/status keys used by other features.
4. Update `frontend/test/features/projects/presentation/project_list_filter_test.dart`, `frontend/test/features/projects/presentation/project_filters_screen_test.dart`, `frontend/test/features/projects/presentation/project_list_screen_test.dart`, `frontend/test/features/projects/presentation/project_list_view_test.dart`, list goldens and router tests. Verify default, archived, pinned, empty, search and legacy-route behavior.

### Acceptance criteria
- [ ] Projects has no filter button, badge, filter sheet, and no filter page; stale filter state cannot silently hide projects.
- [ ] Search, pin ordering and explicit archived-project access work across the matrix; legacy route redirects safely.
- [ ] All five entries are resolved by this single shared Projects change.

## W7 — Remove global queue and transcript shortcuts
**Feedback:** FBK0000171, FBK0000172 · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **After:** W4

### Evidence
- Both screenshots show the same More popup; the messages specifically identify Unprocessed and Transcripts for removal from it.
- `frontend/lib/app/shell_destination.dart:105` defines `moreDestinations`, including queue at `:113` and transcripts at `:119`. `frontend/lib/app/nav_shell.dart:232` and `frontend/lib/features/settings/presentation/settings_screen.dart:90` consume this shared list.

### Scope
- Reach: full matrix, compact More popup and medium/expanded global settings navigation. No platform exclusion.
- Change: `frontend/lib/app/shell_destination.dart`, its consumers, and the affected navigation expectations. W4 already owns root Back behavior; preserve that policy.
- Do not change: queue processing, transcripts, audio, route handlers, project queue/transcript actions and four primary destinations.

### Rules
- FE-SIMP-02, FE-CONS-01/02, FE-RESP-03, FE-SEC-08: navigation removal is not evidence deletion.

### Steps
1. Per D6, remove the two entries from the shared global destination list; retain Templates, Recycle bin and Settings in compact More.
2. Preserve existing global deep links and project-specific queue/transcript links in `frontend/lib/app/router.dart`. Annotate the superseded global-menu requirement in tasks 079/123 and the specification without deleting historical verification evidence.
3. Update `frontend/test/app/nav_more_menu_test.dart`, `frontend/test/app/nav_shell_test.dart`, router tests and `frontend/test/features/settings/presentation/settings_screen_test.dart`. Verify menu cancellation, branch restoration, width changes and saved transcript access.

### Acceptance criteria
- [ ] Both shortcuts are absent globally at every width while project entry points and existing deep links still work.
- [ ] Four primary destinations and W4 Back behavior remain intact; jobs and transcripts are retained.
- [ ] Both entries and all matrix/navigation tests are resolved.

## W8 — Open project packages directly and compact import
**Feedback:** FBK0000168, FBK0000173 · **Type:** Improvement · **Priority:** P4 · **Effort:** M · **After:** W6

### Evidence
- `screenshots/FBK0000173.png` shows the Projects Import a file action; the report asks for Import a Project and direct supported-file selection. `FBK0000168.png` shows generic Import with large introductory artwork and four crowded format descriptions.
- `frontend/lib/features/projects/presentation/project_list_actions.dart:44`, `frontend/lib/features/projects/presentation/project_list_screen.dart:75` and `frontend/lib/features/projects/presentation/project_list_view.dart:131` enter generic import. `frontend/lib/features/import/presentation/import_screen.dart:60` builds its large introduction. Existing `frontend/lib/features/merge/presentation/package_import_flow.dart:42` already provides `startPackageImport`.

### Scope
- Reach: full matrix; native document pickers on Android/iOS/Windows/macOS/Linux and browser file input on web. Folder selection is excluded by D7 because no project-folder importer exists; navigating folders remains native picker behavior.
- Change: the three Projects action sites, `ImportScreen`, existing package flow/controller and `frontend/lib/core/files/document_picker_io.dart`/`frontend/lib/core/files/document_picker_web.dart` only to preserve the supported-type contract.
- Do not change: package validation/merge approval, generic import routes and nested routes, spreadsheet/reference/template import behavior, native file-access permissions.

### Rules
- FE-STR-11, FE-SEC-05/06, FE-PERF-02/07/10, FE-SIMP-01/06/09: reuse the safe importer and keep selection distinct from import approval.

### Steps
1. Per D7, set `projectsImport` to **Import a Project** and call `startPackageImport(context, ref)` directly from both empty and populated Projects. Reuse its controller’s `BundleFormat.extension` = `zip` and `BundleFormat.mimeType` = `application/zip`; do not duplicate the import engine.
2. Keep `/projects/import` for Files settings, mapping/summary retries and merge-history callers. Replace its large hero and permanently expanded format descriptions with a concise title, one Choose file primary action and collapsed `importSupportedFiles` help using `AppSectionHeader`; retain all supported generic formats.
3. Validate extension, signature, size, traversal, manifest and checksums after selection. A generic ZIP is not automatically a project. Cancellation returns to the initiating screen unchanged; valid packages proceed through the existing preview/merge confirmation.
4. Update package-flow and `frontend/test/features/import/presentation/import_screen_test.dart` tests, Projects tests and picker contract tests. Cover supported ZIP, unrelated ZIP, corrupt/traversal package, unsupported extension, cancellation, provider filter fallback and generic xlsx/csv/json paths. Add native picker and browser-file-input integration evidence.

### Acceptance criteria
- [ ] Projects displays the exact requested label and opens the supported-package picker in one action, without the generic introduction.
- [ ] The retained generic Import screen is compact, with expandable format help and all existing routes/formats working.
- [ ] Unsupported selections never enter project storage; cancellations and failures preserve state.
- [ ] Both feedback entries, picker-platform cases and the full matrix pass.

## W9 — Remove repository links from About
**Feedback:** FBK0000183 · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **After:** —

### Evidence
- `screenshots/FBK0000183.png` shows Development plan and Specification below version/build/licences; the report asks to remove repository-related content.
- `frontend/lib/features/settings/presentation/about_screen.dart:68` and `:90` render those two links.

### Scope
- Reach: full matrix, About only. No platform exclusion.
- Change: `frontend/lib/features/settings/presentation/about_screen.dart`, its About-only link helpers and tests; retain referenced shared copy/opener services.
- Do not change: repository files, licences, version/build metadata, release behavior and other external links.

### Rules
- FE-FLOW-04, FE-CONS-01, FE-L10N-01: remove only the approved options and retain shared infrastructure.

### Steps
1. Per D8, remove Development plan and Specification rows plus their About-only URL/open/clipboard plumbing.
2. Retain Version, Build and Licences, including metadata loading/failure states and licence navigation.
3. Update `frontend/test/features/settings/presentation/about_screen_test.dart` and relevant About goldens for absent links, present metadata/licences and the full matrix.

### Acceptance criteria
- [ ] About contains no repository links; version/build/licences remain usable across all states and layouts.
- [ ] No repository documentation is deleted; FBK0000183 is resolved.

## W10 — Remove the Organisation settings shortcut
**Feedback:** FBK0000179 · **Type:** Improvement · **Priority:** P4 · **Effort:** S · **After:** W7

### Evidence
- `screenshots/FBK0000179.png` shows Organisation server/account setup; the short request does not distinguish removing its shortcut from retiring account management.
- `frontend/lib/features/settings/presentation/settings_screen.dart:192` exposes the entry; `frontend/lib/app/router.dart:927` reaches `AccountRoute`, whose unconfigured state opens `ServerAddressForm`.

### Scope
- Reach: full matrix, global Settings navigation; explicit configuration/recovery routes retain their platform behavior. No visual exclusion.
- Change: `frontend/lib/features/settings/presentation/settings_screen.dart` after W7, `frontend/lib/features/settings/presentation/ai_provider_settings_screen.dart` and navigation tests; retain `/more/account`.
- Do not change: server URL configuration, authentication, membership, cached sessions/grants, backend reachability policy and key custody.

### Rules
- FE-SEC-02/04, FE-SIMP-04, FE-STATE-07: removing a shortcut must not make setup mandatory again or erase cached access.

### Steps
1. Per D9, remove only the Organisation row from Settings. Add a secondary **Server and account** (`aiServerAndAccount`) action to AI settings in configured and unconfigured states, opening `RoutePaths.settingsAccount`; W16 retains this action. Keep the existing inline first-sign-in server setup.
2. Verify configured and unconfigured deep links, first sign-in and offline previously signed-in access. No session/configuration writes occur from hiding the row.
3. Update `frontend/test/features/settings/presentation/settings_screen_test.dart`, settings index goldens, router tests and account setup/sign-in tests.

### Acceptance criteria
- [ ] Organisation is absent from Settings across the matrix; explicit setup and existing account links remain functional.
- [ ] Sessions, cached grants and offline capture are preserved; FBK0000179 is resolved under D9.

## W11 — Move relay access into project settings
**Feedback:** FBK0000180 · **Type:** Improvement · **Priority:** P4 · **Effort:** M · **After:** W10

### Evidence
- `screenshots/FBK0000180.png` shows Change relay with a No project message and Open a project action; the report asks to remove it.
- `frontend/lib/features/settings/presentation/settings_screen.dart:205` exposes the global entry, `frontend/lib/app/router.dart:933` opens it, and `frontend/lib/features/account/presentation/relay_route.dart:48` requires current-project context.

### Scope
- Reach: full matrix; relay controls stay subject to the existing platform/service availability. No new relay platform is introduced.
- Change: global `frontend/lib/features/settings/presentation/settings_screen.dart` after W10, `frontend/lib/features/projects/presentation/project_settings_screen.dart`, `frontend/lib/app/route_paths.dart`, `frontend/lib/features/account/presentation/relay_route.dart`, `frontend/lib/features/account/presentation/relay_controller.dart` and router wiring. Reuse the current relay UI/controller.
- Do not change: relay defaults, encryption, consent, queued packages, retention, workers, permissions and offline/manual bundle exchange.

### Rules
- FE-SIMP-06/12, FE-SEC-03/04/08, BE-FLOW-04: preserve optional per-project relay and obtain an independent reader for access-sensitive wiring.

### Steps
1. Per D10, remove Change relay from global Settings. Add its existing labelled action to Project settings using the new `RoutePaths.projectRelay(projectId)` helper for `/projects/:projectId/settings/relay`. Bind the existing relay snapshot/controller to that immutable route project ID through provider families; a later `currentProjectProvider` change must not retarget an open relay action.
2. Keep `/more/relay` compatible: an existing selected project opens its controls, and no selection retains the safe project-selection recovery. Merely navigating must leave relay enablement and its package queue unchanged.
3. Extend settings/router and `frontend/test/features/account/presentation/relay_route_test.dart`; assert project scoping, unchanged enabled state/queue, permission denial, offline behavior and no egress on entry. Retain relay queue/package/merge regression tests.

### Acceptance criteria
- [ ] Global Settings no longer exposes relay; Project settings opens the correct existing controls at every width.
- [ ] Existing links recover safely; encrypted queues/settings are unchanged and navigation triggers no transfer.
- [ ] Independent access-wiring review and applicable platform/matrix tests pass; FBK0000180 is resolved.

## W12 — Collapse advanced capture defaults
**Feedback:** FBK0000181 · **Type:** Improvement · **Priority:** P4 · **Effort:** M · **After:** —

### Evidence
- `screenshots/FBK0000181.png` shows camera, dates, location, quality, folders, naming and context settings competing for space.
- `frontend/lib/features/settings/presentation/capture_settings_screen.dart:70` permanently renders the full form through `:204`.

### Scope
- Reach: full matrix, Capture defaults; no platform exclusion.
- Change: `CaptureSettingsScreen`, existing `frontend/lib/features/settings/presentation/setting_choice.dart`, settings disclosure state, Copy keys `settingsPhotoFiles`, `settingsProjectContexts` and summaries.
- Do not change: persisted values, camera defaults, GPS-off behavior, permission prompts, context rules and the new-files-only meaning of folder/naming changes.

### Rules
- FE-SIMP-06/12, FE-CONS-01/02, FE-STATE-06/07, FE-SEC-07: collapse presentation without rewriting hidden settings.

### Steps
1. Per D11, leave Camera, Automatic dates and Location visible. Use existing `AppSectionHeader` to collapse Photo files (quality, folder strategy, naming) and Project contexts (auto-clear/movement controls), both initially closed with current-value summaries.
2. Add a default-false `alwaysSheet` pass-through to `SettingChoice` and forward it to existing `AppChoiceField`. Use it for capture enumerations inside the collapsed groups; keep stored keys/options unchanged.
3. Reveal idle interval when auto-clear is enabled and movement distance when movement prompting is enabled. Preserve hidden values and expansion state through an in-place rebuild/resize; store disclosure state only for the screen session.
4. Update `frontend/test/features/settings/presentation/capture_settings_screen_test.dart`, `frontend/test/features/settings/presentation/setting_choice_test.dart` and `frontend/test/features/settings/presentation/gps_privacy_section_test.dart`. Add real compact-height fixtures, persistence failures, conditional visibility and matrix goldens.

### Acceptance criteria
- [ ] The initial screen exposes only the specified primary controls plus two collapsed summaries; every existing setting remains reachable.
- [ ] Disclosure/hidden controls leave settings, permissions and existing files unchanged.
- [ ] Stored values survive reopen and failed writes; matrix tests pass and FBK0000181 is resolved.

## W13 — Compact language and speech controls
**Feedback:** FBK0000182 · **Type:** Improvement · **Priority:** P4 · **Effort:** M · **After:** W12

### Evidence
- `screenshots/FBK0000182.png` shows six voice-language rows and long quality controls; `FBK0000182-2.png` shows expanded model inventory, metadata and separate actions.
- `frontend/lib/features/settings/presentation/language_settings_screen.dart:57` uses an always-expanded radio group; `frontend/lib/features/settings/presentation/speech_settings_section.dart:61` and `:254` render full quality/inventory controls.

### Scope
- Reach: full matrix. Existing platform-specific model-import availability is preserved; unsupported native file-path operations remain unavailable on web with existing explanation.
- Change: `LanguageSettingsScreen`, `SpeechSettingsSection`, W12’s `SettingChoice` pass-through and Copy key `settingsSpeechModels` with health summary copy.
- Do not change: the six language tags, quality default, engine policy, model files, verification/removal semantics and on-device-only live speech.

### Rules
- FE-L10N-08/10, FE-SIMP-06, FE-SEC-04, FE-CONS-01, FE-A11Y-07: compact selection must retain speech-health and failure visibility.

### Steps
1. Per D11, replace the radio group with `AppChoiceField<String>(alwaysSheet: true)` using `_voiceLanguages` and `voiceLanguageProvider`. Keep app-language status, selected voice language and transcription quality visible.
2. Use the searchable shared selector for quality. Put model inventory and existing Verify/import/remove controls under collapsed Speech models; show current model and engine status outside it. Keep missing/damaged recovery for the selected engine/model visible without expanding; unavailable unselected models remain within the collapsed inventory.
3. Preserve cancellation, pending operations and state when sections collapse. Disclosure never initiates model downloads, verification and network calls.
4. Update `frontend/test/features/settings/presentation/language_settings_screen_test.dart` and `frontend/test/features/settings/presentation/speech_settings_section_test.dart`; verify language persistence, search, missing/damaged models, in-flight actions, cancellation and existing platform exclusions. Add normal/200-percent corner goldens.

### Acceptance criteria
- [ ] The six-row selector and permanently expanded inventory are replaced by the specified compact controls without losing an action.
- [ ] Speech health/recovery remains visible; locale, quality and model state remain unchanged by disclosure.
- [ ] Matrix, offline speech and platform-availability tests pass; FBK0000182 is resolved.

## W14 — Expose shipped and custom templates globally
**Feedback:** FBK0000170 · **Type:** Gap · **Priority:** P4 · **Effort:** L · **After:** W2

### Evidence
- `screenshots/FBK0000170.png` shows an empty global Templates screen. The report requests shipped templates, creation/editing/customization, and immutable shipped originals with editable derived copies.
- `frontend/lib/features/templates/presentation/template_list_screen.dart:256` returns an empty stream without `currentProjectProvider`; shipped assets live behind a separate picker. `frontend/lib/core/db/tables/templates.dart:17` and `frontend/lib/features/templates/domain/template_def.dart:51` already permit a null project ID.
- `frontend/lib/features/templates/data/shipped_template_loader.dart:437` makes project copies and `:466` retains `source='shipped'`; that tag cannot distinguish an immutable asset from an editable saved copy.

### Scope
- Reach: full matrix, global `/more/templates` and existing project attachment flow, fully offline; no platform exclusion.
- Change: `frontend/lib/features/templates/presentation/template_list_screen.dart`, `frontend/lib/features/templates/presentation/template_create_screen.dart`, existing preview/field editor, `frontend/lib/features/templates/domain/template_repository.dart`, `frontend/lib/features/templates/data/template_repository_impl.dart`, `frontend/lib/features/templates/data/shipped_template_loader.dart`, feature barrels/fakes and router context. Reuse `ShippedPickerScreen`, `ShippedTemplateLoader` and existing `frontend/lib/features/templates/presentation/shipped_library_filter.dart` / `frontend/lib/features/templates/presentation/shipped_library_expanded.dart` state.
- Do not change: bundled JSON, current project-owned rows, template revision/merge contracts, requiredness, source-document files and package formats.

### Rules
- FE-STATE-05/07/08, FE-STR-04/08/09, FE-SEC-08, FE-L10N-07, FE-CONS-01: library ownership is explicit and assets stay immutable.

### Steps
1. Per D12, add `TemplateRepository.watchLibrary(): Stream<List<TemplateDef>>` returning live nondeleted rows with null `projectId`. Global Templates shows shipped catalogue entries and these custom library entries, using existing search/category components and separate asset/saved-entry identity.
2. Enable global blank creation with null project ownership. Add `ShippedTemplateLoader.copyToLibrary({required String templateKey, required String name})` returning a durably saved `Result<TemplateDef>` with fresh IDs, reusing the existing deep-copy logic. Preview shipped entries read-only; provide **Customize a copy** via localized `templatesCustomizeCopy`.
3. Keep project Templates scoped. Add an existing-library selection path that copies the selected custom template into that project with fresh template/field IDs through the current versioned repository flow. Later edits/deletion of the library source cannot mutate attached copies. Reuse W2’s Add template entry.
4. Allow editing and tombstone deletion for saved library copies, including shipped-derived copies. Determine immutability by asset identity, never solely by `source`. Retain the existing delete confirmation and add `TemplateRepository.restore(String id): Future<Result<void>>` for its Undo action, removing the matching tombstone through the existing revision/audit helpers without rewriting captured template versions.
5. Extend `frontend/test/features/templates/presentation/template_list_screen_test.dart`, create/field-editor tests, `frontend/test/features/templates/data/shipped_template_loader_test.dart`, repository contract tests and `frontend/test/features/templates/shipped_template_library_test.dart`. Cover no-project browsing/create/edit, asset byte identity, copy independence, delete/undo, failed local saves, search and project attachment offline.

### Acceptance criteria
- [ ] Global Templates lists shipped assets and editable custom-library rows before a project exists.
- [ ] Shipped originals expose no edit/delete action; customization creates a separate durable editable copy.
- [ ] Project attachment creates an independent versioned copy; existing project templates and package formats are unchanged.
- [ ] Repository/flow/matrix tests pass; FBK0000170 is resolved with no schema migration.

## W15 — Include deleted projects and files in recycling
**Feedback:** FBK0000176 · **Type:** Gap · **Priority:** P4 · **Effort:** L · **After:** —

### Evidence
- `screenshots/FBK0000176.png` shows an empty Recycle bin; the report expects deleted files, records and projects.
- `frontend/lib/features/records/presentation/recycle_bin_screen.dart` watches deleted records only; `frontend/lib/features/records/data/record_queries.dart:680` excludes children of deleted projects. `frontend/lib/features/projects/data/project_repository_impl.dart:659` tombstones project-owned rows and moves native files through `frontend/lib/core/files/project_folders.dart:88`, which has no inverse.

### Scope
- Reach: full matrix; project/record/photo tombstones and all managed attachment kinds in native storage and existing browser stores, including audio and documents. Arbitrary disk files, template deletion and new permanent-purge capabilities are excluded by D13.
- Change: existing recycle-bin presentation, owning project/record/attachment repositories and fakes, tombstone queries, `ProjectFolders` and its platform adapters; add `frontend/lib/core/lifecycle/deleted_entity.dart` and `frontend/lib/core/lifecycle/deleted_entity_kind.dart` for the shared typed projection, and extend the existing `frontend/lib/features/records/presentation/recycle_bin_controller.dart` for aggregation through public feature barrels.
- Do not change: database schema, retention duration, purge eligibility, encrypted bundles, raw bytes, previous independent deletions and task134’s separate transcript-purge work.

### Rules
- FE-SEC-08/09, FE-STATE-05/07/08, FE-STR-04/08/11, FE-PERF-03: recovery is local, audited and ownership-aware; no filesystem guessing.

### Steps
1. Per D13, add typed watch/restore contracts to each owning repository and aggregate their watched deleted projections for the bin. Render shared rows with type, project context, deletion date and Restore. Show deleted projects once, suppress their cascade children, and show independently deleted files only under a live parent.
2. Restore records with existing `RecordRepository.restore`. Add corresponding restoration intents to the owning photo/document/audio repository ports, using existing tombstone/revision/audit helpers. Restore only the selected photo/attachment and cascade-owned dependants, retaining independent child tombstones and shared ownership. Refuse child restore while its parent is deleted; offer the parent restoration action.
3. Add a safe `ProjectFolders.restore(Project)` inverse to the existing recycle operation and adapters. Validate owned paths, refuse collisions, preserve bytes, and coordinate filesystem/browser-store recovery with the database so interrupted operations are retryable and idempotent. Commit a visible restored state only after durable storage and row recovery succeed.
4. For project restoration, clear only project-cascade tombstones matching the existing deletion reason/ownership chain; existing `writeTombstone` preserves older tombstones, so independent deletions stay deleted. Append an audit entry with previous project status when deleting a project from this implementation onward; restore that recorded active/archived status, and use active for legacy deletions without status evidence. Retain existing record-status restoration rules, bump revisions through current helpers and append restoration audit events. Record incomplete/collision recovery visibly; never show an automatic purge countdown for projects/files that have no purge implementation.
5. Keep permanent removal under the existing record-only job. Rename its screen action/copy to **Empty deleted records** (`recycleEmptyRecords`) and include its record count so projects/files cannot appear to be included. Do not add a project/file purge path.
6. Extend `frontend/test/features/records/presentation/recycle_bin_screen_test.dart`, project/record/attachment repository tests, `ProjectFolders` tests and offline integration tests. Cover all kinds, mixed independent/cascade deletions, parent restoration, hash-identical files, existing path collision, interrupted move/transaction, repeated restore, stream updates, permission/storage failure and browser storage.

### Acceptance criteria
- [ ] Deleted projects, records and independently deleted managed files appear with the specified ownership/deduplication rules.
- [ ] Restore is durable, audited, retryable and preserves prior descendant deletions and never overwrites a live file.
- [ ] Raw bytes and retention remain unchanged; permanent removal is explicitly records-only.
- [ ] Real repository/store and offline flow tests pass with the matrix; FBK0000176 is resolved.

## W16 — Configure supported AI providers in a compact flow
**Feedback:** FBK0000177, FBK0000178 · **Type:** Suggestion · **Priority:** P5 · **Effort:** L · **After:** W10, W13

### Evidence
- FBK0000177 requests searchable provider selection, key entry when required and model selection beyond two named providers. FBK0000178 requests a simpler layout; both screenshots show large segments, credential-status failure artwork and competing form actions.
- `frontend/lib/core/ai/server_provider_registry.dart:33`, `backend/src/domain/ai.ts:1`, `backend/src/services/ai/provider-selection.ts:104` and `backend/src/routes/ai-input.ts:15` restrict provider IDs. `backend/migrations/011_ai_processing.sql:5` has the matching database constraint. `frontend/lib/features/settings/presentation/ai_provider_settings_screen.dart:95` starts the crowded controls.

### Scope
- Reach: full matrix, server-backed settings and processing across all existing operations. Support only the two configured protocol families approved in D14; arbitrary new vendor protocols and live model discovery are explicitly excluded. Browser CORS/transport retains its current boundary.
- Change: `backend/src/config/ai.ts`, `backend/src/domain/ai.ts`, `backend/src/services/ai/{provider-selection,proxy,receipts,openai-provider,http_provider}.ts`, `backend/src/services/configuration.ts`, `backend/src/server.ts`, `backend/src/routes/ai-input.ts`, `backend/src/repositories/{store,postgres-ai}.ts`, `backend/openapi.yaml` and a new `backend/migrations/012_ai_provider_catalogue.sql`.
- Change: `frontend/lib/core/backend/server_ai_catalogue.dart`, existing credential client, `frontend/lib/core/ai/server_provider_registry.dart`, registry contracts/fakes, `frontend/lib/main.dart`, `frontend/lib/features/settings/presentation/ai_provider_settings_screen.dart` and its controller.
- Do not change: default `backend` account selection, legacy `personal-gemini`/`personal-openai` IDs, existing credential ciphertext/receipt data, explicit spending approval, evidence consent, offline mode and live on-device speech. Add no dependency.

### Rules
- FE-SEC-01/02/03/04/05, FE-STATE-06/07, FE-SIMP-01/06; BE-AI-01–10, BE-SEC-01/05/06/11, BE-FLOW-03/04: configurable providers must preserve custody, identity, quotas and explicit user actions.

### Steps
1. Per D14/D15, parse administrator-only `AI_PROVIDER_CATALOGUE` as an array of objects with string `id`, `label`, `protocol` (`gemini-generate-content`/`openai-responses`), `baseUrl`, `authMode` (`required`/`none`), string-array `models`, string-array `operations` restricted to wire values `ocr`, `extract`, `refine`, `transcribe` (mapped to Dart `readText`, `extractFields`, `refineText`, `transcribe`), string `model` naming the base model, `currency: "configured"` as the sole accepted cost unit, and `modelCostCeilings: Record<string, number>` containing one positive finite ceiling per model. Reject duplicate IDs/models, unknown operations/protocols, missing model costs and URLs containing credentials/query/fragment. Absent/empty configuration keeps the legacy Gemini/OpenAI entries; nonempty configuration adds entries and rejects collisions with those retained IDs. Document the exact format and a keyless example in `backend/RUNBOOK.md`; configuration contains no provider secret values.
2. Dispatch existing adapters by configured protocol rather than a two-value provider name. Retain HTTPS, exact configured hosts and `redirect: 'error'`; never accept device-provided endpoints. Preserve payload validation, bounded retries/circuit breaker, cancellation, permissions and budgets. With auth-none omit `Authorization` and `x-goog-api-key` headers entirely. Guard secret-echo checks against an empty key; never interpolate imported content as instructions.
3. Extend `/api/v1/ai/providers` rows with `label`, `protocol`, `authMode` and `operations`, retaining existing `provider`, `model`, `models`, `modelCostCeilings`, `requestCostCeiling`, `currency`, `managed` and `personalConfigured` fields. Derive keyless availability from `authMode`, not a fabricated stored credential. Expose neither endpoints nor secret references/values. Update OpenAPI, validators, repository types and frontend parser together. Keep unknown/removed selections explicit and unavailable, never silently reroute billing.
4. Add forward migration 012 to widen the provider-ID constraint while preserving all 011 credential rows, ciphertext, request checkpoints and receipts. Do not edit migration 011. Test 011 → 012 against seeded PostgreSQL and exact before/after row values; do not run the migration against production.
5. Keep key-required personal accounts on existing authenticated server credential custody. Add deterministic `personal-<providerId>` and `keyless-<providerId>` descriptors for required/none respectively; keyless uses managed billing bound to that exact configured provider, bypasses credential lookup in availability and transactional proxy checks, and retains all quotas/permission checks. Bind every new receipt/account identity to provider ID plus configuration fingerprint. For legacy built-in IDs only, compute the previous binding solely to recognize an already-stored receipt and return its existing recovery outcome without dispatching a new provider request; never use the old hash as a fallback for new work. Reject mismatched endpoint/protocol/account/model reuse.
6. Build the shared registry from validated cached catalogue metadata. Update both the processing worker and Settings after catalogue refresh; `frontend/lib/main.dart` must not leave processing with an old registry captured at startup. Offline uses the last validated metadata and disables outbound operations through existing gates; missing metadata produces recovery without blocking capture.
7. Per D14, render provider → required credential → model using `AppChoiceField(alwaysSheet: true)`. Label the catalogue **Supported providers** (`aiSupportedProviders`), keep one concise custody explanation, secondary Test connection and one primary Save. Put cost controls under collapsed `AppSectionHeader` with current-limit summary; preserve explicit escalation approval. Use `AppBanner` for recoverable credential errors. Keyless accounts hide key controls and never call credential endpoints. Secret input is obscured/ephemeral and cleared after successful save; changing selection does not save it.
8. Extend backend config, adapter, proxy/credential/receipt, PostgreSQL, route and contract tests; fixtures cover a third provider for each existing protocol, keyless mode, invalid config/model/provider, auth denial, no secret echo, quota/cancellation, delayed/replayed responses and failed migration. Extend frontend `frontend/test/core/ai/provider_registry_test.dart`, catalogue/client tests, `frontend/test/features/settings/presentation/{ai_provider_settings_screen,server_ai_settings,provider_test_action}_test.dart` and AI settings goldens. Test late metadata refresh updates processing as well as UI, failed/removed providers, cancellation and offline cached selections.
9. Run `npm run verify` from `backend/`, the frontend regressions and matrix. Produce the code/contract diff, migration row-preservation results and fake-egress evidence for the independent review below.

### Review stop
⛔ Stop after step 9 and before marking W16 complete. Show the provider/custody/egress diff, OpenAPI changes and seeded migration results to a second reader. Proceed to acceptance only with explicit recorded review under `backend/.rules/05-security.md` BE-SEC-11 and `backend/.rules/11-workflow.md` BE-FLOW-04. This is a review of produced code; no production deployment is authorized.

### Acceptance criteria
- [ ] Configured providers for both existing protocols appear in the shared searchable catalogue with correct models/capabilities; unsupported protocols are rejected without a universal-compatibility claim.
- [ ] Existing selections, ciphertext and receipts survive the real PostgreSQL migration; unknown/removed accounts never silently switch billing.
- [ ] Keyless routing has no credential lookup, preserves exact provider/account identity and applies the same quotas/permissions; endpoints remain administrator-only and secrets never leave custody.
- [ ] Provider selection/search never invokes an external model; existing authenticated metadata refresh remains offline-gated, and testing/credential writes require explicit actions.
- [ ] Late catalogue updates reach processing and Settings, offline capture remains available, and compact UI/error/recovery behavior passes the full matrix.
- [ ] Backend verification, frontend/contract/integration tests and independent security review pass; FBK0000177 and FBK0000178 are resolved under D14/D15.

## Verification
- Recheck every cited code location against the implementation tree before editing. The evidence here is static inspection, not a claim that application tests were run during prompt generation. Each entry is unresolved as of the inspected tree; duplicates share W6.
- Run each item’s named unit, repository, widget and integration checks at its specified layer. Use the local `frontend/test/support/` factories and fakes; no live AI requests. Validate filesystem/DB restoration and PostgreSQL migration with their actual test storage engines, not mock-only success.
- From `frontend/`, run `dart format --output=none --set-exit-if-changed` on this task’s changed Dart files, `flutter analyze`, the changed suites with `flutter test`, `flutter test test/responsive`, and the existing affected architecture/security suites. Run the named native/browser integration checks on their required targets. A skipped platform/database test is not acceptance evidence; record Partially complete when required verification remains unavailable.
- Regenerate goldens with `--update-goldens` only for each item’s intentional visual changes and list exact regenerated paths in that item’s implementation evidence. Do not update unrelated baseline failures. Exercise all three themes at normal/200-percent text, representative compact/medium/expanded portrait/landscape corners and pseudo-locale expansion. Check keyboard, focus, insets, screen-reader labels and contrast.
- Run `dart run tool/check_l10n.dart`, `dart run tool/generate_pseudo_locale.dart --check` and `dart run tool/check_plan.dart`. Preserve every existing guardrail; this prompt authorizes no rule/checker change. Flutter has **no review command**: do not add `frontend/tool/verify.dart`.
- From `backend/`, `npm run verify` must be green for W16, including format, lint, types, unit/integration/contract checks. Record the real PostgreSQL migration run and independent security/access review; absence of either leaves the relevant acceptance open.
- Update only verified acceptance items in the new plan task, retaining explicit notes for unfinished work. After every implementation/status update run, from `frontend/`, `dart run tool/sync_dev_tracker.dart`, then `dart run tool/sync_dev_tracker.dart --check`. Include the generated tracker changes with this task; never hand-edit it and never stage unrelated user changes automatically.
- Finish with a per-item acceptance report, exact test results, changed golden paths, approved decisions and remaining prerequisites. This prompt does not certify repository-wide release readiness or close final hardening task 023.
