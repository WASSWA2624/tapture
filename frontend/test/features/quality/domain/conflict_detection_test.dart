import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/features/quality/quality.dart';

void main() {
  const ValueCandidate ocr = ValueCandidate(ValueSource.ocr, 'ABB-1234', 0.9, 'p1');
  const ValueCandidate barcodeSame = ValueCandidate(
    ValueSource.barcode,
    'abb 1234',
    0.8,
    'p2',
  );
  const ValueCandidate barcodeOther = ValueCandidate(
    ValueSource.barcode,
    'ABB-9999',
    0.4,
    'p2',
  );

  test('the specification example is one value, not a conflict', () {
    expect(
      ConflictDetection.find(<String, List<ValueCandidate>>{
        'serial': <ValueCandidate>[ocr, barcodeSame],
      }),
      isEmpty,
    );
  });

  test('a genuine difference raises a conflict naming the field', () {
    final List<FieldConflict> conflicts = ConflictDetection.find(
      <String, List<ValueCandidate>>{
        'serial': <ValueCandidate>[ocr, barcodeOther],
      },
    );
    expect(conflicts.single.fieldKey, 'serial');
    expect(conflicts.single.candidates, hasLength(2));
  });

  test('a single candidate is never a conflict', () {
    expect(
      ConflictDetection.find(<String, List<ValueCandidate>>{
        'serial': <ValueCandidate>[ocr],
      }),
      isEmpty,
    );
  });

  test('a null value and an empty string are the same value', () {
    expect(
      ConflictDetection.find(<String, List<ValueCandidate>>{
        'note': <ValueCandidate>[
          const ValueCandidate(ValueSource.ocr, null, 0.5, 'p1'),
          const ValueCandidate(ValueSource.caption, '', 0.5, 'c1'),
        ],
      }),
      isEmpty,
    );
  });

  test('normalisation-only differences never raise a conflict', () {
    const List<String> spellings = <String>[
      'ABB-1234',
      'abb 1234',
      ' abb_1234 ',
      'A.B.B. 12 34',
      'ABB1234',
    ];
    final List<FieldConflict> conflicts = ConflictDetection.find(
      <String, List<ValueCandidate>>{
        'serial': <ValueCandidate>[
          for (final String spelling in spellings)
            ValueCandidate(ValueSource.ocr, spelling, 0.5, null),
        ],
      },
    );
    expect(conflicts, isEmpty);
  });

  test('a conflict keeps every candidate, even the ones that agree', () {
    final List<FieldConflict> conflicts = ConflictDetection.find(
      <String, List<ValueCandidate>>{
        'serial': <ValueCandidate>[ocr, barcodeSame, barcodeOther],
      },
    );
    final List<ValueCandidate> kept = conflicts.single.candidates;
    expect(kept, <ValueCandidate>[ocr, barcodeSame, barcodeOther]);
    expect(kept.map((ValueCandidate c) => c.source), <ValueSource>[
      ValueSource.ocr,
      ValueSource.barcode,
      ValueSource.barcode,
    ]);
    expect(kept.map((ValueCandidate c) => c.evidenceId), <String?>[
      'p1',
      'p2',
      'p2',
    ]);
  });

  test('only the fields that differ are reported, in input order', () {
    final List<FieldConflict> conflicts = ConflictDetection.find(
      <String, List<ValueCandidate>>{
        'name': <ValueCandidate>[
          const ValueCandidate(ValueSource.ocr, 'Pump', 0.9, 'p1'),
          const ValueCandidate(ValueSource.caption, 'Valve', 0.7, 'c1'),
        ],
        'serial': <ValueCandidate>[ocr, barcodeSame],
        'site': <ValueCandidate>[
          const ValueCandidate(ValueSource.reference, 'North', 1, null),
          const ValueCandidate(ValueSource.ocr, 'South', 0.6, 'p3'),
        ],
      },
    );
    expect(conflicts.map((FieldConflict c) => c.fieldKey), <String>[
      'name',
      'site',
    ]);
  });

  test('an empty proposal set has no conflicts', () {
    expect(
      ConflictDetection.find(const <String, List<ValueCandidate>>{}),
      isEmpty,
    );
    expect(
      ConflictDetection.find(<String, List<ValueCandidate>>{
        'serial': <ValueCandidate>[],
      }),
      isEmpty,
    );
  });
}
