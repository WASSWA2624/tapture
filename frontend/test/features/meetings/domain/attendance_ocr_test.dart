import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/meetings/domain/attendance_ocr.dart';

void main() {
  test('a fixture sheet yields the columns and each cell confidence', () {
    final Map<String, Object?> json = Map<String, Object?>.from(
      jsonDecode(
            File(
              'test/features/meetings/fixtures/attendance_sheet.json',
            ).readAsStringSync(),
          )
          as Map<Object?, Object?>,
    );
    final List<OcrCell> cells = <OcrCell>[
      for (final Object? row in json['cells']! as List<Object?>)
        () {
          final Map<String, Object?> cell = Map<String, Object?>.from(
            row! as Map<Object?, Object?>,
          );
          return (
            text: cell['text']! as String,
            confidence: (cell['confidence']! as num).toDouble(),
            x: (cell['x']! as num).toDouble(),
            y: (cell['y']! as num).toDouble(),
          );
        }(),
    ];
    final readings = AttendanceOcr.read(cells);
    expect(readings, hasLength(1));
    expect(readings.single.name, 'Ada Lovelace');
    expect(readings.single.title, 'Chair');
    expect(readings.single.organisation, 'Analytical');
    expect(readings.single.signaturePresent, isTrue);
    expect(readings.single.nameConfidence, 0.91);
    expect(readings.single.titleConfidence, 0.8);
    expect(readings.single.organisationConfidence, 0.77);
    expect(readings.single.signatureConfidence, 0.7);
  });

  test('an empty sheet has no rows', () {
    expect(AttendanceOcr.read(const <OcrCell>[]), isEmpty);
  });
}
