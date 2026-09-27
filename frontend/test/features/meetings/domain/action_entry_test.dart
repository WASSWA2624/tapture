import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/meetings/domain/action_entry.dart';

void main() {
  test('editing an action leaves its source', () {
    final ActionEntry action = ActionEntry(
      id: 'c1',
      text: 'Send the minutes',
      source: 'Send the minutes',
      due: DateTime.utc(2026, 10, 1),
      ownerName: 'Ada',
      ownerId: 'a1',
    );
    final ActionEntry edited = action.copyWith(text: 'Send them today');
    expect(edited.source, action.source);
    expect(edited.text, 'Send them today');
    expect(action.hasOwnerAndDue, isTrue);
    expect(
      const ActionEntry(id: 'c2', text: 'Book the room').hasOwnerAndDue,
      isFalse,
    );
  });
}
