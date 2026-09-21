# 107 — Capture: evidence in, saved before anything else

**Phase** 12 · Capture  |  **Depends on** [024](../02-foundation/024-hashing-service.md), [026](../02-foundation/026-permissions-service.md), [054](../04-data-layer/054-records-table.md), [055](../04-data-layer/055-photos-table.md), [057](../04-data-layer/057-jobs-table.md), [066](../05-file-storage/066-project-folder-service.md), [067](../05-file-storage/067-file-writer.md), [089](../09-templates/089-field-type-registry.md), [105](../10-reference-data/105-reference-data.md), [106](../11-context/106-context.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The whole capture surface, and the rule underneath it that evidence is durable before the interface confirms anything:
the session model and the controller that write every photo, caption and typed value through to disk and the database
as it is added; the capture screen with its context bar, photo tray, caption, identifier, inline template fields and
two save actions; the camera permission gate, the preview, the shutter with its quality scoring, the four controls and
document mode; import of images, of documents and of lazily rendered PDF pages; the tray with ordering, photo types
and multi-select; the full-screen viewer with rotation and cropping; delete, retake and move; the record caption and
per-photo captions with an explicit scope selector; voice input from microphone permission through on-device dictation
to a verbatim transcript, with long-form audio recording beside it; the barcode scanner with its continuous mode and
the identifier-first lookup it feeds; automatic date, time, operator, device, record number and optional coordinates;
both save paths; the reset that readies the next item; crash recovery for an interrupted session; rapid mode; the
storage guard inside capture; and the template picker with session and context-level pinning.

## Files

### Session and screen

- `frontend/lib/features/capture/domain/capture_session.dart` (new)
- `frontend/lib/features/capture/presentation/capture_controller.dart` (new)
- `frontend/lib/features/capture/presentation/capture_screen.dart` (new)
- `frontend/lib/features/capture/presentation/inline_fields_section.dart` (new)

### Camera

- `frontend/lib/features/capture/presentation/camera_permission_gate.dart` (new)
- `frontend/lib/features/capture/presentation/camera_view.dart` (new)
- `frontend/lib/features/capture/domain/take_photo.dart` (new)
- `frontend/lib/features/capture/domain/image_quality.dart` (new)
- `frontend/lib/features/capture/presentation/camera_controls.dart` (new)
- `frontend/lib/features/capture/presentation/document_mode.dart` (new)

### Import

- `frontend/lib/features/capture/presentation/gallery_picker.dart` (new)
- `frontend/lib/features/capture/presentation/document_picker.dart` (new)
- `frontend/lib/core/import/pdf_pages.dart` (new)

### Tray and viewer

- `frontend/lib/features/capture/presentation/photo_tray.dart` (new)
- `frontend/lib/features/capture/presentation/photo_reorder.dart` (new)
- `frontend/lib/features/capture/presentation/photo_type_sheet.dart` (new)
- `frontend/lib/features/capture/presentation/photo_multi_select.dart` (new)
- `frontend/lib/features/capture/presentation/photo_viewer_screen.dart` (new)
- `frontend/lib/features/capture/domain/photo_rotate.dart` (new)
- `frontend/lib/features/capture/presentation/photo_crop_screen.dart` (new)
- `frontend/lib/features/capture/presentation/photo_delete_action.dart` (new)
- `frontend/lib/features/capture/presentation/photo_retake_action.dart` (new)
- `frontend/lib/features/capture/presentation/photo_move_action.dart` (new)

### Captions

- `frontend/lib/features/capture/presentation/record_caption_field.dart` (new)
- `frontend/lib/features/capture/presentation/photo_caption_sheet.dart` (new)
- `frontend/lib/features/capture/presentation/caption_scope_selector.dart` (new)
- `frontend/lib/features/capture/domain/caption_apply.dart` (new)

### Voice and audio

- `frontend/lib/features/capture/presentation/mic_permission_gate.dart` (new)
- `frontend/lib/core/ai/stt_service.dart` (new)
- `frontend/lib/features/capture/presentation/voice_input_button.dart` (new)
- `frontend/lib/features/capture/domain/transcript_store.dart` (new)
- `frontend/lib/features/capture/presentation/audio_recorder.dart` (new)

### Identifiers

- `frontend/lib/features/capture/presentation/barcode_scanner_screen.dart` (new)
- `frontend/lib/features/capture/presentation/barcode_continuous_mode.dart` (new)
- `frontend/lib/features/capture/domain/identifier_lookup.dart` (new)

### Automatic values

- `frontend/lib/features/capture/domain/auto_fields.dart` (new)
- `frontend/lib/features/capture/domain/record_number.dart` (new)
- `frontend/lib/features/capture/domain/gps_capture.dart` (new)

### Saving and resilience

- `frontend/lib/features/capture/domain/save_and_analyse.dart` (new)
- `frontend/lib/features/capture/domain/save_raw.dart` (new)
- `frontend/lib/features/capture/domain/capture_reset.dart` (new)
- `frontend/lib/features/capture/presentation/capture_recovery_prompt.dart` (new)
- `frontend/lib/features/capture/presentation/rapid_mode_screen.dart` (new)
- `frontend/lib/features/capture/presentation/capture_storage_guard.dart` (new)
- `frontend/lib/features/capture/presentation/template_picker_sheet.dart` (new)

## Contract

```dart
class CaptureSession {
  const CaptureSession({
    required this.id,
    required this.templateId,
    required this.contextSnapshot,
    this.recordId,
    this.photos = const [],
    this.captions = const {},
    this.values = const {},
    this.isDirty = false,
  });
  final String id;
  Map<String, Object?> toJson();
  static CaptureSession fromJson(Map<String, Object?> json);
  CaptureSession copyWith({...});
}

// Intent methods, the only way the session changes.
abstract class CaptureController {
  Future<void> addPhoto(PhotoDraft photo);
  Future<void> removePhoto(String photoId);
  Future<void> reorderPhotos(List<String> orderedIds);
  Future<void> setCaption(String? photoId, String text);
  Future<void> setValue(String fieldKey, Object? value);
}

abstract interface class SttService {
  Stream<SttResult> listen({required String languageTag});
  Future<void> cancel();
}

class SttResult {
  const SttResult({required this.text, required this.isFinal, required this.languageTag, this.confidence});
  final String text;
  final bool isFinal;
  final String languageTag; // the language actually used, not the one requested
  final double? confidence;
}
```

## Steps

### Session and screen

1. Model the session: id, template, context snapshot, photo list, captions, field values, record id and dirty state,
   serialised so an interrupted run can be found and restored. Every mutation is a method on the controller; widgets
   never rebuild the model themselves. Persist each addition to disk and to the database before the notifier emits its
   next state, so the emitted state is always already durable.
2. Assemble the capture screen from the specification — context bar, photo tray, caption, identifier, the two save
   actions — compact first, with medium and expanded putting the tray and the form side by side, and both save actions
   within one-thumb reach on a large phone, the deferred save visually primary. Build the inline section from the field
   type registry, showing identity and required fields only with the rest behind a closed "More fields". Nothing on the
   screen is mandatory except one piece of evidence.

### Camera

3. Ask for the camera at the moment it is first needed, never at launch, with the reason visible before the system
   prompt. On refusal keep gallery import and typed capture reachable, and offer a route to system settings when the
   refusal is permanent. Size the preview from the controller's reported preview size, handle rotation in both
   orientations, and release the camera surface on pause and rebuild it on resume.
4. One shutter press builds the path through the project folder service (066), writes the file through the file writer
   (067), hashes it, inserts the row and adds it to the session — all in the isolate runner (024), with the preview
   still live — then confirms with haptics and a shutter flash, accepting the next shot before the previous one
   finishes scoring. Score the saved image for blur, darkness, overexposure and small text only after it is durably
   written, and surface any finding as an advisory hint offering retake or keep, with keep the default.
5. Give the four controls a field worker actually uses: flash cycling off, auto and on with the choice remembered for
   the next session; tap to focus with a visible indicator; pinch to zoom within the device's reported range; and a
   grid toggle that persists. Document mode detects the page boundary in the isolate runner (024) and offers a
   perspective-corrected higher-contrast copy as a derived file linked to the original; when no boundary is found it
   captures normally and says so rather than blocking the shutter.

### Import

6. Open three import paths into the session: multi-select of existing images, attachment of PDFs and other files as
   documents, and lazy rendering of each PDF page so review can treat pages like photos. Validate extension, magic
   bytes, size and structure through file validation (071) before reading anything; a rejected file names its reason.
   Copy rather than reference, keep the original filename in metadata, and write documents into `documents/` with their
   page count where the format reports one (055). Render pages into `.cache` at a readable resolution in the isolate
   runner (024); the source PDF is never modified.

### Tray and viewer

7. Show the horizontal thumbnail strip with a count, an add action reachable at any scroll position, and a type badge,
   caption indicator and processing state on each thumbnail. Drag to reorder and persist the new order immediately;
   export and reports read that same order. Offer the specification's photo types — front, serial, rating plate, damage
   and the rest — defaulting to the last used type for rapid tagging. Long-press enters multi-select with a live count,
   select-all and clear, and a selection that survives scrolling and rotation.
8. Inspect full screen with pinch and double-tap zoom, swiping between the record's photos, with caption, type and
   metadata on demand. Store rotation as metadata and apply it to derived copies only; the original file is never
   rewritten. Write the crop as a derived file linked to the original, computed in the isolate runner (024); reverting
   restores the full frame at its original orientation.
9. Deliver the three corrective actions. Delete confirms through `AppDialogService` naming the consequence, tombstones
   the row, removes it from the tray and offers undo through `AppSnackbar`; the file stays until the retention purge so
   undo always works. Retake keeps the old file as a superseded version and puts the new photo at the same position
   with the same type and caption. Move relocates files through the relocator (067) and rows in one transaction and
   flags affected field values as evidence changed.

### Captions

10. Persist the record's main description as the raw caption as it changes, so backgrounding needs no explicit save.
    Open the photo caption sheet from the thumbnail or the viewer with the existing caption loaded for editing, and
    write each photo caption as its own row keyed to that photo (055).
11. Offer the explicit target selector — this photo, selected photos, all photos — defaulting to this photo when opened
    from a single thumbnail and to selected when opened from multi-select, and labelling every option with its exact
    count, for example "Selected photos (3)" and "All photos (7)". Append adds the new text on a new line; replace
    keeps the previous text recoverable from history. Either way, one independent caption row is written per photo in
    scope.

### Voice and audio

12. Ask for the microphone at the first mic tap, never at launch; refusal leaves typing fully available and asks again
    only on a later explicit tap. Recognise on device in the configured language, falling back to the online recogniser
    only when configured and online, otherwise reporting unavailable rather than failing silently. Attach the mic
    affordance to any long-text field: show listening state and live partial text, stop on tap or silence, and land the
    final text in the field as editable text that is never auto-submitted. Store transcript, language and confidence
    alongside the caption row (055), where refinement can never overwrite them.
13. Record a walkthrough or a meeting to a file attached to the record as a document, showing elapsed duration and
    input level while recording, with pause and stop. Write incrementally through the file writer (067) so an app kill
    keeps everything recorded up to that moment, and register the finished file in the documents table with its
    duration (055).

### Identifiers

14. Scan one-handed: decode the symbologies listed in the specification from the camera stream inside a visible scan
    region, with a torch toggle and the decoded value shown with confirm and rescan. Continuous mode stays open between
    reads for stock counting, debounces the same code, shows a running count and allows undo of the last scan.
15. Resolve a scanned or typed identifier to one of the specification's three outcomes, each one tap from the result:
    search the project's records first, then the reference datasets (105), then offer a new record with the identifier
    already filled. Where the identifier matches more than one record, list the matches rather than guessing.

### Automatic values

16. Apply everything a record gets without being asked — date, time, captured-at, operator and device — on first save,
    marking every value with source `AUTO` and the auto affordance, honouring each template field's `autoFill` setting
    and the project's date format. Allocate the per-project record number inside the same transaction as the record
    insert (054), without gaps or collisions. Time-box the location fix, store the accuracy with it, and save without
    waiting when the fix is slow or absent — and only where the project enables GPS.

### Saving

17. Wire both primary actions. Each persists record, photos, captions and field values first and only then acts:
    capture and analyse enqueues a processing job (057); save raw sets status `CAPTURED` and runs nothing at all,
    making no network call and no AI call of any kind, whatever the settings say. A failed enqueue leaves a complete
    `CAPTURED` record and a retryable job — never a lost record and never a partial one.

### Resilience

18. After a save, clear session-scoped evidence, captions and typed values only, leaving the context snapshot, pinned
    template and last camera settings exactly as they were, and start the next session with a fresh id that shares no
    mutable state with the saved one.
19. Detect an unfinished session at launch, before the capture screen is reachable, and offer resume or discard with
    the photo count named on the prompt. Resume restores photos, captions and typed values; discard asks for
    confirmation and tombstones, so the evidence remains recoverable.
20. Run the high-speed loop: one tap saves the current item raw, resets and returns to a live preview, with a running
    item list showing photo counts and the last item reopenable for correction. Analyse nothing until the operator asks.
21. Read both thresholds from the storage guard (069); never hardcode a size here. Warn once per session, dismissibly,
    and keep capture fully working. At the stop threshold refuse new writes only — a write already in flight completes
    rather than truncating — with a message that names the free space left and offers export as the way out.
22. List the project's templates most recently used first, then by name, hiding the control entirely when the project
    has a single template. Offer pinning for the session or for the current context level, per the specification, and
    remember the pin.

## Constraints

### Evidence integrity

- Raw evidence is written once and corrections write beside it: rotation is metadata, crop, perspective correction and
  retake produce derived files, an edited caption writes a new raw value with an audit entry rather than overwriting,
  replace keeps the earlier caption readable in history, refinement writes a separate column, and the original bytes
  and hash stay immutable (FE-SEC-08).
- Deletion and discard are tombstones; files are removed only by the purge job after the retention window, so undo
  always works, and the reset never touches the saved record, its files or its rows (FE-SEC-08).
- Delete, retake and move each record who, when, from what and to what, as does an edited caption (FE-SEC-09).

### Isolation, networking and input

- Camera, permissions, speech, time, device identity, location and free space are reached only through their `core/`
  services, each with a fake, never a plugin call from a feature (FE-STR-11).
- Networking stays inside `core/ai/`, and the raw save path is provably silent (FE-SEC-03, FE-SEC-04).
- Audio recording works with the network off and is never transcribed here (FE-SEC-04).
- User text is data, never interpolated: imported filenames never reach a path or a command, caption text never reaches
  a provider instruction, a decoded barcode is quoted, and an identifier is bound as a query parameter (FE-SEC-05).
- Validation precedes every read, archives are never expanded here, and traversal is refused before a path is used
  (FE-SEC-06).
- GPS is off by default, and no location permission is requested while it is off (FE-SEC-07).
- The camera plugin and the scanner plugin are both on the dependency allowlist checked by task 005.

### Performance

- No file input or output, hashing, encoding, decode or crop runs on the UI thread; all of it goes through the isolate
  runner and the file writer (FE-PERF-02).
- Copying, hashing, rendering and audio encoding stream in chunks; nothing loads a whole file into memory (FE-PERF-07).
- The tray shows thumbnails only, cached by hash and size, with a cap on concurrent decodes; the full image is decoded
  only in the viewer (FE-PERF-04).
- The tray and the rapid-mode item list are virtualised and paged from `AppConstants`; a whole record's photos are
  never materialised and a long run does not grow the frame budget (FE-PERF-03).
- Shutter to ready is under 400ms on a mid-range device, item-to-item time in rapid mode is measured rather than
  assumed, and lookup over 10,000 records stays under 300ms against a realistically seeded database — each asserted by
  a measurement in the pull request (FE-PERF-01, FE-PERF-06, FE-TEST-09).

### State

- The session is the single source of truth for the photo list; no second provider mirrors it (FE-STATE-06).
- Neither save path may report success before the record and its evidence are durable (FE-STATE-07).
- Preview state models starting, running and failed and renders all three, and a missing or unreadable file renders the
  failure state rather than an empty box (FE-STATE-11).

### Interface

- The size class comes from `core/`; the screen never measures the viewport itself (FE-RESP-02).
- One primary action, largest and in the lower third (FE-SIMP-01); additional attributes stay collapsed (FE-SIMP-06).
- The inline section renders each field through the registry's widget; it never switches on field type itself
  (FE-CONS-01).
- The last used setting is the default — flash, grid, photo type and template alike; a question with one answer is not
  asked (FE-SIMP-05).
- Warnings never block: a quality finding always offers keep and never gates a save, and the storage warning is
  dismissible while only the stop threshold refuses a write (FE-SIMP-08).
- A failure on delete, retake, move, a caption write, a recording against a full disk or the recovery prompt leaves the
  photo, its file, its metadata and anything typed intact, and offers recovery (FE-SIMP-09).
- The stop message names the next action and offers it (FE-SIMP-11).
- Controls are 48dp or larger, glove-friendly, one-handed, carry semantic labels and stay legible in the outdoor theme
  (FE-A11Y-01, FE-A11Y-02, FE-THEME-03).
- Haptic confirmation on capture is required, not decorative (FE-A11Y-09).
- Badges, selection and scope counts carry an icon or text as well as colour; a count is rendered as text, never
  implied by a highlight alone (FE-A11Y-05).
- Saved, saving and failed are announced to screen readers as they happen (FE-A11Y-07).
- Dates and times are formatted through `intl` from the project setting, never assembled by hand (FE-L10N-04).
- The voice language comes from the setting, not the device locale (FE-L10N-08).

## Definition of done

### Session and screen

- [ ] Killing the app mid-session loses at most the last keystroke.
- [ ] A session serialises, restores and resumes with its photos, captions and values intact.
- [ ] Tests: unit tests of every mutation and of the JSON round trip; controller test asserting a photo added is on disk and in the database before the next frame, and that a failed write leaves the emitted state unchanged.
- [ ] Nothing on the capture screen is mandatory except one piece of evidence.
- [ ] A fully manual project can be captured entirely on the capture screen without opening review.
- [ ] Tests: widget test of `capture_screen.dart` at compact, medium and expanded widths at 200 percent text scale; widget test of `inline_fields_section.dart` covering no fields, required-only, "More fields" expanded, and a field whose value fails validation.

### Camera

- [ ] A user who denies the camera can still add evidence and save a record.
- [ ] Returning from background restores the preview without a black frame, in both orientations.
- [ ] Tests: widget test of `camera_permission_gate.dart` covering granted, denied and permanently denied; widget test of `camera_view.dart` covering starting, running, failed and a pause-resume cycle, against a fake camera service.
- [ ] Shutter to ready is under 400 milliseconds on a mid-range device.
- [ ] A quality warning never prevents saving and never discards the photo.
- [ ] Tests: integration test that ten rapid shots produce ten files and ten rows with distinct hashes and correct order; unit tests of `image_quality.dart` over dark, blurry, overexposed, small-text and clean fixtures; a measurement test for the shutter budget.
- [ ] Controls are usable with gloves and remain readable in the outdoor theme.
- [ ] The original photo is retained unchanged alongside the perspective-corrected copy.
- [ ] Flash, zoom and grid choices survive leaving and re-entering capture.
- [ ] Tests: widget test of `camera_controls.dart` asserting flash cycling, focus, zoom clamping, grid persistence and the accessibility matchers against a fake camera service; widget test of `document_mode.dart` covering boundary detected, not detected and correction failed.

### Import

- [ ] Deleting the photo from the device gallery afterwards does not affect the record.
- [ ] A rejected file names the reason and leaves the session unchanged.
- [ ] A twenty-page document does not stall the interface.
- [ ] Tests: widget tests of `gallery_picker.dart` and `document_picker.dart` covering multi-select, an oversized file, a wrong extension and a mismatched magic-byte file; unit test of `pdf_pages.dart` against a multi-page fixture asserting lazy rendering and an unmodified source.

### Tray and viewer

- [ ] Thirty photos scroll smoothly and the add button stays reachable throughout.
- [ ] The persisted order is the order export and reports use.
- [ ] A photo type feeds file naming and evidence tracking as soon as it is set.
- [ ] Tests: widget tests of `photo_tray.dart` (badges, ordering, empty state), `photo_reorder.dart` (order persisted across a rebuild), `photo_type_sheet.dart` (last-used default, every type reachable) and `photo_multi_select.dart` (count, select-all, clear, selection across scroll and rotation).
- [ ] The original file's hash is unchanged after rotating and cropping.
- [ ] Reverting always restores the full frame at its original orientation.
- [ ] Tests: widget tests of `photo_viewer_screen.dart` (single photo, swipe across several, missing file) and `photo_crop_screen.dart` (crop then revert); unit tests of `photo_rotate.dart` asserting metadata-only rotation with no Flutter binding.
- [ ] Undo restores a deleted photo at its original position with its caption and type.
- [ ] Retaking never changes a photo's position in the tray.
- [ ] Moving photos never leaves a dangling evidence link or an orphaned file.
- [ ] Tests: widget tests of delete-then-undo, retake preserving position and metadata, and a multi-select move across records; transaction test asserting a mid-move failure rolls back files and rows together.

### Captions

- [ ] Caption text survives backgrounding with no explicit save.
- [ ] A photo caption can be edited without touching the record caption or any other photo's caption.
- [ ] Tests: widget tests of `record_caption_field.dart` (typing, backgrounding, write failure) and `photo_caption_sheet.dart` (empty, existing caption, write failure).
- [ ] A caption can never be applied without the number of affected photos on screen.
- [ ] Applying to seven photos writes seven independent caption rows, each editable alone afterwards.
- [ ] Tests: widget test of the default scope in both entry paths and of the displayed counts; unit tests of `caption_apply.dart` asserting append, replace, the recoverable previous value, and independence of each written row.

### Voice and audio

- [ ] Dictation works with the network off wherever the platform supports the language.
- [ ] Refusing the microphone leaves typing fully available and blocks nothing else.
- [ ] Later refinement writes a separate column and leaves the raw transcript row unchanged.
- [ ] Tests: unit tests of `stt_service.dart` with a fake recogniser covering partial, final, cancel, unsupported language and offline-unavailable; widget tests of `mic_permission_gate.dart` and `voice_input_button.dart` including the denied and listening states; unit test that refining does not alter the raw transcript row.
- [ ] A thirty-minute recording survives an app kill, with everything captured up to the kill playable.
- [ ] Tests: widget test of `audio_recorder.dart` covering idle, recording, paused, permission denied and disk full; test asserting a killed recording leaves a playable file and a documents row.

### Identifiers

- [ ] A worn label still scans within a couple of seconds.
- [ ] Fifty items can be counted without leaving the screen, with the last scan undoable.
- [ ] Tests: widget tests of `barcode_scanner_screen.dart` (no code, decoded, unreadable code, camera failure) and `barcode_continuous_mode.dart` (debounce of a repeated code, running count, undo of the last scan) against a fake scanner.
- [ ] All three identifier outcomes are reachable in one tap each.
- [ ] Tests: unit tests for a record match, a reference-dataset match, no match, and a duplicate identifier present on two records; a measurement test for the 300ms lookup budget.

### Automatic values

- [ ] A record captured with no typing still carries a complete timestamp, operator and device.
- [ ] Twenty rapid captures produce twenty consecutive record numbers with no gap or duplicate.
- [ ] With GPS off, no location permission is requested anywhere and no location call is made.
- [ ] Tests: unit test with a frozen clock asserting every automatic value and every `autoFill` combination; concurrency test allocating numbers from parallel inserts; test that the disabled GPS path makes no location call and that a slow fix does not delay the save.

### Saving

- [ ] Losing connectivity between save and enqueue never loses the record.
- [ ] Forty records can be captured offline in sequence with no processing triggered.
- [ ] Tests: unit test that a failed enqueue leaves a complete `CAPTURED` record with a retryable job; integration test of the raw path asserting zero outbound calls across forty records.

### Resilience

- [ ] Capturing the next item requires re-selecting nothing.
- [ ] Tests: unit test that context, pinned template and camera settings survive a save and reset, that the new session shares no state with the old one, and that the saved record is untouched.
- [ ] A crash during capture never silently discards photos.
- [ ] Tests: widget test of an interrupted session asserting the photo count on the prompt, that resume restores photos, captions and values, and that discard leaves the files recoverable.
- [ ] Four items with photos can be captured in under a minute.
- [ ] Tests: integration test of a four-item run asserting four records, the correct photo count on each, zero processing jobs, and that reopening the last item edits that item only.
- [ ] A full device shows an actionable message with an export shortcut and loses no photo already taken.
- [ ] Tests: widget test of `capture_storage_guard.dart` at healthy, warning and full levels against a fake storage guard, asserting the warning is dismissible, capture continues after it, and the stop state offers export while completing an in-flight write.
- [ ] A single-template project never shows the template picker.
- [ ] A pinned template is still in force after a save and after a restart.
- [ ] Tests: widget test of `template_picker_sheet.dart` with one, several and no templates, asserting last-used ordering, that a session pin survives a reset, and that a context-level pin applies when that level is re-entered.

## Out of scope

- Reading anything out of an image or a rendered page. Quality scoring here is advisory and page images are only
  produced; OCR, extraction, refinement and summarising all belong to phase 13 · Processing.
- Running the processing job. Capture writes and enqueues; the worker, its retries and its progress belong to
  phase 13 · Processing.
- Annotation, redaction and face blurring, which belong to phase 22 · Privacy and security.
- Deleting a whole record, and the retention purge that finally removes files; both belong to phase 14 · Records.
- Spreadsheet and bundle import, which belong to phase 20 · Data import.
