import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/merge/domain/merge_undo.dart';

import '../../../support/matchers.dart';

void main() {
  test('undo restores the snapshot and stops once it is purged', () {
    const MergeUndo undo = MergeUndo();
    const Map<String, String> before = <String, String>{
      'file': 'old',
      'row': 'kept',
    };
    expect(undo.isAvailable('m1', purged: false), isTrue);
    expect(valueOf(undo.undo(snapshot: before, purged: false)), before);
    expect(undo.isAvailable('m1', purged: true), isFalse);
    final Result<Map<String, String>> purged = undo.undo(
      snapshot: before,
      purged: true,
    );
    expect(purged, isFailure<Map<String, String>, StorageFailure>());
    expect(
      (purged as FailureResult<Map<String, String>>).failure.message,
      'The snapshot has been purged.',
    );
  });
}
