import 'action_entry.dart';
import 'agenda_entry.dart';
import 'attendee.dart';
import 'decision.dart';

/// A meeting filed on a record (task 017).
///
/// Agenda, attendees, decisions and actions are the rows of the meeting
/// tables. The shipped template is [templateKey] (`MTG-006`); this type does
/// not invent another template file.
final class Meeting {
  /// Creates a meeting. Lists default to empty.
  const Meeting({
    required this.id,
    required this.projectId,
    required this.title,
    required this.startedAt,
    this.endedAt,
    this.location,
    this.secretary,
    this.recordId,
    this.agenda = const <AgendaEntry>[],
    this.attendees = const <Attendee>[],
    this.decisions = const <Decision>[],
    this.actions = const <ActionEntry>[],
    this.attachmentIds = const <String>[],
  });

  /// Rebuilds a meeting written by [toJson].
  factory Meeting.fromJson(Map<String, Object?> json) {
    return Meeting(
      id: json['id'] as String? ?? '',
      projectId: json['projectId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      endedAt: DateTime.tryParse(json['endedAt'] as String? ?? ''),
      location: json['location'] as String?,
      secretary: json['secretary'] as String?,
      recordId: json['recordId'] as String?,
      agenda: _maps(
        json['agenda'],
      ).map(AgendaEntry.fromJson).toList(growable: false),
      attendees: _maps(
        json['attendees'],
      ).map(Attendee.fromJson).toList(growable: false),
      decisions: _maps(
        json['decisions'],
      ).map(Decision.fromJson).toList(growable: false),
      actions: _maps(
        json['actions'],
      ).map(ActionEntry.fromJson).toList(growable: false),
      attachmentIds: <String>[
        for (final Object? id in _list(json['attachmentIds']))
          if (id is String) id,
      ],
    );
  }

  /// Key of the shipped meeting-notes template (`MTG-006` in pack `MEET`).
  /// A meeting's record is filed under the project's installed copy of it,
  /// never under this key.
  static const String templateKey = 'mtg_meeting_notes_capture';

  /// The template field that, unless optional, makes every action need an
  /// owner and a due date before approval or export.
  static const String actionsFieldKey = 'action_items';

  /// Meeting row id.
  final String id;

  /// Project the meeting belongs to.
  final String projectId;

  /// Operator-facing title, stored as data.
  final String title;

  /// When the meeting started. Taken from the clock, not typed.
  final DateTime startedAt;

  /// When the meeting ended, if it has.
  final DateTime? endedAt;

  /// Location taken from context, not typed.
  final String? location;

  /// Secretary taken from the operator profile.
  final String? secretary;

  /// Record this meeting is filed on, when it has been saved.
  final String? recordId;

  /// Discussion sections, in order.
  final List<AgendaEntry> agenda;

  /// People present and apologies.
  final List<Attendee> attendees;

  /// Decisions, typed or refined.
  final List<Decision> decisions;

  /// Actions, typed or refined.
  final List<ActionEntry> actions;

  /// Attachment ids on this meeting.
  final List<String> attachmentIds;

  /// People present. Apologies are not included.
  int get attendanceCount =>
      attendees.where((Attendee person) => person.countsAsAttendance).length;

  /// Register rows for export: action, owner, due date and status.
  List<Map<String, Object?>> get actionRegister => <Map<String, Object?>>[
    for (final ActionEntry action in actions) action.registerRow(),
  ];

  /// Action texts that block export or approval when the template requires
  /// an owner and a due date. Empty when [requireOwner] is false.
  List<String> exportBlocks({required bool requireOwner}) {
    if (!requireOwner) {
      return const <String>[];
    }
    return <String>[
      for (final ActionEntry action in actions)
        if (!action.hasOwnerAndDue) action.text,
    ];
  }

  /// JSON covering every attribute.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'projectId': projectId,
      'title': title,
      'startedAt': startedAt.toUtc().toIso8601String(),
      'endedAt': endedAt?.toUtc().toIso8601String(),
      'location': location,
      'secretary': secretary,
      'recordId': recordId,
      'agenda': <Map<String, Object?>>[
        for (final AgendaEntry entry in agenda) entry.toJson(),
      ],
      'attendees': <Map<String, Object?>>[
        for (final Attendee person in attendees) person.toJson(),
      ],
      'decisions': <Map<String, Object?>>[
        for (final Decision decision in decisions) decision.toJson(),
      ],
      'actions': <Map<String, Object?>>[
        for (final ActionEntry action in actions) action.toJson(),
      ],
      'attachmentIds': attachmentIds,
    };
  }

  /// Returns a copy with the provided fields replaced.
  Meeting copyWith({
    String? id,
    String? title,
    DateTime? endedAt,
    String? location,
    String? secretary,
    String? recordId,
    List<AgendaEntry>? agenda,
    List<Attendee>? attendees,
    List<Decision>? decisions,
    List<ActionEntry>? actions,
    List<String>? attachmentIds,
    bool clearEndedAt = false,
  }) {
    return Meeting(
      id: id ?? this.id,
      projectId: projectId,
      title: title ?? this.title,
      startedAt: startedAt,
      endedAt: clearEndedAt ? null : (endedAt ?? this.endedAt),
      location: location ?? this.location,
      secretary: secretary ?? this.secretary,
      recordId: recordId ?? this.recordId,
      agenda: agenda ?? this.agenda,
      attendees: attendees ?? this.attendees,
      decisions: decisions ?? this.decisions,
      actions: actions ?? this.actions,
      attachmentIds: attachmentIds ?? this.attachmentIds,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Meeting &&
        other.id == id &&
        other.projectId == projectId &&
        other.title == title &&
        other.startedAt == startedAt &&
        other.endedAt == endedAt &&
        other.location == location &&
        other.secretary == secretary &&
        other.recordId == recordId &&
        _same(other.agenda, agenda) &&
        _same(other.attendees, attendees) &&
        _same(other.decisions, decisions) &&
        _same(other.actions, actions) &&
        _same(other.attachmentIds, attachmentIds);
  }

  @override
  int get hashCode => Object.hash(
    id,
    projectId,
    title,
    startedAt,
    endedAt,
    location,
    secretary,
    recordId,
    Object.hashAll(agenda),
    Object.hashAll(attendees),
    Object.hashAll(decisions),
    Object.hashAll(actions),
    Object.hashAll(attachmentIds),
  );
}

List<Map<String, Object?>> _maps(Object? raw) {
  return <Map<String, Object?>>[
    for (final Object? entry in _list(raw))
      if (entry is Map) Map<String, Object?>.from(entry),
  ];
}

List<Object?> _list(Object? raw) {
  return raw is List<Object?> ? raw : const <Object?>[];
}

bool _same<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) {
      return false;
    }
  }
  return true;
}
