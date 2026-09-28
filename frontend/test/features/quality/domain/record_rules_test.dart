import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/validation/validation.dart';
import 'package:tapture/features/quality/quality.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';

void main() {
  const FieldDef serial = FieldDef(
    fieldKey: 'serial',
    label: 'Serial',
    type: FieldType.text,
  );
  const FieldDef qty = FieldDef(
    fieldKey: 'qty',
    label: 'Quantity',
    type: FieldType.number,
  );
  const FieldDef fault = FieldDef(
    fieldKey: 'fault_present',
    label: 'Fault',
    type: FieldType.boolean,
  );
  const FieldDef note = FieldDef(
    fieldKey: 'note',
    label: 'Note',
    type: FieldType.text,
    requiredWhen: 'fault_present == true',
  );
  const FieldDef volume = FieldDef(
    fieldKey: 'volume',
    label: 'Volume',
    type: FieldType.text,
    requiredness: Requiredness.recommended,
  );
  const FieldDef photo = FieldDef(
    fieldKey: 'photo',
    label: 'Photo',
    type: FieldType.text,
    validation: <String, Object?>{'evidence': true},
  );
  const FieldDef legacy = FieldDef(
    fieldKey: 'legacy',
    label: 'Legacy',
    type: FieldType.number,
    requiredness: Requiredness.required,
    hidden: true,
  );
  const FieldDef total = FieldDef(
    fieldKey: 'total',
    label: 'Total',
    type: FieldType.computed,
    validation: <String, Object?>{'expression': 'qty * 2'},
  );
  final FieldDef requiredSerial = serial.copyWith(
    requiredness: Requiredness.required,
  );

  group('validateField', () {
    test('a whole-number field holding text is a type error', () {
      final List<ValidationIssue> issues = RecordRules.validateField(
        qty,
        'abc',
        const <String, Object?>{},
      );
      final Result<void> typed = FieldTypeRegistry.validate(
        type: FieldType.number,
        value: 'abc',
        field: qty,
      );
      expect(typed, isA<FailureResult<void>>());
      expect(issues.single.fieldKey, 'qty');
      expect(issues.single.blocks, isTrue);
      expect(
        issues.single.message,
        (typed as FailureResult<void>).failure.message,
      );
    });

    test('a whole number passes the type check', () {
      expect(
        RecordRules.validateField(qty, '12', const <String, Object?>{}),
        isEmpty,
      );
    });

    test('an empty required field is an error naming the field', () {
      final List<ValidationIssue> issues = RecordRules.validateField(
        requiredSerial,
        '',
        const <String, Object?>{},
      );
      expect(issues.single.fieldKey, 'serial');
      expect(issues.single.severity, Severity.error);
      expect(issues.single.message, Copy.validationRequired('Serial'));
    });

    test('an empty recommended field warns and never blocks', () {
      final List<ValidationIssue> issues = RecordRules.validateField(
        volume,
        '',
        const <String, Object?>{},
      );
      expect(issues.single.severity, Severity.warning);
      expect(issues.single.blocks, isFalse);
      expect(RecordRules.blocks(issues), isFalse);
    });

    test('a required_when field is required only while its trigger holds', () {
      final List<ValidationIssue> triggered = RecordRules.validateField(
        note,
        '',
        const <String, Object?>{'fault_present': true},
      );
      expect(triggered.single.message, Copy.validationRequired('Note'));
      expect(triggered.single.blocks, isTrue);
      expect(
        RecordRules.validateField(note, '', const <String, Object?>{
          'fault_present': false,
        }),
        isEmpty,
      );
    });
  });

  group('validateRecord', () {
    test('a hidden field is not checked, whatever it holds', () {
      final List<ValidationIssue> issues = RecordRules.validateRecord(
        template: aTemplate(fields: const <FieldDef>[legacy]),
        values: const <String, Object?>{'legacy': 'abc'},
        hasEvidence: true,
      );
      expect(issues, isEmpty);
    });

    test('an empty identity field named by the template blocks approval', () {
      final List<ValidationIssue> issues = RecordRules.validateRecord(
        template: aTemplate(
          fields: const <FieldDef>[serial],
          identityFieldKeys: const <String>['serial'],
        ),
        values: const <String, Object?>{},
        hasEvidence: true,
      );
      expect(
        issues,
        contains(
          ValidationIssue(
            'serial',
            Severity.error,
            Copy.validationIdentity('Serial'),
          ),
        ),
      );
      expect(RecordRules.blocks(issues), isTrue);
    });

    test('a field flagged identity on its own row blocks when empty', () {
      final List<ValidationIssue> issues = RecordRules.validateRecord(
        template: aTemplate(
          fields: <FieldDef>[serial.copyWith(identity: true)],
        ),
        values: const <String, Object?>{'serial': '  '},
        hasEvidence: true,
      );
      expect(issues.single.message, Copy.validationIdentity('Serial'));
    });

    test('a filled identity field does not block', () {
      final List<ValidationIssue> issues = RecordRules.validateRecord(
        template: aTemplate(
          fields: const <FieldDef>[serial],
          identityFieldKeys: const <String>['serial'],
        ),
        values: const <String, Object?>{'serial': 'ABB-1234'},
        hasEvidence: true,
      );
      expect(issues, isEmpty);
    });

    test('an empty required_when-triggered field blocks approval', () {
      final TemplateDef template = aTemplate(
        fields: const <FieldDef>[fault, note],
      );
      final List<ValidationIssue> triggered = RecordRules.validateRecord(
        template: template,
        values: const <String, Object?>{'fault_present': true},
        hasEvidence: true,
      );
      expect(triggered.single.fieldKey, 'note');
      expect(triggered.single.blocks, isTrue);
      expect(
        RecordRules.validateRecord(
          template: template,
          values: const <String, Object?>{'fault_present': false},
          hasEvidence: true,
        ),
        isEmpty,
      );
    });

    test('evidence the template demands must be on the record', () {
      final TemplateDef template = aTemplate(fields: const <FieldDef>[photo]);
      final List<ValidationIssue> missing = RecordRules.validateRecord(
        template: template,
        values: const <String, Object?>{'photo': 'front.jpg'},
        hasEvidence: false,
      );
      expect(missing.single.fieldKey, isNull);
      expect(missing.single.message, Copy.validationEvidence);
      expect(missing.single.blocks, isTrue);
      expect(
        RecordRules.validateRecord(
          template: template,
          values: const <String, Object?>{'photo': 'front.jpg'},
          hasEvidence: true,
        ),
        isEmpty,
      );
    });

    test('an unresolved conflict blocks approval and names the field', () {
      final List<ValidationIssue> issues = RecordRules.validateRecord(
        template: aTemplate(fields: const <FieldDef>[serial]),
        values: const <String, Object?>{'serial': 'ABB-1234'},
        hasEvidence: true,
        conflicts: const <String>['serial'],
      );
      expect(issues.single.fieldKey, 'serial');
      expect(issues.single.message, Copy.conflictBlocksApproval('Serial'));
      expect(RecordRules.blocks(issues), isTrue);
    });

    test('a type error on the record names its field', () {
      final List<ValidationIssue> issues = RecordRules.validateRecord(
        template: aTemplate(fields: const <FieldDef>[serial, qty]),
        values: const <String, Object?>{'serial': 'A', 'qty': 'many'},
        hasEvidence: true,
      );
      expect(issues.single.fieldKey, 'qty');
      expect(issues.single.blocks, isTrue);
    });
  });

  group('validateExportSet', () {
    test('every record is checked and evidence is read off the record', () {
      final List<ValidationIssue> issues = RecordRules.validateExportSet(
        <Map<String, Object?>>[
          <String, Object?>{'photo': 'a.jpg', '__evidence': true},
          <String, Object?>{'photo': 'b.jpg'},
          <String, Object?>{'photo': 'c.jpg', '__evidence': false},
        ],
        aTemplate(fields: const <FieldDef>[photo]),
      );
      expect(issues, hasLength(2));
      expect(
        issues.map((ValidationIssue issue) => issue.message).toSet(),
        <String>{Copy.validationEvidence},
      );
    });

    test('an empty required field in any record blocks the export', () {
      final List<ValidationIssue> issues = RecordRules.validateExportSet(
        <Map<String, Object?>>[
          <String, Object?>{'serial': 'A-1'},
          <String, Object?>{'serial': ''},
        ],
        aTemplate(fields: <FieldDef>[requiredSerial]),
      );
      expect(issues.single.message, Copy.validationRequired('Serial'));
      expect(RecordRules.blocks(issues), isTrue);
    });

    test('a clean set has nothing blocking', () {
      final List<ValidationIssue> issues = RecordRules.validateExportSet(
        <Map<String, Object?>>[
          <String, Object?>{'serial': 'A-1', 'qty': 1},
        ],
        aTemplate(fields: <FieldDef>[requiredSerial, qty]),
      );
      expect(issues, isEmpty);
    });
  });

  group('blocks', () {
    const ValidationIssue warning = ValidationIssue(
      'volume',
      Severity.warning,
      'Volume is recommended.',
    );
    const ValidationIssue error = ValidationIssue(
      'serial',
      Severity.error,
      'Serial is required.',
    );

    test('a warning alone does not block', () {
      expect(RecordRules.blocks(const <ValidationIssue>[warning]), isFalse);
    });

    test('one error among warnings blocks', () {
      expect(
        RecordRules.blocks(const <ValidationIssue>[warning, error, warning]),
        isTrue,
      );
    });

    test('no issues never block', () {
      expect(RecordRules.blocks(const <ValidationIssue>[]), isFalse);
    });
  });

  group('ruleOf', () {
    test('requiredness maps to required or recommended, never both', () {
      final FieldRule required = RecordRules.ruleOf(requiredSerial);
      expect(required.required, isTrue);
      expect(required.recommended, isFalse);
      final FieldRule recommended = RecordRules.ruleOf(volume);
      expect(recommended.required, isFalse);
      expect(recommended.recommended, isTrue);
      final FieldRule optional = RecordRules.ruleOf(serial);
      expect(optional.required, isFalse);
      expect(optional.recommended, isFalse);
    });

    test('identity comes from the field row or the template list', () {
      expect(RecordRules.ruleOf(serial).identity, isFalse);
      expect(RecordRules.ruleOf(serial, identity: true).identity, isTrue);
      expect(
        RecordRules.ruleOf(serial.copyWith(identity: true)).identity,
        isTrue,
      );
    });

    test('evidence, the trigger and hidden carry over', () {
      expect(RecordRules.ruleOf(photo).requiresEvidence, isTrue);
      expect(RecordRules.ruleOf(serial).requiresEvidence, isFalse);
      expect(RecordRules.ruleOf(note).requiredWhen, 'fault_present == true');
      expect(RecordRules.ruleOf(legacy).hidden, isTrue);
      expect(RecordRules.ruleOf(serial).label, 'Serial');
    });

    test('only a computed field carries its expression', () {
      expect(RecordRules.ruleOf(total).computedExpression, 'qty * 2');
      expect(
        RecordRules.ruleOf(
          serial.copyWith(
            validation: const <String, Object?>{'expression': 'qty * 2'},
          ),
        ).computedExpression,
        isNull,
      );
      expect(
        RecordRules.ruleOf(
          total.copyWith(validation: const <String, Object?>{}),
        ).computedExpression,
        isNull,
      );
    });
  });
}
