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

  group('movedWithin', () {
    const FieldDef note = FieldDef(
      fieldKey: 'note',
      label: 'Note',
      type: FieldType.text,
    );
    const FieldDef rating = FieldDef(
      fieldKey: 'rating',
      label: 'Rating',
      type: FieldType.number,
    );

    test('a one-place move swaps the two fields and nothing else', () {
      final List<FieldDef> next = FieldReorder.movedWithin(
        <FieldDef>[serial, note, name, rating],
        <int>[0, 2, 3],
        0,
        1,
      );
      expect(next.map((FieldDef field) => field.fieldKey), <String>[
        'asset_name',
        'note',
        'serial',
        'rating',
      ]);
      expect(next.map((FieldDef field) => field.outputColumn), <String?>[
        'C',
        null,
        'B',
        null,
      ]);
      expect(next.map((FieldDef field) => field.sortOrder), <int>[0, 1, 2, 3]);
    });

    test('a longer move lays the section back into its own slots', () {
      final List<FieldDef> next = FieldReorder.movedWithin(
        <FieldDef>[serial, note, name, rating],
        <int>[0, 2, 3],
        2,
        0,
      );
      expect(next.map((FieldDef field) => field.fieldKey), <String>[
        'rating',
        'note',
        'serial',
        'asset_name',
      ]);
    });

    test('an out-of-range move leaves the fields as they are', () {
      final List<FieldDef> fields = <FieldDef>[serial, note, name];
      expect(
        identical(FieldReorder.movedWithin(fields, <int>[0, 2], 1, 2), fields),
        isTrue,
      );
      expect(
        identical(FieldReorder.movedWithin(fields, <int>[0, 2], 1, 1), fields),
        isTrue,
      );
      expect(
        identical(FieldReorder.movedWithin(fields, <int>[0, 5], 0, 1), fields),
        isTrue,
      );
    });
  });
}
