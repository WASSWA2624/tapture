import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/export/value_formatter.dart';

void main() {
  const ExportValueFormatter formatter = ExportValueFormatter(<String>{
    'text',
    'barcode',
    'number',
    'boolean',
    'date',
    'choice',
  });

  test('every format renders a value the same way', () {
    const String asset = '00734';
    for (final ExportFormat format in ExportFormat.values) {
      expect(formatter.format(asset, 'barcode', format), '00734');
      expect(formatter.format(null, 'text', format), '');
      expect(formatter.format(true, 'boolean', format), 'Yes');
      expect(formatter.format(<Object?>['a', 'b'], 'text', format), 'a; b');
      expect(
        formatter.format(DateTime.utc(2026, 9, 28), 'date', format),
        '2026-09-28',
      );
    }
    expect(formatter.typed(asset, 'barcode'), '00734');
    expect(formatter.typed(12, 'number'), 12);
  });
}
