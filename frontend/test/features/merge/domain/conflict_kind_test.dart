import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/merge/domain/conflict_kind.dart';

void main() {
  test('every kind is stored by a stable name and reads as words', () {
    expect(ConflictKind.values.map((ConflictKind k) => k.name), <String>[
      'value',
      'caption',
      'status',
      'deletedThere',
      'deletedHere',
    ]);
    final Set<String> read = <String>{
      for (final ConflictKind kind in ConflictKind.values)
        Copy.conflictKind(kind.name, 'Serial'),
    };
    expect(read, hasLength(ConflictKind.values.length));
  });
}
