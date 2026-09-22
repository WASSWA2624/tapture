# 008 — Projects: the container that owns everything else

**Phase** 08 · Projects  |  **Depends on** [001](../01-orchestration/001-project-setup.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The whole of `features/projects/`: the immutable `Project` with its status, dates and validated settings type, the
mapper that folds organisation and the dates onto the row's `client`, `startedAt` and `completedAt` columns and keeps
the description inside the settings JSON, the repository implementation behind the interface the data layer declares,
the feature barrel and the hand-written fake every later project screen tests against; the landing list that shows
each project once with its record count, unprocessed count and last-worked time, most recently worked first, from one
watch query, beside `CurrentProject`, the single persisted source of the open project id that restores on launch and
clears an id that no longer resolves; the short create form and the duplicate action, both running one transaction
that writes the row, its folder tree and its default Site context definition, or copies an existing project's
structure under a new id and a new folder without carrying a single record; the open-project home that answers "what
should I do next" with the pinned context, one dominant *Continue capturing* action and a subordinate row of count
cards that each link to the list they count; the details and per-project settings screens, where a rename changes the
display name only and every switch is an override that falls back to the app default; and the two ways a project
leaves the active list — an archive that is reversible and loses nothing, and a delete that takes the project name
typed by hand, writes one tombstone per owned entity and moves the folder into the recycle area, removing not a byte
at the moment the user taps. No presentation code in this phase or after it sees a database type. Later
field-feedback work is included: home and list management actions, hiding the unbuilt import button, the archived
checkbox, dictation on project fields, redesigned home count cards, pinning, and numbered list actions.

## Files

Domain, data and the fake:

- `frontend/lib/features/projects/domain/project.dart` (new)
- `frontend/lib/features/projects/domain/project_status.dart` (new)
- `frontend/lib/features/projects/domain/project_settings.dart` (new)
- `frontend/lib/features/projects/data/project_mapper.dart` (new)
- `frontend/lib/features/projects/data/project_repository_impl.dart` (new)
- `frontend/lib/features/projects/projects.dart` (new)
- `frontend/test/features/projects/fakes/fake_project_repository.dart` (new)

The landing list and the open project:

- `frontend/lib/features/projects/presentation/project_list_screen.dart` (new)
- `frontend/lib/features/projects/presentation/current_project.dart` (new)

Creating and duplicating:

- `frontend/lib/features/projects/presentation/project_create_screen.dart` (new)
- `frontend/lib/features/projects/presentation/project_duplicate_action.dart` (new)

The open-project home:

- `frontend/lib/features/projects/presentation/project_home_screen.dart` (new)

Details and per-project settings:

- `frontend/lib/features/projects/presentation/project_edit_screen.dart` (new)
- `frontend/lib/features/projects/presentation/project_settings_screen.dart` (new)

Leaving the active list:

- `frontend/lib/features/projects/presentation/project_archive_action.dart` (new)
- `frontend/lib/features/projects/presentation/project_delete_action.dart` (new)
- `frontend/lib/features/projects/presentation/project_list_screen.dart` (changed in step 6, for the archived filter)

Follow-up files:

- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/features/projects/presentation/project_home_screen_test.dart`
- `frontend/test/features/projects/presentation/project_list_screen_test.dart`
- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/core/copy/copy_test.dart`
- `dev-plan/20-data-import/222-import-entry.md`
- `frontend/test/features/projects/presentation/project_archive_action_test.dart`
- `frontend/test/features/projects/presentation/project_create_screen_test.dart`
- `frontend/test/features/projects/presentation/project_edit_screen_test.dart`
- `frontend/test/features/projects/presentation/project_delete_action_test.dart`
- `frontend/lib/core/db/tables/projects.dart`
- `frontend/lib/core/db/migrations.dart`
- `frontend/lib/core/db/app_database.dart`
- `frontend/lib/features/projects/domain/project_repository.dart`
- `frontend/test/support/factories.dart`
- `frontend/test/core/db/migrations_test.dart`
- `frontend/test/core/db/tables/projects_test.dart`
- `frontend/test/features/projects/data/project_repository_impl_test.dart`
- `frontend/test/features/projects/data/project_mapper_test.dart`
- `frontend/lib/features/projects/presentation/project_list_actions.dart`
- `frontend/lib/features/projects/presentation/project_rename_action.dart`
- `frontend/lib/features/projects/presentation/project_list_view.dart`
- `frontend/test/app/nav_pane_golden_test.dart`
- `frontend/test/features/projects/presentation/project_list_view_test.dart`
- `frontend/test/features/projects/presentation/project_rename_action_test.dart`
- `frontend/test/features/projects/presentation/project_list_golden_test.dart`


## Contract

```dart
enum ProjectStatus { active, archived, deleted }

final class Project {
  const Project({
    required this.id, required this.name, required this.status, required this.folderName,
    required this.settings, required this.createdAt, required this.updatedAt,
    this.description, this.organisation, this.startsOn, this.endsOn,
  });
  Project copyWith({String? name, String? description, String? organisation, ProjectStatus? status,
      DateTime? startsOn, DateTime? endsOn, ProjectSettings? settings});   // no folderName entry
}

/// Every switch is nullable; null means "use the app default".
final class ProjectSettings {
  factory ProjectSettings.decode(String raw);          // unknown or missing shapes default, never throw
  factory ProjectSettings.fromJson(Object? json);
  Map<String, Object?> toJson();
  ProjectSettingsResolved resolve(ProjectSettingsDefaults app);
}

/// Members the implementation fills in for the interface declared by 004 · Local database.
abstract interface class ProjectRepository {
  Stream<List<Project>> watchAll({bool includeArchived = false});
  Stream<List<ProjectListRow>> watchList({bool includeArchived = false});
  Stream<ProjectHomeCounts> watchHome(String projectId);
  Future<Result<Project>> create(Project project);
  Future<Result<Project>> createReady({
    required String name, String? description, String? organisation, String? sourceId,
  });
  Future<Result<void>> update(Project project);
  Future<Result<void>> setStatus(String id, ProjectStatus status);
  Future<Result<ProjectOwnedCounts>> ownedCounts(String id);   // records and files a delete would hide
  Future<Result<void>> delete(String id);
}

typedef ProjectListRow = ({Project project, int recordCount, int unprocessedCount, DateTime lastWorkedAt});
typedef ProjectHomeCounts = ({int review, int process, int toExport, int toShare});
typedef ProjectOwnedCounts = ({int records, int files});

final projectRepositoryProvider = Provider<ProjectRepository>(...);

final class CurrentProject extends Notifier<String?> {
  void open(String projectId);
  void close();
}

final currentProjectProvider = NotifierProvider<CurrentProject, String?>(CurrentProject.new);
final openProjectIdProvider = currentProjectProvider;          // an alias, never a second source
final currentProjectDetailsProvider = Provider<Project?>(...);
```

## Steps

1. Land the domain model and the repository. `Project` carries status, display name, description, organisation, start
   and end dates, settings and `folderName`; `folderName` is set at creation and has no setter and no `copyWith`
   entry. `ProjectSettings` parses and serialises the row's validated JSON, rejecting unknown shapes and defaulting
   missing values rather than throwing. `project_mapper.dart` maps both directions, folding organisation and the dates
   onto the row's `client`, `startedAt` and `completedAt` columns and keeping the description in the settings JSON,
   because the table carries no column of its own for it; the repository implementation is the only file importing
   both the table and the domain. The barrel exports only `Project`, `ProjectStatus`, `ProjectSettings` and
   `projectRepositoryProvider`, leaving the mapper and the implementation internal, and the fake honours the same
   contract as the implementation, watch stream included.
2. Land the landing list and the open project. One `watchList` query returns the record count, the unprocessed count
   and the last-worked time with the rows, served by the `status` plus `updatedAt` index the projects table declares,
   so there is no query per row. Rows render with `AppListTile` and all four states through `AsyncValueView`; the empty
   state offers "Create a project" and "Import a bundle". `CurrentProject` persists the open id under the declared
   `SettingKeys.openProjectId` key in `settings_store.dart`, restores it on launch, clears an id that no longer
   resolves and stays on this screen rather than failing, and is the one source `openProjectIdProvider` aliases.
   Opening a row sets `CurrentProject` and then honours the destination the router guard carried, so a diverted deep
   link resumes.
3. Land create and duplicate. The form asks for name, optional description and optional organisation; everything else
   is defaulted, not asked (FE-SIMP-05). `createReady` derives `folderName` through `project_folders.dart`, then
   writes the row, the eight-folder tree and a default Site context definition in one transaction; a failed folder
   write discards the partial tree and rolls the row back, so a half-created project is impossible. Duplicate copies
   templates, context definitions, project-scoped reference data and project settings under a new id and a new folder
   tree, and copies no records, no photos and no audio; the suggested name is editable before the copy commits.
   `ProjectCreateScreen` and `ProjectDuplicateAction` both route through `createReady`, so there is one transaction
   boundary and one rollback route for both entry points, and success opens the new project by setting
   `CurrentProject`.
4. Land the open-project home. It reads the project from `currentProjectDetailsProvider` and holds no id of its own.
   The header shows the pinned context; Review, Process, Export and Share are `AppCard`s carrying their pending counts
   from one `watchHome` watch, each number tappable and routed through `AppRoutes` to its filtered list. "Continue
   capturing" is the single primary action, in the lower third and within thumb reach on a large phone. The pending
   totals stay in the global status line rather than being repeated verbatim here.
5. Land details and per-project settings, two `AppForm` screens over the same row. Details write name, description,
   organisation, dates and status and never touch `folderName`, so every existing file path keeps resolving and no
   file moves. The settings screen persists nullable overrides — AI enabled, do-not-send-images, GPS, folder strategy,
   confidence thresholds and refined columns — in the project's validated settings JSON on its own row, never in the
   app settings store; an unset value resolves to the app default from `settings_store.dart`, clearing an override
   returns it to that default, and each override row states what the app-level default currently is. Status here
   writes the same field the archive action writes, so the two can never disagree. Both screens take the
   unsaved-changes guard and the error summary from the design system, and AI off with do-not-send-images on refuses
   every provider call and every image egress for that project.
6. Land archive, unarchive and delete. Archive sets `ProjectStatus.archived`; the list screen gains a "Show archived"
   filter that hides them by default and default exports exclude them, and unarchive restores the project with
   records, files and settings untouched. Delete confirms once through `showAppConfirm` in its destructive form,
   naming the record and file counts from `ownedCounts`, requiring the project name typed by hand and offering
   "Export first" in the same dialog — one decision, no dialog chain. It sets `ProjectStatus.deleted`, soft-deletes
   the owned rows and writes exactly one tombstone per entity through the helper in `tombstones.dart`, all in one
   transaction, then moves the project folder into the `.recycle` area. The retention window comes from
   `AppConstants`; only the purge job removes files, and only once it expires.

## Constraints

- Nothing under `domain/` imports Flutter, Drift or a HTTP client, and one public type lives per file, named after the
  type (FE-STR-05, FE-STR-06).
- The fake honours the same contract as the implementation, including the watch stream, so later screens never need a
  database (FE-STATE-10).
- One source of truth for the open project: no screen, controller or service keeps its own copy of the id
  (FE-STATE-06).
- Counts come from the watch queries and the database indexes, never from a loop or a timer, and they are derived
  rather than stored, so they cannot disagree with the lists they link to (FE-STATE-06, FE-PERF-03, FE-PERF-06).
- The two-second landing claim is asserted by a measurement, not assumed (FE-TEST-09).
- The row and the folder tree succeed or fail together; a half-created project must be impossible (FE-STATE-07).
- The folder tree is only ever created through `project_folders.dart`; no screen touches the filesystem directly
  (FE-STR-11).
- Exactly one primary action on the home screen; the secondary row is visibly subordinate (FE-SIMP-01, FE-A11Y-09).
- The project row is the source of truth for project settings; the app store is only the default supplier
  (FE-STATE-06).
- Turning AI off and do-not-send-images on must genuinely stop every provider call for that project (FE-SEC-03).
- Archiving and deleting never destroy evidence. Archiving only changes a status, deletion is a tombstone plus a move,
  and no file is unlinked in the user's request path (FE-SEC-08, rule 1 of the standard).
- The destructive confirmation names the consequence and the counts and comes from the one dialog API
  (FE-SIMP-07, FE-CONS-05).

## Definition of done

- [x] Presentation compiles with no `core/db` import anywhere under `features/projects/presentation/`.
- [x] Unknown or missing settings JSON loads as defaults instead of throwing.
- [x] Opening the app lands on the project list with counts rendered in under two seconds on the reference device.
- [x] Reopening the app returns to the last opened project without asking; a deleted last project clears cleanly.
- [x] Loading, empty, populated and failure all render through `AsyncValueView` on the list.
- [x] A project exists and is ready for capture after one screen.
- [x] A failed folder creation leaves no project row and no partial folder tree.
- [x] A duplicate has zero records and identical structure — same template, context and reference counts, new id, new
      folder.
- [x] Every number on the home screen is tappable and lands on the matching list, already filtered.
- [x] One primary action on the home screen, in the lower third, usable one-handed.
- [x] Loading, empty, populated and failure all render through `AsyncValueView` on the home screen.
- [x] Existing file paths keep working after a rename, and no file is moved or copied.
- [x] A project can be made fully manual and offline with two switches.
- [x] An override wins over the app default, and clearing it falls back to that default.
- [x] Archiving is reversible and loses nothing; an archived project is absent from the active list and from default
      exports.
- [x] A mistaken delete is recoverable for the whole retention period, with its files still on disk in the recycle
      area.
- [x] Deleting writes exactly one tombstone per deleted entity, inside the delete transaction.
- [x] Tests: `frontend/test/features/projects/data/project_mapper_test.dart` round-trips row → `Project` → row,
      including organisation and the dates on `client`, `startedAt` and `completedAt` and the description in settings.
- [x] Tests: `frontend/test/features/projects/domain/project_settings_test.dart` asserts unknown and missing JSON
      loads as defaults and that overrides serialise back unchanged.
- [x] Tests: `frontend/test/features/projects/project_repository_contract.dart` holds the create, watch and
      status-change suite, run against an in-memory database by
      `frontend/test/features/projects/data/project_repository_impl_test.dart` and against the fake by
      `frontend/test/features/projects/domain/project_repository_test.dart`.
- [x] Tests: `frontend/test/features/projects/presentation/project_list_screen_test.dart` covers all four
      `AsyncValueView` states and measures the landing budget.
- [x] Tests: `frontend/test/features/projects/presentation/current_project_test.dart` asserts a persisted id is
      restored, an unresolvable one is cleared, and a carried destination resumes.
- [x] Tests: `frontend/test/features/projects/presentation/project_create_screen_test.dart` covers the form's
      validation and failure states and the rollback against a failing folder-service fake.
- [x] Tests: `frontend/test/features/projects/presentation/project_duplicate_action_test.dart` asserts a record count
      of zero and equal structure counts against the source project.
- [x] Tests: `frontend/test/features/projects/presentation/project_home_screen_test.dart` covers all four
      `AsyncValueView` states plus a navigation assertion that each count reaches its route with the right filter.
- [x] Tests: `frontend/test/features/projects/presentation/project_edit_screen_test.dart` covers populated, dirty and
      failure states and asserts a rename leaves `folderName` unchanged.
- [x] Tests: `frontend/test/features/projects/presentation/project_settings_screen_test.dart` covers populated, dirty
      and failure states and asserts override-then-fallback resolution.
- [x] Tests: `frontend/test/features/projects/presentation/project_archive_action_test.dart` covers archive,
      unarchive and the archived filter on the list.
- [x] Tests: `frontend/test/features/projects/presentation/project_delete_action_test.dart` covers the typed-name
      confirmation, the cancel path and "Export first", and asserts the delete writes one tombstone per owned entity
      and that no file disappears immediately.

### Follow-up work

#### Add project management actions

- [x] With one or more projects, the list shows "Create a project", and it opens `/projects/new`.
- [x] From a project home: All projects shows the list; New project opens the create form; Project details and Project
      settings open their screens.
- [x] Archive or Delete from the home runs the existing confirmation and then shows the list.
- [x] Opening another row from the list makes it the current project, and capture follows it.
- [x] Tapping Projects on a project home shows the list, at compact, medium and expanded widths.
- [x] Tests: each home menu item reaches its route; Archive and Delete land on the list; the menu meets the label and
      48 dp matchers; Create shows with zero, one and many projects; Project details opens `/projects/<id>/edit`; tapping
      Projects while on a project home shows the list at 400, 800 and 1200 dp.

#### Hide the unbuilt project import button

- [x] The empty Projects list shows "Create a project" and no import control.
- [x] The empty message reads "Create a project to start capturing."
- [x] `Copy.projectsImport` reads "Import a project", and task 222 records where it returns.
- [x] Tests: the empty state shows Create and no import control; tapping Create opens the form; the new copy values
      pass the vocabulary checks.

#### Use a checkbox for Show archived

- [x] Projects shows a checkbox labelled "Show archived", unticked by default.
- [x] Ticking it lists archived projects, and unticking hides them again.
- [x] The label no longer sits flush against the screen edge, and the row is inset like other tiles.
- [x] Tests: ticking shows archived rows and unticking hides them; the tile passes the 48 dp and
      label matchers; no overflow at 360 dp and 200 percent text.

#### Enable dictation on project fields

- [x] New project and Project details show a microphone on Name, Description and
      Organisation, and dictation fills the field.
- [x] With Stay offline on, dictation uses on-device recognition or shows the existing
      plain message.
- [x] Excluded fields still show no microphone.
- [x] Tests: the three fields offer a microphone; dictating into Name inserts the words
      and does not submit; the Delete confirmation's typed-name field has no microphone;
      no overflow at 360 dp and 200 percent text.

#### Redesign the project home count cards

- [x] No card repeats its name; each shows, for example, "Review" and "0".
- [x] Phone portrait shows two rows of two cards, and tablet and desktop show one row of four.
- [x] No text wraps inside a card at 360 dp, and nothing clips at 200 percent text or in
      landscape.
- [x] A screen reader hears "0 to review" and similar for each card.
- [x] Tests: each card shows its name once and its number; semantics read the pending
      sentence; 393 dp is 2×2 and 800 / 1200 dp are one row; landscape and 200 percent text
      show no overflow; navigation still reaches each list with its filter.

#### Add project pinning

- [x] A version-13 database with projects upgrades to 14 with every row intact and `pinnedAt` null,
      on the native file database and on an in-memory database.
- [x] `setPinned` pins and unpins; the value survives a close and reopen.
- [x] `watchList` and `watchAll` emit pinned first, then newest, with a stable tie; unpinning
      restores the plain order; a pinned archived row stays behind `includeArchived`.
- [x] The ordering is served by `projects_by_status_pin`.
- [x] `migrateToV14` is not in `kDestructiveSteps`; a second run is a no-op.
- [x] Tests: migration 13→14, repository pin/order, query-plan uses the index.

#### Add project list actions and numbering

- [x] At 1200 dp the pane header offers create and the more menu above search.
- [x] At 400 and 800 dp the same actions are reachable from the list screen title bar.
- [x] Show archived appears only in that menu, reflects its state, and still filters the list.
- [x] Rows are numbered from 1 in display order and renumber when search, filter or pin changes.
- [x] Each row menu is borderless and offers Rename, Pin or Unpin, Archive or Unarchive, and Delete.
- [x] Rename saves without moving the folder and cancels cleanly.
- [x] Pin moves the row to the top.
- [x] New controls meet 48 dp, label, tooltip and contrast matchers.
- [x] Nothing clips at 200 percent text. In RTL the number leads and the menu sits at the end.
- [x] Long-press does not open the row menu.




## Follow-up absorbed from 314, 315, 320, 321, 323, 327, 329

### Add project management actions

From an open project's home, the operator can see all projects, start a new one, edit its details and settings,
archive it, delete it, or duplicate it. From the project list, a new project can always be created, whether or not
projects already exist. Tapping the current destination again returns that branch to its root.

Files:

- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/lib/features/projects/presentation/project_list_screen.dart`
- `frontend/lib/features/projects/presentation/project_duplicate_action.dart`
- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/features/projects/presentation/project_home_screen_test.dart`
- `frontend/test/features/projects/presentation/project_list_screen_test.dart`
- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/core/copy/copy_test.dart`

Constraints:

- The list's one primary action is Create; the home keeps Continue capturing as its only primary action (FE-SIMP-01).
- `AppOverflowMenu`, `AppPrimaryAction`, `AppListTile` and the existing confirmations only (FE-CONS-01, FE-CONS-05,
  FE-CONS-06).
- Reuse the icons already used for these actions (`edit_outlined`, `inventory_2_outlined`, `delete_outline`)
  (FE-CONS-08).
- Feature files cannot import `router.dart`, so keep local path constants (FE-STR-04).
- Switching branches or size class keeps in-progress input (FE-RESP-03).
- `Copy` strings, 48 dp, and labels (FE-L10N-01, FE-A11Y-01, FE-A11Y-02).
- Do not change the create, edit, settings, archive or delete screens and their confirmations, `CurrentProject`
  persistence, the launch restore, or the four destinations.

### Hide the unbuilt project import button

The project list never offers a control that does nothing. The import button stays hidden until bundle import exists
(task 222), and its label and the empty-state copy say "Import a project" when it returns.

Files:

- `frontend/lib/features/projects/presentation/project_list_screen.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/features/projects/presentation/project_list_screen_test.dart`
- `frontend/test/core/copy/copy_test.dart`
- `dev-plan/20-data-import/222-import-entry.md`

Constraints:

- An empty state names the next action, and the one offered works (FE-SIMP-11).
- Code keeps the canonical word `bundle`. Only the button's wording changes (FE-CONS-07).
- Labels live in `Copy`; the key name stays, since it names meaning (FE-L10N-01, FE-L10N-02).
- Do not build import here (FE-FLOW-04).
- Do not change `DomainNames.bundle`, bundle code, or any other empty state.

### Use a checkbox for Show archived

The Projects list filter "Show archived" is a two-state checkbox with its label, not a switch. The
row is inset like other tiles, so the label is not flush with the screen edge.

Files:

- `frontend/lib/features/projects/presentation/project_list_screen.dart`
- `frontend/test/features/projects/presentation/project_list_screen_test.dart`
- `frontend/test/features/projects/presentation/project_archive_action_test.dart`

Constraints:

- Reuse `AppSwitchTile.checkbox`; build no new control (FE-CONS-01).
- A tap on the row or the box toggles it (FE-CONS-10).
- 48 dp, labelled, and the state is shown by the tick as well as colour (FE-A11Y-01, FE-A11Y-02,
  FE-A11Y-05).
- The control sits at the start in both text directions (FE-L10N-05).
- Do not change `projectListShowArchivedProvider`, the filter logic, the copy, or other switches
  in the app.

### Enable dictation on project fields

Every free-text field on New project and Project details offers the catalogue microphone.
Name, description and organisation accept speech to text. Fields that already opt out for a
stated reason stay as they are.

Files:

- `frontend/lib/features/projects/presentation/project_create_screen.dart`
- `frontend/lib/features/projects/presentation/project_edit_screen.dart`
- `frontend/test/features/projects/presentation/project_create_screen_test.dart`
- `frontend/test/features/projects/presentation/project_edit_screen_test.dart`
- `frontend/test/features/projects/presentation/project_delete_action_test.dart`

Constraints:

- Reuse catalogue dictation; add no screen-level speech code (FE-CONS-01).
- The speech language comes from the voice-language setting that `DictationScope` already
  reads (FE-L10N-08).
- Offline by choice keeps recognition on the device (FE-SEC-04).
- Dictated words land at the caret, and nothing is submitted (FE-SIMP-09).
- The microphone is 48 dp and labelled (FE-A11Y-01, FE-A11Y-02).
- Tests use `SttService` stand-ins, never the plugin (FE-TEST-03).
- Do not change `DictationScope`, `AppTextField`, the voice language setting, offline
  behaviour, or the recorded opt-outs (initials, email, phone, the typed-name delete
  confirmation, and the numeric confidence fields).

### Redesign the project home count cards

The project home's Review, Process, Export and Share cards each show their name once and their
count as a large number. They sit in a 2×2 grid on compact widths and in one row on medium and
expanded.

Files:

- `frontend/lib/features/projects/presentation/project_home_screen.dart`
- `frontend/test/features/projects/presentation/project_home_screen_test.dart`

Constraints:

- Keep `AppCard`, and add no new card widget (FE-CONS-01).
- Numbers are formatted for the active locale, the same way the catalogue fields do it
  (FE-CONS-09, FE-L10N-04).
- Choose the layout by size class, never by measuring width; test three widths and two
  orientations (FE-RESP-02, FE-RESP-10).
- Each card reads as one sentence, and nothing clips at 200 percent (FE-A11Y-02, FE-A11Y-03).
- No sentence is assembled from parts; the semantic label is the existing plural message
  (FE-L10N-03).
- Tokens only. Continue capturing stays the only primary action (FE-THEME-01, FE-SIMP-01).
- Do not change where each card navigates or its filter, the counts provider, the Continue
  capturing action, or the header.

### Add project pinning

A project can be pinned and unpinned. The pin is a shared `pinnedAt` column, survives a restart, and
does not bump `updatedAt` or the merge revision. Every project list orders pinned rows first, then
newest `updatedAt`, with a stable `id` tie. No control and no visible change — 006 adds the menu
item and the list marker.

Files:

- `frontend/lib/core/db/tables/projects.dart`
- `frontend/lib/core/db/migrations.dart`
- `frontend/lib/core/db/app_database.dart`
- `frontend/lib/features/projects/domain/project.dart`
- `frontend/lib/features/projects/domain/project_repository.dart`
- `frontend/lib/features/projects/data/project_mapper.dart`
- `frontend/lib/features/projects/data/project_repository_impl.dart`
- `frontend/test/support/factories.dart`
- `frontend/test/features/projects/fakes/fake_project_repository.dart`
- `frontend/test/core/db/migrations_test.dart`
- `frontend/test/core/db/tables/projects_test.dart`
- `frontend/test/features/projects/data/project_repository_impl_test.dart`
- `frontend/test/features/projects/data/project_mapper_test.dart`

Constraints:

- A migration adds; it never rewrites or destroys. Do not edit earlier upgrade steps (FE-STATE-07).
- Domain stays pure Dart; Drift stays in `data/` (FE-STR-05, FE-STR-04).
- Order in the query, never by sorting a materialised list in Dart (FE-PERF-03, FE-CONS-09).
- Pinning writes only `pinnedAt` and leaves `updatedAt`, `rev` and "Last worked" alone.
- Do not change any screen, menu, `ProjectStatus`, archive, delete, the folder tree, or merge
  columns. No UI, no golden regeneration.

### Add project list actions and numbering

The project list carries create and a more menu holding Show archived — in the expanded pane
header and in the compact/medium title bar, from one shared list — and each row is numbered in
display order and offers a borderless menu of Rename, Pin, Archive and Delete.

Files:

- `frontend/lib/features/projects/presentation/project_list_actions.dart`
- `frontend/lib/features/projects/presentation/project_rename_action.dart`
- `frontend/lib/features/projects/presentation/project_list_view.dart`
- `frontend/lib/features/projects/presentation/project_list_screen.dart`
- `frontend/lib/features/projects/projects.dart`
- `frontend/lib/app/nav_shell.dart`
- `frontend/lib/core/copy/copy.dart`
- `frontend/test/app/nav_shell_test.dart`
- `frontend/test/app/nav_pane_golden_test.dart`
- `frontend/test/features/projects/presentation/project_list_screen_test.dart`
- `frontend/test/features/projects/presentation/project_list_view_test.dart`
- `frontend/test/features/projects/presentation/project_rename_action_test.dart`
- `frontend/test/features/projects/presentation/project_list_golden_test.dart`
- `frontend/test/core/copy/copy_test.dart`

Constraints:

- One actions list feeds the pane and the title bar (FE-RESP-02). No `MediaQuery` width comparison.
- Show archived lives only in the more menu, with its on/off state visible, at every width.
- The filter control is omitted: Show archived is the only filter today.
- Row numbers are the position in the current filtered, sorted list (FE-L10N-04).
- The three-dot control is the only way into the row menu (FE-CONS-10). No "Open with".
- Rename uses the shared dialog API and does not move `folderName`. Pin reuses `setPinned`.
- Catalogue widgets only: `AppOverflowMenu`, `AppIconButton`, `AppButton`, `AppListTile`, `AppPage`.

## Out of scope

- Importing a bundle as a new project, which the data-import phase carries.
- The purge job and the recycle-bin screen; this phase only writes into the recycle area.
