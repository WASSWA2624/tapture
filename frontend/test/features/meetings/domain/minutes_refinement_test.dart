import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/meetings/domain/action_entry.dart';
import 'package:tapture/features/meetings/domain/agenda_entry.dart';
import 'package:tapture/features/meetings/domain/minutes_refinement.dart';

void main() {
  const String notes = 'Welcome.\nSend the minutes by Friday.';
  const String transcript = 'The chair opened the meeting.';

  test('a fabricated action is rejected by name and a supported one stays', () {
    final MinutesRefinementResult result = MinutesRefinement.refine(
      notes: notes,
      transcript: transcript,
      agenda: const <AgendaEntry>[AgendaEntry(id: 'g1', title: 'Welcome')],
      actions: const <ActionEntry>[
        ActionEntry(id: 'c1', text: 'Send the minutes'),
        ActionEntry(id: 'c2', text: 'Buy a yacht'),
      ],
    );
    expect(result.actions.single.text, 'Send the minutes');
    expect(result.rejected, <String>['Buy a yacht']);
    expect(result.summaries.single.summary, 'Welcome.');
    expect(result.notes, notes);
    expect(result.transcript, transcript);
  });
}
