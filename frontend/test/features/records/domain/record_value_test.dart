import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/fields/field_value.dart';
import 'package:tapture/features/records/domain/record_value.dart';

void main() {
  const RecordValue captured = RecordValue(
    fieldKey: 'serial',
    raw: 'SN-1',
    source: 'ocr',
    confidence: 0.7,
    band: 'medium',
  );

  group('display', () {
    test('reads approved, then refined, then raw', () {
      expect(captured.display, 'SN-1');
      expect(captured.copyWith(refined: 'SN-2').display, 'SN-2');
      expect(
        captured.copyWith(refined: 'SN-2', approved: 'SN-3').display,
        'SN-3',
      );
    });

    test('skips an empty stage rather than showing a blank', () {
      expect(captured.copyWith(approved: '', refined: 'SN-2').display, 'SN-2');
      expect(captured.copyWith(refined: '').display, 'SN-1');
    });

    test('is empty only when every stage is', () {
      expect(const RecordValue(fieldKey: 'notes').display, isEmpty);
      expect(const RecordValue(fieldKey: 'notes').hasValue, isFalse);
      expect(captured.hasValue, isTrue);
    });
  });

  group('valueSource', () {
    test('maps every stored spelling in use', () {
      const Map<String, ValueSource> expected = <String, ValueSource>{
        'TYPED': ValueSource.manual,
        'manual': ValueSource.manual,
        'MANUAL': ValueSource.manual,
        'CONTEXT': ValueSource.context,
        'ocr': ValueSource.ocr,
        'extraction': ValueSource.aiVision,
        'aiText': ValueSource.aiText,
        'stt': ValueSource.stt,
        'barcode': ValueSource.barcode,
        'lookup': ValueSource.lookup,
        'default': ValueSource.auto,
        'IMPORTED_TABLE': ValueSource.import,
      };
      expected.forEach((String stored, ValueSource source) {
        expect(RecordValue.sourceOf(stored), source, reason: stored);
      });
      expect(captured.valueSource, ValueSource.ocr);
    });

    test('an unknown source reads as manual', () {
      expect(RecordValue.sourceOf('carrier pigeon'), ValueSource.manual);
    });

    test('an edit writes the manual source', () {
      expect(
        RecordValue.sourceOf(RecordValue.manualSource),
        ValueSource.manual,
      );
    });
  });

  group('toFieldValue', () {
    test('hands the editor the display text, source and verification', () {
      final FieldValue value = captured
          .copyWith(refined: 'SN-9', verified: true)
          .toFieldValue();
      expect(value.fieldKey, 'serial');
      expect(value.value, 'SN-9');
      expect(value.source, ValueSource.ocr);
      expect(value.verified, isTrue);
      expect(value.audit, isEmpty);
    });

    test('decodes the text when the caller knows the field type', () {
      const RecordValue count = RecordValue(fieldKey: 'count', raw: '12');
      expect(count.toFieldValue(int.tryParse).value, 12);
    });
  });

  test('values with the same fields are equal', () {
    const RecordValue same = RecordValue(
      fieldKey: 'serial',
      raw: 'SN-1',
      source: 'ocr',
      confidence: 0.7,
      band: 'medium',
    );
    expect(captured, same);
    expect(captured.hashCode, same.hashCode);
    expect(captured, isNot(captured.copyWith(retired: true)));
    expect(captured, isNot(captured.copyWith(evidenceRemoved: true)));
  });

  test('copyWith keeps the rest and clears only what is asked', () {
    final RecordValue refined = captured.copyWith(
      refined: 'SN-2',
      approved: 'SN-2',
      provider: 'provider-a',
      model: 'model-b',
      method: 'localOcr',
    );
    expect(refined.raw, 'SN-1');
    expect(refined.provider, 'provider-a');
    expect(refined.model, 'model-b');
    expect(refined.method, 'localOcr');
    final RecordValue cleared = refined.copyWith(
      clearRefined: true,
      clearApproved: true,
      clearConfidence: true,
    );
    expect(cleared.refined, isNull);
    expect(cleared.approved, isNull);
    expect(cleared.confidence, isNull);
    expect(cleared.band, 'medium');
    expect(captured.copyWith(), captured);
  });

  test('toString names the field and never the value', () {
    expect(captured.toString(), 'RecordValue(serial)');
    expect(captured.toString(), isNot(contains('SN-1')));
  });
}
