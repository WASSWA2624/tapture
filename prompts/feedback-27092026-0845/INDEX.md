# Feedback prompts — TAPTURE-27092026-0843.xlsx and TAPTURE-27092026-0845.xlsx

13 entries and 3 chat requests → 1 prompt, 22 work items. Generated 27 September 2026. Repository commit: e4e1ded.

The two archives go into one prompt, as the operator asked, together with three requests the operator made in the
same instruction (R1 to R3 below). Screenshots are under `prompts/TAPTURE-27092026-0843/screenshots/` (FBK0000002
to FBK0000007) and `prompts/TAPTURE-27092026-0845/screenshots/` (FBK0000156 to FBK0000162). The copy of the 08:43
archive inside the 08:45 folder (`TAPTURE-27092026-0843.zip`) holds the same workbook and images.

## Run order

| Prompt | Item | Title | Feedback | Type | Priority | After |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 001 | W1 | Confirm a saved project and release the unsaved guard | FBK0000156 | Defect | P3 | — |
| 001 | W2 | Keep the pane border and mark the open project | FBK0000007 | Defect | P3 | — |
| 001 | W3 | Lay out the Project contexts page | FBK0000006 | Defect | P3 | — |
| 001 | W4 | Let a responsive pair share one row on compact | FBK0000158 | Improvement | P4 | — |
| 001 | W5 | Share search folding and word matching in core | FBK0000161, R3 | Improvement | P4 | — |
| 001 | W6 | Let a section header collapse its section | FBK0000161 | Improvement | P4 | — |
| 001 | W7 | Pick a document on every platform | R2 | Gap | P4 | — |
| 001 | W8 | Save and share a stored package without loading it whole | R1 | Gap | P4 | — |
| 001 | W9 | Write the project package | R1 | Gap | P4 | — |
| 001 | W10 | Read and verify a project package | R2 | Gap | P4 | W9 |
| 001 | W11 | Add a read-only project details page | FBK0000156 | Gap | P5 | W1 |
| 001 | W12 | Put Save raw and Save and process in one equal row | FBK0000158 | Improvement | P5 | W4 |
| 001 | W13 | Fill a record's fields by hand from the record page | FBK0000162 | Improvement | P5 | — |
| 001 | W14 | See and change context from Capture | FBK0000160 | Gap | P5 | — |
| 001 | W15 | Group the template library into collapsible categories | FBK0000161 | Improvement | P5 | W6 |
| 001 | W16 | Rank library search and accept a description | FBK0000161 | Improvement | P5 | W5, W15 |
| 001 | W17 | Export the whole project as one package | R1 | Gap | P5 | W8, W9 |
| 001 | W18 | Show a capture guide built from the template | FBK0000157, FBK0000159 | Suggestion | P6 | W12 |
| 001 | W19 | Import a package as a new project | R2 | Suggestion | P6 | W7, W10 |
| 001 | W20 | Check template compatibility before a merge | R2 | Suggestion | P6 | W19 |
| 001 | W21 | Merge a package into a project | R2 | Suggestion | P6 | W20 |
| 001 | W22 | Check incoming records for possible duplicates | R3 | Suggestion | P6 | W5, W21 |

## Coverage

| Feedback ID | Category | Screen | Outcome |
| :--- | :--- | :--- | :--- |
| FBK0000002 | General feedback | Projects › Testing › Templates | Already resolved (`frontend/lib/features/templates/presentation/field_advanced_section.dart:129` sets a default; `frontend/lib/features/processing/data/validate_stage.dart:78-82` applies it; `Copy.fieldRowDefault`, `frontend/lib/core/copy/copy.dart:1499`, shows it on the row; 5dcab69, task 070 W11) |
| FBK0000003 | General feedback | Projects › Testing › Templates | Already resolved (`frontend/lib/features/templates/presentation/field_list_screen.dart:196` Required, Recommended and Optional sections, `:127` filter button; `template_list_screen.dart:100` and `project_home_screen.dart:170` filters; `frontend/lib/core/widgets/app_search_field.dart:61-67` shared button; 5dcab69, task 070 W6, W7, W10) |
| FBK0000004 | General feedback | Projects › Testing › Capture | Already resolved (`frontend/lib/core/widgets/fields/app_choice_field.dart:246-247` one field tall; `capture_target_fields.dart:126` selects side by side; `capture_screen.dart:315` saves side by side; `photo_tray.dart:72-73` the icon is the add action and Add photo is gone, as `screenshots/FBK0000159.png` shows; 5dcab69, task 070 W3, W4, W5, W8) |
| FBK0000005 | General feedback | Projects › Testing › Capture | Already resolved (`frontend/lib/core/files/file_writer_web.dart:30` writes through `BlobFileWriter` into IndexedDB; `frontend/lib/features/capture/data/drift_photo_repository.dart:190` reads back through `FileReader`; `frontend/lib/core/widgets/app_photo_thumb.dart:72`, `:251-255` draw bytes on web; 5dcab69, task 070 W1, W2) |
| FBK0000006 | General feedback | Projects › Error › Project contexts | 001 W3 |
| FBK0000007 | General feedback | Projects › Error | 001 W2 |
| FBK0000156 | General feedback | Projects › UgIFT Asset Verification › Project details | 001 W1, 001 W11 |
| FBK0000157 | General feedback | Projects › UgIFT Asset Verification › Capture | 001 W18 |
| FBK0000158 | General feedback | Projects › UgIFT Asset Verification › Capture | 001 W4, 001 W12 |
| FBK0000159 | General feedback | Projects › UgIFT Asset Verification › Capture | 001 W18 |
| FBK0000160 | General feedback | Projects › UgIFT Asset Verification › Capture | 001 W14 |
| FBK0000161 | General feedback | Projects › UgIFT Asset Verification › Templates | 001 W6, 001 W15, 001 W16; the AI-ranked part goes to the plan task "Suggest shipped templates with AI", per D12(a) |
| FBK0000162 | General feedback | Projects › UgIFT Asset Verification › Records | 001 W13 |

