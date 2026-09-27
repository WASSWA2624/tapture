import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/export/export_record.dart';

void main() {
  test('a record keeps its number as text', () {
    const ExportRecord record = ExportRecord(
      id: 'r1',
      number: '00734',
      templateId: 't1',
      templateName: 'Asset',
      status: 'approved',
    );
    expect(ExportRecord.fromJson(record.toJson()).number, '00734');
  });
}
