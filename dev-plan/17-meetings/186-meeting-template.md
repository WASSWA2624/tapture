# 186 — Meeting template, model and creation

**Phase** 17 · Meetings  |  **Depends on** [044](../03-design-system/044-app-form-scaffold.md), [059](../04-data-layer/059-meetings-tables.md), [090](../09-templates/090-shipped-templates-assets.md), [125](../12-capture/125-gallery-picker.md)  |  **Standard** [STANDARD.md](../STANDARD.md)

## Implement

The shipped meeting template, the `Meeting` domain model over the tables of 107, the screen that starts a meeting with
its header already filled, and the attachments list that hangs agendas, reports, handouts and whiteboard photos off
the record.

## Files

- `frontend/lib/features/meetings/domain/meeting.dart` (new)
- `frontend/lib/features/meetings/presentation/meeting_create_screen.dart` (new)
- `frontend/lib/features/meetings/presentation/meeting_attachments.dart` (new)

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

1. Carry every field of the specification's meeting template. Date and times come from the clock service and location
   from the context state, so neither is typed.
2. Ship the template as an asset beside the others of 155, versioned the same way.
3. The create screen prefills date, start time, location and secretary from context and profile, leaving a meeting one
   tap from started.
4. Attachments arrive through the document picker of 225, list their kind and size, and open from the meeting record;
   photographed handouts join the same list as picked files.

## Constraints

- `meeting.dart` stays pure Dart: no Flutter or Drift import under `domain/` (FE-STR-05).
- Template field labels are user data and are not translated as interface strings (FE-L10N-07).

## Definition of done

- [ ] A meeting can be started in one tap, with a correct header and no typing.
- [ ] Attachments of every supported kind appear in one list on the meeting and open from it.
- [ ] Tests: round-trip mapper test of `meeting.dart` covering every attribute; widget tests of
      `meeting_create_screen.dart` and `meeting_attachments.dart` including their empty and failure states.
