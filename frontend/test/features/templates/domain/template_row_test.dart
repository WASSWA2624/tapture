import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/templates/domain/template_row.dart';

void main() {
  test('copyWith replaces aliases and leaves the identifier put', () {
    const TemplateRow original = TemplateRow(
      identifier: 'm-1',
      label: 'Meter 1',
      outputRowNumber: 4,
      aliases: <String>['M1'],
    );
    final TemplateRow edited = original.copyWith(
      label: 'Blood Pressure Machine',
      aliases: const <String>['BP machine', 'M1'],
    );
    expect(edited.identifier, 'm-1');
    expect(edited.outputRowNumber, 4);
    expect(edited.label, 'Blood Pressure Machine');
    expect(edited.aliases, <String>['BP machine', 'M1']);
    expect(edited.foundStatus, 'missing');
  });

  test('two rows with the same attributes are equal', () {
    const TemplateRow row = TemplateRow(
      identifier: 'm-1',
      label: 'Meter 1',
      outputRowNumber: 4,
    );
    expect(
      row,
      const TemplateRow(
        identifier: 'm-1',
        label: 'Meter 1',
        outputRowNumber: 4,
      ),
    );
    expect(row, isNot(row.copyWith(label: 'Other')));
  });
}
