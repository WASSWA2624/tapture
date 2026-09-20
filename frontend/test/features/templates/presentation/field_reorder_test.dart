import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/templates/domain/field_def.dart';
import 'package:tapture/features/templates/presentation/field_reorder.dart';

void main() {
  const FieldDef serial = FieldDef(
    fieldKey: 'serial',
    label: 'Serial',
    type: FieldType.text,
    outputColumn: 'B',
  );
  const FieldDef name = FieldDef(
    fieldKey: 'asset_name',
    label: 'Name',
    type: FieldType.text,
    outputColumn: 'C',
  );

  test('movedDown changes list order and leaves output columns', () {
    final List<FieldDef> next = FieldReorder.movedDown(<FieldDef>[
      serial,
      name,
    ], 0);
    expect(next.map((FieldDef field) => field.fieldKey), <String>[
      'asset_name',
      'serial',
    ]);
    expect(next.map((FieldDef field) => field.outputColumn), <String?>[
      'C',
      'B',
    ]);
    expect(next.map((FieldDef field) => field.sortOrder), <int>[0, 1]);
  });

  test('moved places the field at the already-adjusted index', () {
    final List<FieldDef> next = FieldReorder.moved(
      <FieldDef>[serial, name],
      0,
      1,
    );
    expect(next.map((FieldDef field) => field.fieldKey), <String>[
      'asset_name',
      'serial',
    ]);
  });
}
