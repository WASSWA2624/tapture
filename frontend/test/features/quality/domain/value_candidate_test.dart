import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/features/quality/quality.dart';

void main() {
  test('a higher confidence never settles a conflict on its own', () {
    const ValueCandidate sure = ValueCandidate(ValueSource.ocr, 'A-1', 0.99, 'p1');
    const ValueCandidate unsure = ValueCandidate(
      ValueSource.barcode,
      'A-2',
      0.01,
      'p2',
    );
    final List<FieldConflict> conflicts = ConflictDetection.find(
      <String, List<ValueCandidate>>{
        'serial': <ValueCandidate>[sure, unsure],
      },
    );
    expect(conflicts.single.candidates, <ValueCandidate>[sure, unsure]);
    expect(
      conflicts.single.candidates.map((ValueCandidate c) => c.confidence),
      <double>[0.99, 0.01],
    );
  });

  test('a candidate with no value proposes the empty value', () {
    const ValueCandidate empty = ValueCandidate(ValueSource.ocr, null, 0.5, 'p1');
    const ValueCandidate filled = ValueCandidate(
      ValueSource.barcode,
      'A-1',
      0.5,
      'p2',
    );
    final FieldConflict conflict = ConflictDetection.find(
      <String, List<ValueCandidate>>{
        'serial': <ValueCandidate>[empty, filled],
      },
    ).single;
    expect(conflict.candidates.first.value, isNull);
    expect(conflict.candidates, hasLength(2));
  });

  test('a candidate is compared by the text of its value', () {
    expect(
      ConflictDetection.find(<String, List<ValueCandidate>>{
        'qty': <ValueCandidate>[
          const ValueCandidate(ValueSource.ocr, 12, 0.9, 'p1'),
          const ValueCandidate(ValueSource.typed, '12', 1, null),
        ],
      }),
      isEmpty,
    );
    expect(
      ConflictDetection.find(<String, List<ValueCandidate>>{
        'qty': <ValueCandidate>[
          const ValueCandidate(ValueSource.ocr, 12, 0.9, 'p1'),
          const ValueCandidate(ValueSource.typed, '13', 1, null),
        ],
      }),
      hasLength(1),
    );
  });

  test('a candidate keeps its source and evidence link through detection', () {
    const ValueCandidate ocr = ValueCandidate(ValueSource.ocr, 'A-1', 0.9, 'p1');
    const ValueCandidate typed = ValueCandidate(ValueSource.typed, 'A-2', 1, null);
    final FieldConflict conflict = ConflictDetection.find(
      <String, List<ValueCandidate>>{
        'serial': <ValueCandidate>[ocr, typed],
      },
    ).single;
    expect(identical(conflict.candidates.first, ocr), isTrue);
    expect(conflict.candidates.first.evidenceId, 'p1');
    expect(conflict.candidates.first.source, ValueSource.ocr);
    expect(conflict.candidates.last.evidenceId, isNull);
    expect(conflict.candidates.last.source, ValueSource.typed);
  });
}
