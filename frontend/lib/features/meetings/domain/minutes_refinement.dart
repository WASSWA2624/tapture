import 'action_entry.dart';
import 'agenda_entry.dart';
import 'attendee.dart';
import 'decision.dart';

/// Turns raw notes and a transcript into minutes, and refuses anything the
/// material does not support.
///
/// Refining again is a new result. [notes] and [transcript] come back
/// unchanged.
final class MinutesRefinement {
  /// Summarises each agenda entry and keeps only supported people, decisions
  /// and actions. A rejection names the item.
  static MinutesRefinementResult refine({
    required String notes,
    required String transcript,
    required List<AgendaEntry> agenda,
    List<Attendee> attendees = const <Attendee>[],
    List<Decision> decisions = const <Decision>[],
    List<ActionEntry> actions = const <ActionEntry>[],
  }) {
    final String material = '$notes\n$transcript';
    final String folded = material.toLowerCase();
    final List<String> rejected = <String>[];
    final List<({String agendaId, String summary})> summaries =
        <({String agendaId, String summary})>[
          for (final AgendaEntry entry in agenda)
            (agendaId: entry.id, summary: _summary(entry, notes, transcript)),
        ];
    final List<Attendee> keptPeople = <Attendee>[
      for (final Attendee person in attendees)
        if (_supported(person.name, folded, rejected)) person,
    ];
    final List<Decision> keptDecisions = <Decision>[
      for (final Decision decision in decisions)
        if (_supported(decision.text, folded, rejected)) decision,
    ];
    final List<ActionEntry> keptActions = <ActionEntry>[
      for (final ActionEntry action in actions)
        if (_supported(action.text, folded, rejected)) action,
    ];
    return (
      summaries: summaries,
      decisions: keptDecisions,
      actions: keptActions,
      attendees: keptPeople,
      rejected: rejected,
      notes: notes,
      transcript: transcript,
    );
  }

  static String _summary(AgendaEntry entry, String notes, String transcript) {
    final String title = entry.title.trim().toLowerCase();
    if (title.isEmpty) {
      return '';
    }
    for (final String source in <String>[notes, transcript]) {
      for (final String line in source.split('\n')) {
        if (line.toLowerCase().contains(title)) {
          return line.trim();
        }
      }
    }
    return '';
  }

  static bool _supported(String text, String folded, List<String> rejected) {
    final String needle = text.trim().toLowerCase();
    if (needle.isEmpty || !folded.contains(needle)) {
      rejected.add(text.trim().isEmpty ? '(blank)' : text.trim());
      return false;
    }
    return true;
  }
}

/// What refinement kept, and the items it refused because the raw material
/// does not support them.
typedef MinutesRefinementResult = ({
  List<({String agendaId, String summary})> summaries,
  List<Decision> decisions,
  List<ActionEntry> actions,
  List<Attendee> attendees,
  List<String> rejected,
  String notes,
  String transcript,
});
