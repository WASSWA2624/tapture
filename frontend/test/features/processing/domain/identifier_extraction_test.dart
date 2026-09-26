import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/identifier_extraction.dart';

void main() {
  const List<IdentityField> fields = <IdentityField>[
    (fieldKey: 'serial', pattern: r'SN\d{6}'),
    (fieldKey: 'asset_tag', pattern: r'AT-\d{4}'),
  ];

  test('one candidate on a realistic plate, with its block', () {
    const List<PlateBlock> blocks = <PlateBlock>[
      (text: 'GRUNDFOS PUMPS', top: 10, confidence: 0.95),
      (text: 'TYPE CR 3-8 SN458923', top: 40, confidence: 0.9),
      (text: '240V 50HZ 0.55KW', top: 70, confidence: 0.85),
    ];
    final List<IdentifierCandidate> found = IdentifierExtraction.extract(
      text: blocks.map((PlateBlock b) => b.text).join('\n'),
      blocks: blocks,
      fields: fields,
    );
    expect(found, hasLength(1));
    expect(found.single.fieldKey, 'serial');
    expect(found.single.value, 'SN458923');
    expect(found.single.blockIndex, 1);
    expect(found.single.blockText, 'TYPE CR 3-8 SN458923');
  });

  test('competing candidates come back best first', () {
    const List<PlateBlock> blocks = <PlateBlock>[
      (text: 'SN111111', top: 5, confidence: 0.95),
      (text: 'AT-0042', top: 30, confidence: 0.9),
      (text: 'SN222222', top: 90, confidence: 0.4),
    ];
    final List<IdentifierCandidate> found = IdentifierExtraction.extract(
      text: blocks.map((PlateBlock b) => b.text).join('\n'),
      blocks: blocks,
      fields: fields,
    );
    expect(found.map((IdentifierCandidate c) => c.value), <String>[
      'SN111111',
      'AT-0042',
      'SN222222',
    ]);
    for (var i = 1; i < found.length; i++) {
      expect(found[i - 1].score, greaterThanOrEqualTo(found[i].score));
    }
    expect(
      found
          .firstWhere((IdentifierCandidate c) => c.fieldKey == 'asset_tag')
          .value,
      'AT-0042',
      reason: 'leading zeros are kept',
    );
  });

  test('a value only in the joined text has no block and ranks lowest', () {
    const List<PlateBlock> blocks = <PlateBlock>[
      (text: 'SN4589', top: 10, confidence: 0.9),
      (text: '23', top: 20, confidence: 0.9),
    ];
    final List<IdentifierCandidate> found = IdentifierExtraction.extract(
      text: 'SN458923',
      blocks: blocks,
      fields: fields,
    );
    expect(found.single.value, 'SN458923');
    expect(found.single.blockIndex, isNull);
  });

  test('no candidate when nothing matches', () {
    expect(
      IdentifierExtraction.extract(
        text: 'NO SERIAL HERE',
        blocks: const <PlateBlock>[
          (text: 'NO SERIAL HERE', top: 0, confidence: 0.9),
        ],
        fields: fields,
      ),
      isEmpty,
    );
  });

  test('a pattern that cannot be read is passed over', () {
    expect(
      IdentifierExtraction.extract(
        text: 'SN458923',
        blocks: const <PlateBlock>[],
        fields: const <IdentityField>[(fieldKey: 'serial', pattern: '(')],
      ),
      isEmpty,
    );
  });
}
