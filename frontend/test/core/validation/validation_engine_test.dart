import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/validation/validation.dart';

void main() {
  const FieldRule serial = FieldRule(
    fieldKey: 'serial',
    label: 'Serial',
    identity: true,
    pattern: r'^[A-Z]+-\d+$',
    minLength: 3,
    maxLength: 12,
  );
  const FieldRule qty = FieldRule(
    fieldKey: 'qty',
    label: 'Quantity',
    min: 1,
    max: 10,
  );
  const FieldRule fault = FieldRule(fieldKey: 'fault_present', label: 'Fault');
  const FieldRule note = FieldRule(
    fieldKey: 'note',
    label: 'Note',
    requiredWhen: 'fault_present == true',
  );
  const FieldRule grade = FieldRule(
    fieldKey: 'grade',
    label: 'Grade',
    options: <String>['Good', 'Fair'],
  );
  const FieldRule volume = FieldRule(
    fieldKey: 'volume',
    label: 'Volume',
    unit: 'L',
    recommended: true,
  );

  const ValidationEngine engine = validationEngine;

  group('field rules', () {
    test('a matching serial passes', () {
      expect(
        engine.validateField(serial, 'ABB-1234', const <String, Object?>{}),
        isEmpty,
      );
    });

    test('an empty identity field is an error', () {
      final List<ValidationIssue> issues = engine.validateField(
        serial,
        '',
        const <String, Object?>{},
      );
      expect(issues.single.blocks, isTrue);
      expect(issues.single.message, Copy.validationIdentity('Serial'));
    });

    test('a short value, a long value and a pattern miss are errors', () {
      expect(
        engine
            .validateField(serial, 'A', const <String, Object?>{})
            .any(
              (ValidationIssue issue) =>
                  issue.message == Copy.validationTooShort('Serial'),
            ),
        isTrue,
      );
      expect(
        engine
            .validateField(serial, 'ABCDEFGHIJKLM', const <String, Object?>{})
            .any(
              (ValidationIssue issue) =>
                  issue.message == Copy.validationTooLong('Serial'),
            ),
        isTrue,
      );
      expect(
        engine
            .validateField(serial, 'abb', const <String, Object?>{})
            .any(
              (ValidationIssue issue) =>
                  issue.message == Copy.validationPattern('Serial'),
            ),
        isTrue,
      );
    });

    test('a number outside the range is an error and one inside passes', () {
      expect(
        engine.validateField(qty, '0', const <String, Object?>{}),
        isNotEmpty,
      );
      expect(
        engine.validateField(qty, '4', const <String, Object?>{}),
        isEmpty,
      );
    });

    test('a choice outside the list is an error', () {
      expect(
        engine.validateField(grade, 'Bad', const <String, Object?>{}),
        isNotEmpty,
      );
      expect(
        engine.validateField(grade, 'good', const <String, Object?>{}),
        isEmpty,
      );
    });

    test('a unit the field cannot store is an error', () {
      expect(
        engine.validateField(volume, '3 furlongs', const <String, Object?>{}),
        isNotEmpty,
      );
      expect(
        engine.validateField(volume, '3 L', const <String, Object?>{}),
        isEmpty,
      );
    });

    test('an empty recommended field warns and does not block', () {
      final ValidationIssue issue = engine
          .validateField(volume, '', const <String, Object?>{})
          .single;
      expect(issue.severity, Severity.warning);
      expect(issue.blocks, isFalse);
    });

    test('required_when makes the field required only when it is true', () {
      expect(
        engine.validateField(note, '', const <String, Object?>{
          'fault_present': false,
        }),
        isEmpty,
      );
      expect(
        engine
            .validateField(note, '', const <String, Object?>{
              'fault_present': true,
            })
            .single
            .blocks,
        isTrue,
      );
    });
  });

  group('expressions', () {
    test('arithmetic and comparison evaluate', () {
      final FieldExpression qtyCost = _parse('qty * unit_cost', <String>[
        'qty',
        'unit_cost',
      ]);
      expect(
        evaluate(qtyCost, const <String, Object?>{'qty': 2, 'unit_cost': 4}),
        8,
      );
      final FieldExpression fault = _parse('fault_present == true', <String>[
        'fault_present',
      ]);
      expect(
        evaluate(fault, const <String, Object?>{'fault_present': true}),
        isTrue,
      );
    });

    test('a missing operand and a type mismatch yield null', () {
      final FieldExpression product = _parse('qty * unit_cost', <String>[
        'qty',
        'unit_cost',
      ]);
      expect(evaluate(product, const <String, Object?>{'qty': 2}), isNull);
      expect(
        evaluate(product, const <String, Object?>{
          'qty': 'two',
          'unit_cost': 4,
        }),
        isNull,
      );
    });

    test('an unknown field fails to parse and does not throw', () {
      final Result<FieldExpression> parsed = FieldExpression.parse(
        'missing == true',
        const <String>['fault_present'],
      );
      expect(parsed, isA<FailureResult<FieldExpression>>());
    });

    test('and, or and not combine booleans', () {
      final FieldExpression expression = _parse(
        'not fault_present or qty > 1 and ready == true',
        const <String>['fault_present', 'qty', 'ready'],
      );
      expect(
        evaluate(expression, const <String, Object?>{
          'fault_present': false,
          'qty': 2,
          'ready': true,
        }),
        isTrue,
      );
    });
  });

  group('records and export sets', () {
    test('an empty identity field blocks the record', () {
      final List<ValidationIssue> issues = engine.validateRecord(
        fields: const <FieldRule>[serial, fault],
        values: const <String, Object?>{'serial': '', 'fault_present': false},
        hasEvidence: true,
      );
      expect(issues.any((ValidationIssue issue) => issue.blocks), isTrue);
    });

    test('missing evidence blocks when a field demands it', () {
      const FieldRule photo = FieldRule(
        fieldKey: 'photo',
        label: 'Photo',
        requiresEvidence: true,
      );
      final List<ValidationIssue> issues = engine.validateRecord(
        fields: const <FieldRule>[photo],
        values: const <String, Object?>{},
        hasEvidence: false,
      );
      expect(
        issues.any(
          (ValidationIssue issue) => issue.message == Copy.validationEvidence,
        ),
        isTrue,
      );
    });

    test('an unresolved conflict names the field and blocks', () {
      final ValidationIssue issue = engine
          .validateRecord(
            fields: const <FieldRule>[serial],
            values: const <String, Object?>{'serial': 'ABB-1'},
            hasEvidence: true,
            conflicts: const <String>['serial'],
          )
          .single;
      expect(issue.blocks, isTrue);
      expect(issue.fieldKey, 'serial');
      expect(issue.message, contains('Serial'));
    });

    test('an export set collects each record\'s errors', () {
      final List<ValidationIssue> issues = engine.validateExportSet(
        fields: const <FieldRule>[serial],
        records: const <Map<String, Object?>>[
          <String, Object?>{'serial': ''},
          <String, Object?>{'serial': 'ABB-1'},
        ],
        hasEvidence: (_) => true,
      );
      expect(issues, isNotEmpty);
      expect(issues.every((ValidationIssue issue) => issue.blocks), isTrue);
    });

    test('a warning does not block', () {
      final List<ValidationIssue> issues = engine.validateRecord(
        fields: const <FieldRule>[volume],
        values: const <String, Object?>{'volume': ''},
        hasEvidence: true,
      );
      expect(
        engine.validateField(volume, '', const <String, Object?>{}),
        issues,
      );
      expect(issues.every((ValidationIssue issue) => !issue.blocks), isTrue);
    });
  });
}

FieldExpression _parse(String source, List<String> keys) {
  final Result<FieldExpression> parsed = FieldExpression.parse(source, keys);
  expect(parsed, isA<Success<FieldExpression>>());
  return (parsed as Success<FieldExpression>).value;
}
