# 076 — Resolve project, capture and template feedback, and add project packages

**Phase** 23 · Hardening  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

Close FBK0000006 and FBK0000007 from the 27 September 2026 08:43 archive, FBK0000156 to FBK0000162 from the 08:45
archive, and the operator's three requests made with them: R1, the project export writes one ZIP holding everything
another Tapture app needs; R2, another app imports that ZIP as a new project or merges it into a project built from
compatible templates after a compatibility check; R3, an optional duplicate check that a person decides. FBK0000002
to FBK0000005 in the 08:43 archive were already closed by task 070.

The executable prompt is `prompts/feedback-27092026-0845/001-resolve-project-capture-package-feedback.md`.
Decisions D1–D17 use the defaults in that prompt, (a) in every case:

- D1: `AppForm.onSubmit` returns `Future<bool>`; `true` clears the form's unsaved mark.
- D2: the open project's row has the `surfaceVariant` fill, a 4dp `primary` start bar, a `primary` title and is
  announced as selected.
- D3: the Project contexts page loses its level-name diagram; each level row carries one overflow menu.
- D4: Save raw and Save and process share one row at equal width at every width; FE-SIMP-01 reads "No other control
  is larger".
- D5: an in-house document picker mirroring `FolderPicker`; no new dependency.
- D6: native packages stream to disk under `AppConstants.bundles.nativeMaxBytes` (4,000,000,000 bytes) and are
  delivered by a streamed copy; web builds in memory under 200 MiB.
- D7: the package carries every project-owned table and file, and leaves out capture drafts, the processing queue,
  caches, export history, device settings, the operator profile and secure storage.
- D8: a read-only project page at `/projects/<id>/details`; the form is "Edit project" and returns there.
- D9: "Edit fields" moves from the record page's overflow to its Fields heading.
- D10: on the Capture tab the shell's context bar shows every level, set or not, and Manage.
- D11: the library's categories collapse, with counts, collapsed by default.
- D12: ranked on-device description search now; AI suggestions are task
  [077](077-suggest-shipped-templates-with-ai.md).
- D13: one export, the ZIP package, carrying the workbook as `records.xlsx`.
- D14: a collapsed "What to capture" row, and a caption panel while typing, dictating or recording.
- D15: a merge is blocked when a used template has no match or a filled field is missing or cannot hold its values.
- D16: the merge settles by content with §47's rules and a person; no version vectors, no undo (task 019).
- D17: the duplicate check is on by default, runs before the write, and offers Keep both or Don't import.

FBK0000158 supersedes task 070's decision (W8, from FBK0000004) that Save and process is twice as wide.

Deviations from the prompt, each smaller or safer than what it replaces:

- W13: the record page's Fields heading carries "Edit fields" as an icon button with a tooltip, not a text button;
  the text button overflowed the heading at 200 % text.
- W16: the ranking also drops the English connectives ("and", "the", "with"…) a description carries, which would
  otherwise match every template.
- W21: a merge writes the new files straight to paths no other file uses (a path already on disk moves under
  `_merged/`), each checked against the package's checksum, before the one transaction; any failure removes them.
  This replaces the `imports/<bundleId>/` staging folder and the move after the commit, which could leave rows
  pointing at files that never arrived.
- W21: a person's "Keep this device's" is stored with the conflict, so merging the same package again raises
  nothing; planning is `MergePlanner.plan(incoming, local, templateMapping, …)`, with the mapping taken from
  W20's `CompatibilityReport`.
- W22: the pair type is `PossibleDuplicate`, since Drift already names the stored row `DuplicatePair`. Only the
  scoring moved to `core/normalise/fuzzy_matcher.dart`; its reference-row ranking became a generic `rank`.
- W19: `PickedFile.isCopy` marks the picker's own copy on Android and iOS, so the flow deletes that copy and never
  the operator's file on a desktop.

## Files

- Plan: this task, [077](077-suggest-shipped-templates-with-ai.md), [078](078-keep-device-id-in-storage-root.md),
  `dev-plan/23-hardening/README.md`, `dev-plan/INDEX.md`, `dev-plan/08-projects/008-projects.md`,
  `dev-plan/18-export/018-export.md`, `dev-plan/19-bundles-and-merge/019-bundles-and-merge.md`,
  `frontend/.rules/06-simplicity.md`
- Native: `frontend/android/app/src/main/kotlin/com/tapture/app/MainActivity.kt`,
  `frontend/ios/Runner/AppDelegate.swift`
- App: `frontend/lib/main.dart`, `frontend/lib/app/nav_shell.dart`, `frontend/lib/app/route_paths.dart`,
  `frontend/lib/app/router.dart`
- Core: `frontend/lib/core/bundle/` (new: format, entry, manifest, tables, output, writer, zip jobs, reader,
  rejection, inspected bundle, template key), `frontend/lib/core/files/` (document picker and its platforms,
  picked document, file and bytes, archive problem, `file_validation.dart`, download service and its platforms),
  `frontend/lib/core/normalise/` (`search_text.dart`, `fuzzy_matcher.dart` moved from `features/reference`),
  `frontend/lib/core/constants/app_constants.dart`, `frontend/lib/core/copy/copy.dart`,
  `frontend/lib/core/widgets/` (`app_list_tile.dart`, `app_section_header.dart`, `app_icons.dart`,
  `forms/app_form.dart`, `responsive/responsive_pair.dart`, `fields/app_text_field.dart`,
  `fields/app_number_field.dart`, `fields/field_editor.dart`, `gallery/widget_gallery_screen.dart`)
