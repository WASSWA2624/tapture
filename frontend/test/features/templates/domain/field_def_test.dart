import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/templates/domain/field_def.dart';

void main() {
  test('requiredness is the three-value enum, never a bool', () {
    expect(Requiredness.values, <Requiredness>[
      Requiredness.required,
      Requiredness.recommended,
      Requiredness.optional,
    ]);
    const FieldDef field = FieldDef(
      fieldKey: 'serial',
      label: 'Serial',
      type: FieldType.text,
    );
    expect(field.requiredness, Requiredness.optional);
    expect(
      field.copyWith(requiredness: Requiredness.recommended).requiredness,
      Requiredness.recommended,
    );
    expect(
      field.copyWith(requiredness: Requiredness.required).requiredness,
      Requiredness.required,
    );
  });

  test('copyWith keeps every §12.2 attribute the caller does not name', () {
    const FieldDef original = FieldDef(
      fieldKey: 'serial',
      label: 'Serial',
      type: FieldType.number,
      requiredness: Requiredness.recommended,
      unit: 'kg',
      helpText: 'On the plate',
      inputMode: InputMode.manualOnly,
      stickable: true,
      contextLevel: 1,
      autoFill: AutoFill.today,
      refine: true,
      group: 'identity',
      outputColumn: 'B',
      requiredWhen: 'fault_present == true',
      hidden: true,
      identity: true,
    );
    final FieldDef relabelled = original.copyWith(label: 'Serial number');
    expect(relabelled.label, 'Serial number');
    expect(relabelled.fieldKey, original.fieldKey);
    expect(relabelled.type, FieldType.number);
    expect(relabelled.requiredness, Requiredness.recommended);
    expect(relabelled.unit, 'kg');
    expect(relabelled.helpText, 'On the plate');
    expect(relabelled.inputMode, InputMode.manualOnly);
    expect(relabelled.stickable, isTrue);
    expect(relabelled.autoFill, AutoFill.today);
    expect(relabelled.refine, isTrue);
    expect(relabelled.hidden, isTrue);
    expect(relabelled.identity, isTrue);
  });

  test('FieldType names every type of §12.1', () {
    expect(FieldType.values, hasLength(19));
    expect(
      FieldType.values,
      containsAll(<FieldType>[
        FieldType.text,
        FieldType.longText,
        FieldType.number,
        FieldType.decimal,
        FieldType.currency,
        FieldType.percentage,
        FieldType.date,
        FieldType.time,
        FieldType.dateTime,
        FieldType.boolean,
        FieldType.choice,
        FieldType.multiChoice,
        FieldType.lookup,
        FieldType.barcode,
        FieldType.photoReference,
        FieldType.documentReference,
        FieldType.gpsLocation,
        FieldType.signature,
        FieldType.computed,
      ]),
    );
  });
}
