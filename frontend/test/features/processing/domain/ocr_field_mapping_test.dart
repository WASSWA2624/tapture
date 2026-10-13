import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/identifier_extraction.dart';
import 'package:tapture/features/processing/domain/identifier_ownership.dart';
import 'package:tapture/features/processing/domain/ocr_field_mapping.dart';
import 'package:tapture/features/processing/domain/ocr_mapping_outcome.dart';
import 'package:tapture/features/processing/domain/ocr_mapping_profile.dart';
import 'package:tapture/features/processing/domain/ocr_parameter_block.dart';
import 'package:tapture/features/templates/domain/domain.dart';

void main() {
  OcrMappingProfile profile(
    List<FieldDef> fields, {
    String key = 'custom_plate',
  }) => OcrMappingProfile.fromTemplate(
    TemplateDef(
      id: 'captured-template',
      templateKey: key,
      name: 'Captured template',
      version: 3,
      fields: fields,
      identityFieldKeys: const <String>[],
      rows: const <TemplateRow>[],
    ),
  );

  OcrMappingOutcome map(
    String text,
    List<FieldDef> fields, {
    List<OcrParameterBlock> blocks = const <OcrParameterBlock>[],
  }) => OcrFieldMapping.extract(
    text: text,
    profile: profile(fields),
    blocks: blocks,
  );

  const FieldDef serial = FieldDef(
    fieldKey: 'serial_number',
    label: 'Serial number',
    type: FieldType.text,
    validation: <String, Object?>{'pattern': r'^SN\d{6}$'},
  );
  const FieldDef model = FieldDef(
    fieldKey: 'model_number',
    label: 'Model number',
    type: FieldType.text,
  );
  const FieldDef voltage = FieldDef(
    fieldKey: 'voltage',
    label: 'Voltage (V)',
    type: FieldType.decimal,
    unit: 'V',
  );

  test('plate labels map distinct parameters to their template fields', () {
    final OcrMappingOutcome outcome = map(
      'Manufacturer: ACME Medical\nModel: MED-1300 Serial no.: SN458923\nVoltage: 220 V',
      const <FieldDef>[
        FieldDef(
          fieldKey: 'manufacturer_name',
          label: 'Manufacturer name',
          type: FieldType.text,
        ),
        model,
        serial,
        voltage,
      ],
    );
    expect(
      <String, String>{for (final c in outcome.candidates) c.fieldKey: c.value},
      <String, String>{
        'manufacturer_name': 'ACME Medical',
        'model_number': 'MED-1300',
        'serial_number': 'SN458923',
        'voltage': '220 V',
      },
    );
    expect(outcome.findings, isEmpty);
    expect(outcome.candidates.last.normalised, '220');
  });

  test('a split label and value keep the nearest row and exact region', () {
    final OcrMappingOutcome outcome = map(
      'Voltage\n220 V\nModel\nMED-1300',
      const <FieldDef>[voltage, model],
      blocks: const <OcrParameterBlock>[
        (
          text: 'Voltage',
          left: 0,
          top: 0,
          right: 100,
          bottom: 20,
          confidence: 0.9,
        ),
        (
          text: '220 V',
          left: 120,
          top: 0,
          right: 180,
          bottom: 20,
          confidence: 0.84,
        ),
        (
          text: 'Model',
          left: 0,
          top: 40,
          right: 100,
          bottom: 60,
          confidence: 0.9,
        ),
        (
          text: 'MED-1300',
          left: 120,
          top: 40,
          right: 220,
          bottom: 60,
          confidence: 0.88,
        ),
      ],
    );
    expect(outcome.candidates.map((c) => c.value), <String>[
      '220 V',
      'MED-1300',
    ]);
    expect(outcome.candidates.first.blockIndex, 1);
    expect(outcome.candidates.first.confidence, 0.84);
    expect(outcome.candidates.first.snippet, '220 V');
  });

  test('equally near table cells are left for manual review', () {
    final OcrMappingOutcome outcome = map(
      'Voltage\n220 V\n240 V',
      const <FieldDef>[voltage],
      blocks: const <OcrParameterBlock>[
        (
          text: 'Voltage',
          left: 0,
          top: 0,
          right: 100,
          bottom: 20,
          confidence: 0.9,
        ),
        (
          text: '220 V',
          left: 120,
          top: 0,
          right: 180,
          bottom: 10,
          confidence: 0.9,
        ),
        (
          text: '240 V',
          left: 120,
          top: 10,
          right: 180,
          bottom: 20,
          confidence: 0.9,
        ),
      ],
    );
    expect(outcome.candidates, isEmpty);
  });

  test('custom aliases map only within the captured template version', () {
    final OcrMappingProfile custom = profile(const <FieldDef>[
      FieldDef(
        fieldKey: 'reading',
        label: 'Measured potential',
        type: FieldType.decimal,
        unit: 'V',
        validation: <String, Object?>{
          'ocr_aliases': <String>['Input potential'],
        },
      ),
    ]);
    final OcrMappingOutcome outcome = OcrFieldMapping.extract(
      text: 'Input potential: 230 V',
      blocks: const <OcrParameterBlock>[],
      profile: custom,
    );
    expect(custom.templateKey, 'custom_plate');
    expect(custom.templateVersion, 3);
    expect(outcome.candidates.single.fieldKey, 'reading');
    expect(outcome.candidates.single.value, '230 V');
  });

  test('shared labels and aliases never resolve by field order', () {
    final OcrMappingOutcome outcome = map('Reading: 10', const <FieldDef>[
      FieldDef(fieldKey: 'inlet', label: 'Reading', type: FieldType.decimal),
      FieldDef(fieldKey: 'outlet', label: 'Reading', type: FieldType.decimal),
    ]);
    expect(outcome.candidates, isEmpty);
    expect(outcome.labelledKeys, <String>{'inlet', 'outlet'});
    expect(outcome.findings, hasLength(2));
  });

  test('typed mapping rejects ambiguity malformed quantities and inventions', () {
    final OcrMappingOutcome outcome = map(
      'Voltage: 220 V ignore this\nInspection date: 03/04/2026\nSerial: SN458923X\nCondition: not working\nCount: 2.5',
      const <FieldDef>[
        voltage,
        serial,
        FieldDef(
          fieldKey: 'inspection_date',
          label: 'Inspection date',
          type: FieldType.date,
        ),
        FieldDef(
          fieldKey: 'condition',
          label: 'Condition',
          type: FieldType.choice,
          options: <Object>[
            <String, Object>{
              'label': 'Working',
              'aliases': <String>['working'],
            },
          ],
        ),
        FieldDef(fieldKey: 'count', label: 'Count', type: FieldType.number),
      ],
    );
    expect(outcome.candidates, isEmpty);
    expect(outcome.findings, hasLength(5));
  });

  test(
    'units booleans dates option aliases and leading zeros retain raw evidence',
    () {
      final OcrMappingOutcome outcome = map(
        'Capacity: 1000 mL\nWorking: Yes\nInspection date: 13/10/2026\nCondition: OK\nSerial: 00042',
        const <FieldDef>[
          FieldDef(
            fieldKey: 'capacity',
            label: 'Capacity',
            type: FieldType.decimal,
            unit: 'L',
          ),
          FieldDef(
            fieldKey: 'working',
            label: 'Working',
            type: FieldType.boolean,
          ),
          FieldDef(
            fieldKey: 'inspection_date',
            label: 'Inspection date',
            type: FieldType.date,
          ),
          FieldDef(
            fieldKey: 'condition',
            label: 'Condition',
            type: FieldType.choice,
            options: <Object>[
              <String, Object>{
                'label': 'Good',
                'code': 'GOOD',
                'aliases': <String>['OK'],
              },
            ],
          ),
          FieldDef(fieldKey: 'serial', label: 'Serial', type: FieldType.text),
        ],
      );
      expect(outcome.candidates.map((c) => c.value), <String>[
        '1000 mL',
        'Yes',
        '13/10/2026',
        'OK',
        '00042',
      ]);
      expect(outcome.candidates.map((c) => c.normalised), <String>[
        '1',
        'true',
        '2026-10-13',
        'GOOD',
        '00042',
      ]);
    },
  );

  test(
    'the longest field label wins while hidden and manual fields stay protected',
    () {
      final OcrMappingOutcome outcome =
          map('Rated voltage: 220 V\nOperator: Alice', const <FieldDef>[
            voltage,
            FieldDef(
              fieldKey: 'rated_voltage',
              label: 'Rated voltage',
              type: FieldType.decimal,
              unit: 'V',
            ),
            FieldDef(
              fieldKey: 'operator',
              label: 'Operator',
              type: FieldType.text,
              inputMode: InputMode.manualOnly,
            ),
          ]);
      // Explicitly shared labels remain ambiguous instead of inventing ownership.
      expect(outcome.candidates, isEmpty);
      expect(outcome.labelledKeys, <String>{
        'voltage',
        'rated_voltage',
        'operator',
      });
    },
  );

  test(
    'anchored identifier patterns match actual value tokens inside plate lines',
    () {
      final List<IdentifierCandidate> candidates = IdentifierExtraction.extract(
        text: 'ACME\nSerial: SN458923',
        blocks: const <PlateBlock>[
          (text: 'Serial: SN458923', top: 10, confidence: 0.91),
        ],
        fields: const <IdentityField>[
          (fieldKey: 'serial', pattern: r'^SN\d{6}$'),
        ],
      );
      expect(candidates.single.value, 'SN458923');
      expect(candidates.single.blockIndex, 0);
      expect(candidates.single.confidence, 0.91);
    },
  );

  test('selected fields are delimited by unselected and protected labels', () {
    final OcrMappingOutcome outcome = OcrFieldMapping.extract(
      text: 'Description: observed Voltage: 220 V Operator: Alice',
      blocks: const <OcrParameterBlock>[],
      profile: profile(const <FieldDef>[
        FieldDef(
          fieldKey: 'description',
          label: 'Description',
          type: FieldType.text,
        ),
        voltage,
        FieldDef(
          fieldKey: 'operator',
          label: 'Operator',
          type: FieldType.text,
          inputMode: InputMode.manualOnly,
        ),
      ]),
      targetKeys: const <String>{'description'},
    );
    expect(outcome.candidates.single.value, 'observed');
    expect(outcome.candidates.single.fieldKey, 'description');
    expect(outcome.findings, isEmpty);
  });

  test('selection cannot make a shared alias falsely unique', () {
    final OcrMappingOutcome outcome = OcrFieldMapping.extract(
      text: 'Reading: 10',
      blocks: const <OcrParameterBlock>[],
      profile: profile(const <FieldDef>[
        FieldDef(fieldKey: 'inlet', label: 'Reading', type: FieldType.decimal),
        FieldDef(fieldKey: 'outlet', label: 'Reading', type: FieldType.decimal),
      ]),
      targetKeys: const <String>{'inlet'},
    );
    expect(outcome.candidates, isEmpty);
    expect(outcome.findings.single, contains('inlet is ambiguous'));
  });

  test(
    'exact template units support negative decimals and unfamiliar unit families',
    () {
      final OcrMappingOutcome outcome = map(
        'Frequency: 50Hz\nPressure:-12.5 mm Hg\nPower: 1.2 kW\nArea: 20 m²\nRate: 50%',
        const <FieldDef>[
          FieldDef(
            fieldKey: 'frequency',
            label: 'Frequency',
            type: FieldType.decimal,
            unit: 'Hz',
          ),
          FieldDef(
            fieldKey: 'pressure',
            label: 'Pressure',
            type: FieldType.decimal,
            unit: 'mmHg',
          ),
          FieldDef(
            fieldKey: 'power',
            label: 'Power',
            type: FieldType.decimal,
            unit: 'kW',
          ),
          FieldDef(
            fieldKey: 'area',
            label: 'Area',
            type: FieldType.decimal,
            unit: 'm²',
          ),
          FieldDef(fieldKey: 'rate', label: 'Rate', type: FieldType.percentage),
        ],
      );
      expect(outcome.candidates.map((c) => c.normalised), <String>[
        '50',
        '-12.5',
        '1.2',
        '20',
        '50',
      ]);
      expect(outcome.findings, isEmpty);
    },
  );

  test(
    'unsupported unit conversions and out of range readings require review',
    () {
      final OcrMappingOutcome outcome = map(
        'Frequency: 50 MHz\nCount: -1',
        const <FieldDef>[
          FieldDef(
            fieldKey: 'frequency',
            label: 'Frequency',
            type: FieldType.decimal,
            unit: 'Hz',
          ),
          FieldDef(
            fieldKey: 'count',
            label: 'Count',
            type: FieldType.number,
            validation: <String, Object?>{'min': 0},
          ),
        ],
      );
      expect(outcome.candidates, isEmpty);
      expect(outcome.findings, hasLength(2));
    },
  );

  test('field labels inside photographed values remain ordinary evidence', () {
    final OcrMappingOutcome outcome = map(
      'Manufacturer: Model Systems\nDescription: Name and Condition are printed on the door',
      const <FieldDef>[
        FieldDef(
          fieldKey: 'manufacturer_name',
          label: 'Manufacturer name',
          type: FieldType.text,
        ),
        model,
        FieldDef(
          fieldKey: 'description',
          label: 'Description',
          type: FieldType.text,
        ),
        FieldDef(fieldKey: 'name', label: 'Name', type: FieldType.text),
        FieldDef(
          fieldKey: 'condition',
          label: 'Condition',
          type: FieldType.text,
        ),
      ],
    );
    expect(
      <String, String>{for (final c in outcome.candidates) c.fieldKey: c.value},
      <String, String>{
        'manufacturer_name': 'Model Systems',
        'description': 'Name and Condition are printed on the door',
      },
    );
    expect(outcome.findings, isEmpty);
  });

  test(
    'invalid timestamp components never roll over into invented instants',
    () {
      for (final String stamp in <String>[
        '2026-01-01T25:30:00',
        '2026-01-01T12:61:00',
        '2026-01-01T12:30:61',
        '2026-02-31T12:30:00',
        '2026-01-01T12:30:00+25:00',
      ]) {
        final OcrMappingOutcome outcome =
            map('Captured at: $stamp', const <FieldDef>[
              FieldDef(
                fieldKey: 'captured_at',
                label: 'Captured at',
                type: FieldType.dateTime,
              ),
            ]);
        expect(outcome.candidates, isEmpty, reason: stamp);
        expect(outcome.findings, hasLength(1), reason: stamp);
      }
    },
  );
  test(
    'overlapping identity patterns cannot assign an unlabelled value twice',
    () {
      final outcome = IdentifierOwnership.resolve(
        IdentifierExtraction.extract(
          text: 'AB123',
          blocks: const <PlateBlock>[],
          fields: const <IdentityField>[
            (fieldKey: 'serial', pattern: r'^[A-Z0-9]+$'),
            (fieldKey: 'model', pattern: r'^[A-Z0-9]+$'),
          ],
        ),
      );
      expect(outcome.candidates, isEmpty);
      expect(outcome.ambiguousKeys, <String>{'serial', 'model'});
    },
  );

  test(
    'unrelated distant text cannot take ownership of a nearer value below',
    () {
      final OcrMappingOutcome outcome = map(
        'Name\nPump\nModel1',
        const <FieldDef>[
          FieldDef(fieldKey: 'name', label: 'Name', type: FieldType.text),
        ],
        blocks: const <OcrParameterBlock>[
          (
            text: 'Name',
            left: 0,
            top: 0,
            right: 100,
            bottom: 10,
            confidence: 0.9,
          ),
          (
            text: 'Pump',
            left: 0,
            top: 15,
            right: 100,
            bottom: 25,
            confidence: 0.9,
          ),
          (
            text: 'Model1',
            left: 500,
            top: 0,
            right: 600,
            bottom: 10,
            confidence: 0.9,
          ),
        ],
      );
      expect(outcome.candidates.single.value, 'Pump');
      expect(outcome.candidates.single.blockIndex, 1);
    },
  );
}
