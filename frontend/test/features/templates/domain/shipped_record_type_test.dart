import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/templates/domain/shipped_record_type.dart';

void main() {
  test('a record type keeps its pack, kind and guidance', () {
    const ShippedRecordType type = ShippedRecordType(
      code: 'INSPECT',
      title: 'Inspection / field form',
      kind: 'inspection',
      capture: 'Checklists; photos; measurements',
      aiAssistance: 'Summarize findings',
      outputs: 'Inspection report',
      review: 'Qualified inspector signs off',
    );

    expect(type.code, 'INSPECT');
    expect(type.title, 'Inspection / field form');
    expect(type.kind, 'inspection');
    expect(type.capture, 'Checklists; photos; measurements');
    expect(type.aiAssistance, 'Summarize findings');
    expect(type.outputs, 'Inspection report');
    expect(type.review, 'Qualified inspector signs off');
  });

  test('guidance the catalogue does not give is empty, not null', () {
    const ShippedRecordType type = ShippedRecordType(
      code: 'LOG',
      title: 'Activity / event log',
      kind: 'log',
    );

    expect(type.capture, isEmpty);
    expect(type.aiAssistance, isEmpty);
    expect(type.outputs, isEmpty);
    expect(type.review, isEmpty);
  });
}
