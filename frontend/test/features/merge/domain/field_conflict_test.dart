import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/merge/domain/conflict_kind.dart';
import 'package:tapture/features/merge/domain/field_conflict.dart';

void main() {
  FieldConflict conflict(ConflictKind kind, {String theirs = 'B'}) {
    return FieldConflict(
      kind: kind,
      table: 'record_fields',
      rowId: 'v1',
      recordId: 'r1',
      fieldKey: 'serial',
      fieldLabel: 'Serial',
      recordLabel: 'Pump one',
      mine: 'A',
      theirs: theirs,
      mineDevice: 'here',
      theirsDevice: 'there',
      mineAt: 100,
      theirsAt: 200,
    );
  }

  test('the id names the kind, the table and the row, so a choice survives '
      're-planning', () {
    expect(conflict(ConflictKind.value).id, 'value:record_fields:v1');
    expect(
      conflict(ConflictKind.value).id,
      conflict(ConflictKind.value, theirs: 'C').id,
    );
    expect(
      conflict(ConflictKind.value).id,
      isNot(conflict(ConflictKind.deletedThere).id),
    );
  });
}
