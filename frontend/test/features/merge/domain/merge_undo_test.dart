import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/merge_undo.dart';

void main() {
  test('undo restores the snapshot and stops once it is purged', () {
    const MergeUndo undo = MergeUndo();
    const Map<String, String> before = <String, String>{
      'file': 'old',
      'row': 'kept',
    };
    expect(undo.isAvailable('m1', purged: false), isTrue);
    expect(undo.undo(snapshot: before, purged: false), before);
    expect(undo.isAvailable('m1', purged: true), isFalse);
    expect(() => undo.undo(snapshot: before, purged: true), throwsStateError);
  });
}
