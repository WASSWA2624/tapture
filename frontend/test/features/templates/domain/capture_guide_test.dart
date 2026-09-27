import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/templates/templates.dart';

import '../../../support/factories.dart';

void main() {
  test('an asset template asks the photos for its identity and barcode', () {
    final CaptureGuide guide = CaptureGuide.of(_asset);

    expect(guide.photoFields, <String>[
      'Item identifier',
      'Serial number',
      'Barcode value',
    ]);
    expect(guide.captionFields, <String>[
      'Item name',
      'Equipment name',
      'Condition grade',
    ]);
    expect(guide.isEmpty, isFalse);
  });

  test('inherited, automatic, context and file fields are never asked for', () {
    final CaptureGuide guide = CaptureGuide.of(_asset);

    for (final String hidden in <String>[
      'Record status',
      'Country',
      'Photo count',
      'Reviewed by',
      'Site ref',
      'Captured by',
      'District',
      'Signature',
      'Secret',
    ]) {
      expect(guide.captionFields, isNot(contains(hidden)), reason: hidden);
      expect(guide.photoFields, isNot(contains(hidden)), reason: hidden);
    }
  });

  test('a built template with no identity fields guides the caption only', () {
    final CaptureGuide guide = CaptureGuide.of(
      aTemplate(
        fields: const <FieldDef>[
          FieldDef(
            fieldKey: 'finding',
            label: 'Finding',
            type: FieldType.text,
            requiredness: Requiredness.required,
          ),
          FieldDef(
            fieldKey: 'note',
            label: 'Note',
            type: FieldType.longText,
            requiredness: Requiredness.optional,
            sortOrder: 1,
          ),
        ],
      ),
    );

    expect(guide.photoFields, isEmpty);
    expect(guide.captionFields, <String>['Finding']);
  });

  test('a template with nothing to ask shows no guide', () {
    expect(CaptureGuide.of(aTemplate()).isEmpty, isTrue);
  });

  test('each list stops at the cap', () {
    final CaptureGuide guide = CaptureGuide.of(
      aTemplate(
        fields: <FieldDef>[
          for (int i = 0; i < 10; i++)
            FieldDef(
              fieldKey: 'f$i',
              label: 'Field $i',
              type: FieldType.text,
              requiredness: Requiredness.recommended,
              sortOrder: i,
            ),
        ],
      ),
    );

    expect(guide.captionFields, hasLength(6));
    expect(guide.captionFields.first, 'Field 0');
  });
}

final TemplateDef _asset = aTemplate(
  identityFieldKeys: const <String>['item_identifier', 'serial_number'],
  fields: const <FieldDef>[
    FieldDef(
      fieldKey: 'record_status',
      label: 'Record status',
      type: FieldType.text,
      requiredness: Requiredness.required,
      group: 'record_admin',
      inputMode: InputMode.auto,
    ),
    FieldDef(
      fieldKey: 'country',
      label: 'Country',
      type: FieldType.text,
      requiredness: Requiredness.recommended,
      group: 'location',
      sortOrder: 1,
    ),
    FieldDef(
      fieldKey: 'photo_count',
      label: 'Photo count',
      type: FieldType.number,
      requiredness: Requiredness.recommended,
      group: 'evidence',
      sortOrder: 2,
    ),
    FieldDef(
      fieldKey: 'reviewed_by',
      label: 'Reviewed by',
      type: FieldType.text,
      requiredness: Requiredness.recommended,
      group: 'review',
      sortOrder: 3,
    ),
    FieldDef(
      fieldKey: 'site_ref',
      label: 'Site ref',
      type: FieldType.text,
      requiredness: Requiredness.recommended,
      group: 'context',
      stickable: true,
      sortOrder: 4,
    ),
    FieldDef(
      fieldKey: 'item_identifier',
      label: 'Item identifier',
      type: FieldType.text,
      requiredness: Requiredness.recommended,
      group: 'asset',
      sortOrder: 5,
    ),
    FieldDef(
      fieldKey: 'item_name',
      label: 'Item name',
      type: FieldType.text,
      requiredness: Requiredness.required,
      group: 'asset',
      sortOrder: 6,
    ),
    FieldDef(
      fieldKey: 'serial_number',
      label: 'Serial number',
      type: FieldType.text,
      requiredness: Requiredness.recommended,
      group: 'asset',
      sortOrder: 7,
    ),
    FieldDef(
      fieldKey: 'barcode_value',
      label: 'Barcode value',
      type: FieldType.barcode,
      requiredness: Requiredness.optional,
      group: 'asset',
      sortOrder: 8,
    ),
    FieldDef(
      fieldKey: 'equipment_name',
      label: 'Equipment name',
      type: FieldType.text,
      requiredness: Requiredness.recommended,
      group: 'specific_details',
      sortOrder: 9,
    ),
    FieldDef(
      fieldKey: 'condition_grade',
      label: 'Condition grade',
      type: FieldType.choice,
      requiredness: Requiredness.recommended,
      group: 'asset',
      sortOrder: 10,
    ),
    FieldDef(
      fieldKey: 'captured_by',
      label: 'Captured by',
      type: FieldType.text,
      requiredness: Requiredness.recommended,
      autoFill: AutoFill.now,
      sortOrder: 11,
    ),
    FieldDef(
      fieldKey: 'district',
      label: 'District',
      type: FieldType.text,
      requiredness: Requiredness.recommended,
      contextLevel: 1,
      sortOrder: 12,
    ),
    FieldDef(
      fieldKey: 'signature',
      label: 'Signature',
      type: FieldType.signature,
      requiredness: Requiredness.recommended,
      sortOrder: 13,
    ),
    FieldDef(
      fieldKey: 'secret',
      label: 'Secret',
      type: FieldType.text,
      requiredness: Requiredness.required,
      hidden: true,
      sortOrder: 14,
    ),
  ],
);
