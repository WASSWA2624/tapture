# 112 — Meetings: minutes, attendance and actions

**Phase** 17 · Meetings  |  **Depends on** [035](../03-design-system/035-app-text-field.md), [038](../03-design-system/038-app-card.md), [044](../03-design-system/044-app-form-scaffold.md), [059](../04-data-layer/059-meetings-tables.md), [090](../09-templates/090-shipped-templates-assets.md), [105](../10-reference-data/105-reference-data.md), [107](../12-capture/107-capture.md), [108](../13-processing/108-processing.md), [111](../16-review/111-review.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The whole meeting record type: the shipped meeting template and the `Meeting` domain model over the meeting, attendee
and action tables of 059; the create screen that starts a meeting with its header already filled and the attachments
list that hangs agendas, reports, handouts and whiteboard photos off the record; the agenda and attendee editors, with
apologies kept distinct from attendance; attendance-sheet capture that photographs the signed sheet as ATTENDANCE
evidence, reads it into editable attendee rows and offers — never imposes — a link from each name to the Staff
reference dataset; a long-form recording attached to the record with a verbatim, versioned transcript that can be
re-run against a better service later; minutes refinement that turns the raw notes and the transcript into a summary
per agenda item, a list of decisions and actions with owners and dates, shown beside the raw material with both sides
editable; the decisions and actions registers, each item editable whether it arrived from refinement or was typed; and
the review screen that approves a meeting down the same path as any other record, with the meeting-specific
completeness checks standing in front of export.

## Files

Domain:

- `frontend/lib/features/meetings/domain/meeting.dart` (new)
- `frontend/lib/features/meetings/domain/attendance_ocr.dart` (new)
- `frontend/lib/features/meetings/domain/attendee_matching.dart` (new)
- `frontend/lib/features/meetings/domain/meeting_transcription.dart` (new)
- `frontend/lib/features/meetings/domain/minutes_refinement.dart` (new)

Presentation:

- `frontend/lib/features/meetings/presentation/meeting_create_screen.dart` (new)
- `frontend/lib/features/meetings/presentation/meeting_attachments.dart` (new)
- `frontend/lib/features/meetings/presentation/agenda_editor.dart` (new)
- `frontend/lib/features/meetings/presentation/attendee_editor.dart` (new)
- `frontend/lib/features/meetings/presentation/attendance_capture.dart` (new)
- `frontend/lib/features/meetings/presentation/meeting_audio_section.dart` (new)
- `frontend/lib/features/meetings/presentation/decisions_editor.dart` (new)
- `frontend/lib/features/meetings/presentation/actions_editor.dart` (new)
- `frontend/lib/features/meetings/presentation/meeting_review_screen.dart` (new)

## Contract

```dart
class Meeting {
  const Meeting({
    required this.id,
    required this.projectId,
    required this.title,
    required this.startedAt,
    this.endedAt,
    this.location,
    this.secretary,
    this.agenda = const [],
    this.attendees = const [],
    this.decisions = const [],
    this.actions = const [],
    this.attachmentIds = const [],
  });
  final String id, projectId, title;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? location, secretary;
  final List<AgendaItem> agenda;
  final List<Attendee> attendees;
  final List<Decision> decisions;
  final List<ActionItem> actions;
  final List<String> attachmentIds;
}
```

## Steps

1. Build the model, the shipped template and the way a meeting starts. `meeting.dart` carries every field of the
   specification's meeting template over the tables of 059; date and times come from the clock service and the
   location from the context state, so neither is typed. The meeting template ships as an asset beside the other
   shipped templates of 090 and is versioned the same way — a shipped asset, not a file this task invents a home for.
   The create screen prefills date, start time, location and secretary from context and profile, leaving a meeting one
   tap from started. Attachments arrive through the document picker of 107, list their kind and size, and open from
   the meeting record; photographed handouts join the same list as picked files.
2. Build the two list editors a meeting starts with. Agenda items add, reorder by drag and remove, and each item
   becomes a discussion section that keeps its order through to export. Attendees entered by hand carry name, title,
   organisation and contact, plus a status distinguishing present from apologies.
3. Build attendance-sheet capture, reading and matching. Photograph the signed sheet through the shutter of 107, typed
   ATTENDANCE by the photo type sheet of the same phase; the sheet remains evidence whatever the reading later
   produces. `attendance_ocr.dart` detects the name, title, organisation and signature-present columns and emits one
   row per line with a confidence per cell, taken from the OCR service of 108. `attendee_matching.dart` scores each
   name against the Staff dataset with the fuzzy matcher of 105 and attaches the score; below the threshold no
   suggestion is offered and nothing is linked.
4. Attach a long-form recording and produce its transcript. The audio section shows elapsed time and remaining storage
   while recording, and keeps the partial file when the app is interrupted or killed. Transcription chunks long audio,
   reports progress per chunk, and survives one chunk failing without losing the chunks already done. Each
   transcription run is stored as its own version against the recording; a re-run adds a version and replaces none.
5. Refine the minutes on request. Produce a discussion summary per agenda item, plus decisions and actions carrying
   the owner and due date the material states, and reject any attendee, decision or action with no support in the raw
   notes or the transcript, naming the offending item. Show raw notes and refined minutes side by side, both editable;
   refining again adds a version rather than overwriting one.
6. Build the two registers a meeting produces. Decisions add, edit and remove; a refined decision shows where it came
   from and stays editable. An action's owner is picked from the attendee list or the Staff dataset, its due date
   through the shared date field of 035, and its status from the shared set. Editing or removing a refined item never
   alters the transcript or the notes behind it.
7. Review and approve a meeting down the record path. Approval runs through the approve action of 111; this screen
   adds the meeting summary above it — attendance count, decisions and actions — rather than a second approval path.
   Where the template requires it, block approval while an action has no owner or no due date, naming the action.

## Constraints

- Everything under `frontend/lib/features/meetings/domain/` stays pure Dart: no Flutter and no Drift import there
  (FE-STR-05).
- Template field labels, agenda text, decisions and attendee details are meeting content stored as user data, not
  localisation keys, and are never translated as interface strings (FE-L10N-07).
- Both list editors build on the shared card of 038 and the shared confirm of 041 for removal; neither invents its own
  row (FE-CONS-06).

## Definition of done

- [ ] A meeting can be started in one tap, with a correct header and no typing.
- [ ] Attachments of every supported kind appear in one list on the meeting and open from it.
- [ ] Each agenda item becomes a discussion section, in the order the user set.
- [ ] An apology is recorded as an apology and never counted as attendance, in the record and on export.
- [ ] Every extracted attendance row is editable before it joins the attendee list, and none is added silently.
- [ ] No attendee is linked to a staff row without a person accepting the suggestion.
- [ ] A sheet that reads badly still leaves its photo attached and the attendee list editable by hand.
- [ ] An interrupted recording is still attached to the meeting and playable.
- [ ] The raw transcript is never replaced, neither by refining the minutes nor by a later transcription run.
- [ ] A fabricated attendee, decision or action is rejected by the guard, and the rejection names the item.
- [ ] Raw notes and refined minutes are shown side by side and both are editable.
- [ ] Actions are exportable as their own register, with owner, due date and status.
- [ ] A refined decision or action can be edited or deleted without altering the raw material it came from.
- [ ] A meeting cannot be exported while its actions have no owners, when the template requires them.
- [ ] Approving a meeting writes the same lifecycle and audit trail as any other record.
- [ ] Tests: round-trip mapper test of `meeting.dart` covering every attribute.
- [ ] Tests: widget test of `meeting_create_screen.dart` including its empty and failure states.
- [ ] Tests: widget test of `meeting_attachments.dart` including its empty and failure states.
- [ ] Tests: widget test of `agenda_editor.dart` covering add, reorder and remove, plus its empty and failure states.
- [ ] Tests: widget test of `attendee_editor.dart` covering a present attendee and an apology, plus its empty and
      failure states.
- [ ] Tests: widget test of `attendance_capture.dart` including its empty and failure states.
- [ ] Tests: test of `attendance_ocr.dart` against a fixture attendance sheet asserting the columns and the per-row
      confidence.
- [ ] Tests: unit tests of `attendee_matching.dart` over above- and below-threshold scores, with no Flutter binding.
- [ ] Tests: widget test of `meeting_audio_section.dart` covering recording, interruption, and its empty and failure
      states.
- [ ] Tests: unit tests of `meeting_transcription.dart` over chunking, a failed chunk and a repeat run, with no Flutter
      binding.
- [ ] Tests: unit tests of `minutes_refinement.dart` asserting a fabricated action is rejected, a supported one
      survives, and the raw material is unchanged by refinement, with no Flutter binding.
- [ ] Tests: widget test of `decisions_editor.dart` covering add, edit and remove, plus its empty and failure states.
- [ ] Tests: widget test of `actions_editor.dart` covering add, edit, remove, an owner taken from each source, and its
      empty and failure states.
- [ ] Tests: widget test of `meeting_review_screen.dart` covering a complete meeting, an ownerless action blocking
      approval, and its empty and failure states.

## Out of scope

- The formatted minutes PDF — attendance list, agenda items with their decisions and actions, and the photo appendix.
  The registers are exportable here; producing the document belongs to 113 · Export.
- The end-to-end meeting journey as an integration run, which belongs to 120 · Testing and release.
