import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/conflict_choice.dart';

void main() {
  test('a choice is stored by name as the conflict resolution', () {
    expect(ConflictChoice.values.map((ConflictChoice c) => c.name), <String>[
      'mine',
      'theirs',
    ]);
  });
}
