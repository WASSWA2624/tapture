import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';

void main() {
  test('an edit-shaped copy keeps the previous value in audit', () {
    const FieldValue original = FieldValue(
      fieldKey: 'serial',
      value: 'ABB',
      source: ValueSource.ocr,
    );

    final FieldValue edited = FieldValue(
      fieldKey: original.fieldKey,
      value: 'ABB-1',
      source: ValueSource.manual,
      verified: true,
      audit: <FieldAudit>[(previousValue: original.value, newValue: 'ABB-1')],
    );

    expect(edited.source, ValueSource.manual);
    expect(edited.verified, isTrue);
    expect(edited.audit.single.previousValue, 'ABB');
    expect(edited.audit.single.newValue, 'ABB-1');
    expect(original.source, ValueSource.ocr);
    expect(original.verified, isFalse);
  });

  test('copyWith can clear the stored value', () {
    const FieldValue filled = FieldValue(fieldKey: 'when', value: '2026-09-17');
    expect(filled.copyWith(clearValue: true).value, isNull);
    expect(filled.copyWith(value: '2026-09-18').value, '2026-09-18');
  });
}