| Chat request | Asked | Outcome |
| :--- | :--- | :--- |
| R1 | The project export produces one ZIP with every file, setting and table another Tapture app needs | 001 W8, W9, W17 |
| R2 | Import that ZIP elsewhere, and merge it into a project built from the same templates, after a compatibility check | 001 W7, W10, W19, W20, W21 |
| R3 | An optional duplicate check, where a person decides each pair | 001 W5, W22 |

FBK0000002 to FBK0000005 were submitted on 26 September between 09:27 and 09:43 EAT, before task 070 landed at
17:26 EAT. They are the same entries as the 26 September 15:49 archive that task 070 closed. The Android
screenshots in the 08:45 archive, taken on a later build, already show task 070's layout.

## Open questions

- 001 D1, default (a): `AppForm.onSubmit` returns `Future<bool>`, and `true` clears the unsaved mark. All nine
  callers change.
- 001 D2, default (a): the open project's row gets the `surfaceVariant` fill, a 4dp `primary` start bar, a
  `primary` title and the selected announcement.
- 001 D3, default (a): the level-name diagram goes, and each level row gets one overflow menu with Edit and Remove.
- 001 D4, default (a): the two capture saves are equal width in one row at every width. FE-SIMP-01 becomes "No
  other control is larger".
- 001 D5, default (a): an in-house document picker that mirrors `FolderPicker`, with no new dependency.
- 001 D6, default (a): native packages stream to disk with a 4,000,000,000-byte ceiling for export and import,
  and are delivered by streamed copy. Web builds in memory under 200 MiB.
- 001 D7, default (a): the package carries every project-owned table and file. It leaves out capture drafts, the
  processing queue, caches, export history, device settings, the operator profile and secure storage.
- 001 D8, default (a): a read-only page at `/projects/<id>/details`. The edit form is retitled "Edit project" and
  returns to details after a save.
- 001 D9, default (a): "Edit fields" moves from the record page's overflow menu to the Fields heading.
- 001 D10, default (a): on the Capture tab, the shell's context bar shows every level, set or not, plus Manage.
- 001 D11, default (a): the library's categories collapse, with counts, and start collapsed.
- 001 D12, default (a): ranked on-device description search now; AI suggestions become a plan task.
- 001 D13, default (a): one export, the ZIP package, with the workbook inside as `records.xlsx`.
- 001 D14, default (a): a collapsed "What to capture" row, plus a caption panel shown while typing, dictating or
  recording.
- 001 D15, default (a): a merge is blocked when a used template has no match, or when a field that holds values is
  missing locally or cannot hold them. Other differences only warn.
- 001 D16, default (a): the merge works by content, with §47's three rules and a person deciding the rest. It keeps
  no version vectors and has no undo; task 019 keeps both.
- 001 D17, default (a): the duplicate check is on by default and runs before the write. Each pair offers Keep both
  or Don't import this record.
- FBK0000158 reverses task 070's choice (from FBK0000004) that Save and process is twice as wide. It is the later
  request, made after using that layout, so it wins.
- FBK0000157 mentions accessories, which no shipped asset template has as a field. The guide lists only fields the
  template holds, so the reporter should say whether an accessories field belongs in the asset templates. That
  would be a catalogue change.
- FBK0000161 asks for AI search. On-device ranking closes the discoverability part. AI ranking needs a provider
  behind the backend proxy (task 024), and an endpoint the specification does not list yet (§74.2).
- FBK0000005 is closed on the evidence that both error screenshots show the photo reaching the file writer. If the
  webcam preview itself fails to open, the reporter needs to say which browser.
- Noticed, not reported:
  - The device id is kept in the OS temp folder on native (`frontend/lib/core/device/device_io.dart:4-6`) and only
    in memory on web. The prompt adds a plan task.
  - `records.identityHash` hashes the capture session, not the identity fields
    (`frontend/lib/features/capture/data/capture_record_writer.dart:78-80`).
  - Capture's inline field section never renders, because no route passes it fields
    (`frontend/lib/features/capture/presentation/capture_screen.dart:121`).
  - Removing a context level has no confirmation or undo
    (`frontend/lib/features/context/presentation/context_hierarchy_screen.dart:375-383`).
  - The contexts page's proposals state puts a second primary action inside its list (`:237-253`).
  - Version vectors are never written on ordinary edits (task 019).
