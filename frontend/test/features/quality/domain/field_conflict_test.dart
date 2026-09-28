import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/features/quality/quality.dart';

void main() {
  const ValueCandidate ocr = ValueCandidate(ValueSource.ocr, 'A-1', 0.9, 'p1');
  const ValueCandidate caption = ValueCandidate(
    ValueSource.stt,
    'A-2',
    0.4,
    'c1',
  );
  const ValueCandidate reference = ValueCandidate(
    ValueSource.lookup,
    'A-1',
    1,
    null,
  );

  test('a conflict keeps every candidate in the order it was proposed', () {
    final FieldConflict conflict = ConflictDetection.find(
      <String, List<ValueCandidate>>{
        'serial': <ValueCandidate>[ocr, caption, reference],
      },
    ).single;
    expect(conflict.candidates, <ValueCandidate>[ocr, caption, reference]);
    expect(
      conflict.candidates.map((ValueCandidate c) => c.source),
      <ValueSource>[ValueSource.ocr, ValueSource.stt, ValueSource.lookup],
    );
    expect(
      conflict.candidates.map((ValueCandidate c) => c.confidence),
      <double>[0.9, 0.4, 1],
    );
    expect(
      conflict.candidates.map((ValueCandidate c) => c.evidenceId),
      <String?>['p1', 'c1', null],
    );
  });

  test('a conflict is its own list: editing the proposal leaves it intact', () {
    final List<ValueCandidate> proposal = <ValueCandidate>[ocr, caption];
    final FieldConflict conflict = ConflictDetection.find(
      <String, List<ValueCandidate>>{'serial': proposal},
    ).single;
    proposal.clear();
    expect(conflict.candidates, <ValueCandidate>[ocr, caption]);
  });

  test('each conflict names the field its candidates belong to', () {
    final List<FieldConflict> conflicts = ConflictDetection.find(
      <String, List<ValueCandidate>>{
        'serial': <ValueCandidate>[ocr, caption],
        'tag': <ValueCandidate>[
          const ValueCandidate(ValueSource.barcode, 'T-1', 0.8, 'p2'),
          const ValueCandidate(ValueSource.ocr, 'T-9', 0.3, 'p3'),
        ],
      },
    );
    expect(conflicts.map((FieldConflict c) => c.fieldKey), <String>[
      'serial',
      'tag',
    ]);
    expect(
      conflicts[1].candidates.map((ValueCandidate c) => c.value),
      <Object?>['T-1', 'T-9'],
    );
  });
}