- Capture: `capture_screen.dart`, `capture_guide_card.dart`, `capture_guide_state.dart`, `record_caption_field.dart`
- Context: `context_bar.dart`, `context_hierarchy_screen.dart`
- Exports: `export_repository.dart`, `export_repository_impl.dart`, `export_file_name.dart`
- Merge: `features/merge/domain/` (compatibility, conflicts, settlement rules, plan and planner, import port,
  presence), `features/merge/data/` (`package_files*.dart`, `package_import_repository_impl.dart`),
  `features/merge/presentation/` (import controller, phase and flow, merge controller and view, preview, conflict
  screen, duplicate pair sheet, target sheet, compatibility pill, labels), barrels
- Projects: `current_project.dart`, `project_details_screen.dart`, `project_edit_screen.dart`,
  `project_create_screen.dart`, `project_settings_screen.dart`, `project_home_screen.dart`,
  `project_list_actions.dart`, `project_list_screen.dart`, `project_list_view.dart`, `project_list_filter.dart`,
  `project_export_screen.dart`, `export_summary_view.dart`, `record_detail_screen.dart`, `record_edit_sheet.dart`,
  `record_field_draft.dart`, `record_field_input.dart`, `record_field_sheet.dart`
- Quality: `duplicate_signal.dart`, `duplicate_signals.dart`, `possible_duplicate.dart`, barrels
- Reference: `domain/domain.dart` (the matcher moved out)
- Settings: `app_lock_screen.dart`, `operator_profile_screen.dart`; Feedback: `give_feedback_screen.dart`
- Templates: `capture_guide.dart`, `shipped_search_document.dart`, `shipped_template_ranking.dart`,
  `shipped_library_expanded.dart`, `shipped_picker_screen.dart`, `template_create_screen.dart`,
  `field_add_sheet.dart`, `templates.dart`
- Tests: `test/core/bundle/`, `test/core/files/document_picker_test.dart`, `download_service_test.dart`,
  `test/core/normalise/search_text_test.dart`, the widget tests of the list tile, section header, number field,
  form and responsive pair, their gallery goldens and the catalogue golden, `test/app/nav_shell_test.dart`, capture,
  context, exports, merge (planner, compatibility, repository, preview, import flow), processing
  (`key_custody_test.dart`), projects, quality, reference and templates suites, and
  `test/support/bundle_fixture.dart`, `fakes/fake_export_repository.dart`,
  `fakes/fake_package_import_repository.dart`

## Definition of done

- [ ] W1 — A project save reports "Project saved" and leaving asks nothing; a failed save keeps its guard; an
      archived project stays editable; every `AppForm` returns its outcome.
- [ ] W2 — The expanded pane's border is drawn in front of its rows; the open project's row carries the current
      marker (fill, start bar, title colour, selected semantics).
- [ ] W3 — Project contexts is inset by the gutter, has no diagram, no default drag handles and one overflow menu
      per level row.
- [ ] W4 — `ResponsivePair.stacksOnCompact` and `matchesHeights`.
- [ ] W5 — `foldSearchText`, `searchWords` and `searchStem` in `core/normalise/search_text.dart`.
- [ ] W6 — `AppSectionHeader.expanded`/`onToggle` and `AppIcons.collapse`.
- [ ] W7 — `DocumentPicker` on Android, iOS, Windows, macOS, Linux and web.
- [ ] W8 — `DownloadService.saveStored` and `openStoredExternally`, exports folder only.
- [ ] W9 — `BundleWriter` writes the package on native (streamed) and web (in memory).
- [ ] W10 — `BundleReader.inspect` refuses each `BundleRejection` and accepts a written package.
- [ ] W11 — A read-only project details page; the form is "Edit project" and returns to it after a save.
- [ ] W12 — Capture's saves share one equal row at every width; the offline line sits under the row.
- [ ] W13 — A tap on a record field edits it with a typed input; "Edit fields" sits on the Fields heading.
- [ ] W14 — On Capture the context bar shows every level, set or not, plus Manage or Set up context.
- [ ] W15 — The shipped library groups templates into collapsible, counted categories.
- [ ] W16 — The shipped library ranks a description by relevance, offline.
- [ ] W17 — Export writes the package with `records.xlsx` inside, delivered as a stored file on native.
- [ ] W18 — Capture shows a guide built from the template, and the caption panel while typing or recording.
- [ ] W19 — "Import a project" imports a package as a new project, all or nothing.
- [ ] W20 — A compatibility report precedes every merge; an incompatible target cannot be chosen.
- [ ] W21 — A package merges into a project after a preview and a person's conflict choices, all or nothing.
- [ ] W22 — The merge preview checks for possible duplicates, and a person decides each pair.
- [ ] Tests:
- [ ] [077](077-suggest-shipped-templates-with-ai.md) and [078](078-keep-device-id-in-storage-root.md) are in the
      plan.
