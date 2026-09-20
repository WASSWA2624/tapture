import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/import/type_inference.dart';

void main() {
  test('mixed sample columns resolve to registry types as suggestions', () {
    final List<ColumnSuggestion> columns = TypeInference.suggest(
      headers: const <String>[
        'Count',
        'Mass (kg)',
        'Price',
        'Share',
        'Installed',
        'Checked at',
        'Open',
        'Colour',
        'Asset tag',
        'Notes',
      ],
      sampleRows: const <List<String>>[
        <String>[
          '1',
          '12 kg',
          r'$12.00',
          '50%',
          '2026-09-20',
          '2026-09-20 10:02:31',
          'yes',
          'Red',
          'EQ-001',
          'Short',
        ],
        <String>[
          '2',
          '15 kg',
          r'$8.50',
          '25%',
          '2026-09-21',
          '2026-09-21 08:00:00',
          'no',
          'Blue',
          'EQ-002',
          'Also short',
        ],
        <String>[
          '3',
          '18 kg',
          r'$3.25',
          '10%',
          '2026-09-22',
          '2026-09-22 14:15:00',
          'yes',
          'Red',
          'EQ-003',
          'Still short',
        ],
      ],
    );

    expect(columns.map((ColumnSuggestion c) => c.typeName).toList(), <String>[
      'number',
      'number',
      'currency',
      'percentage',
      'date',
      'date_time',
      'boolean',
      'choice',
      'barcode',
      'text',
    ]);
    expect(columns[1].unit, 'kg');
    expect(columns[7].options, <String>['Blue', 'Red']);
    expect(
      columns.every((ColumnSuggestion column) => column.isSuggestion),
      isTrue,
    );
  });
}
