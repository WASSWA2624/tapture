import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/templates/domain/domain.dart';

void main() {
  const Set<FieldType> evidenceTypes = <FieldType>{
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
  };
  const Map<InputMode, Set<FieldType>> permitted = <InputMode, Set<FieldType>>{
    InputMode.any: evidenceTypes,
    InputMode.aiAllowed: evidenceTypes,
    InputMode.manualOnly: <FieldType>{},
    InputMode.auto: <FieldType>{},
  };

  for (final InputMode mode in InputMode.values) {
    test(
      '${mode.name} extraction follows its complete field-type contract',
      () {
        for (final FieldType type in FieldType.values) {
          expect(
            FieldInputPolicy.canExtract(_field(type: type, mode: mode)),
            permitted[mode]!.contains(type),
            reason: '${mode.name}/${type.name}',
          );
        }
      },
    );
  }

  for (final InputMode mode in <InputMode>[
    InputMode.any,
    InputMode.aiAllowed,
  ]) {
    test('${mode.name} never extracts an explicitly automatic source', () {
      for (final AutoFill source in AutoFill.values) {
        expect(
          FieldInputPolicy.canExtract(_field(mode: mode, source: source)),
          isFalse,
          reason: source.name,
        );
      }
    });

    test('${mode.name} preserves hidden and hierarchy-bound fields', () {
      expect(
        FieldInputPolicy.canExtract(_field(mode: mode, hidden: true)),
        isFalse,
      );
      for (final int level in <int>[0, 1, 3]) {
        expect(
          FieldInputPolicy.canExtract(_field(mode: mode, contextLevel: level)),
          isFalse,
          reason: 'A declared level is protected, including invalid legacy 0.',
        );
      }
    });

    test('${mode.name} permits an ordinary stickable unbound field', () {
      expect(
        FieldInputPolicy.canExtract(_field(mode: mode, stickable: true)),
        isTrue,
      );
    });

    test('${mode.name} protects every opaque stored source payload', () {
      for (final Object payload in <Object>[
        '',
        'FUTURE_SOURCE',
        'LOCAL_ADDRESS',
        true,
        false,
        42,
        <Object?>['future'],
        <String, Object?>{'future': true},
      ]) {
        expect(
          FieldInputPolicy.canExtract(
            _field(
              mode: mode,
              validation: <String, Object?>{
                '_tapture': <String, Object?>{'autoFill': payload},
              },
            ),
          ),
          isFalse,
          reason: '$payload remains configured even without a typed source.',
        );
      }
    });

    test('${mode.name} keeps absent and null source metadata eligible', () {
      for (final Map<String, Object?> metadata in <Map<String, Object?>>[
        <String, Object?>{'group': 'business'},
        <String, Object?>{'autoFill': null},
      ]) {
        expect(
          FieldInputPolicy.canExtract(
            _field(
              mode: mode,
              validation: <String, Object?>{'_tapture': metadata},
            ),
          ),
          isTrue,
        );
      }
    });
  }

  test(
    'requiredness and a business default do not grant source permission',
    () {
      expect(
        FieldInputPolicy.canExtract(
          _field(
            requiredness: Requiredness.required,
            defaultValue: 'Unspecified',
          ),
        ),
        isTrue,
      );
      for (final InputMode mode in <InputMode>[
        InputMode.manualOnly,
        InputMode.auto,
      ]) {
        expect(
          FieldInputPolicy.canExtract(
            _field(mode: mode, requiredness: Requiredness.required),
          ),
          isFalse,
        );
      }
    },
  );

  group('audited correction permission', () {
    for (final InputMode mode in InputMode.values) {
      test(
        '${mode.name} permits visible business and capture date/time edits',
        () {
          for (final FieldType type in FieldType.values) {
            expect(
              FieldInputPolicy.canCorrect(_field(type: type, mode: mode)),
              type != FieldType.computed && type != FieldType.gpsLocation,
              reason: '${mode.name}/${type.name}',
            );
          }
          for (final String key in <String>['captured_date', 'captured_time']) {
            expect(
              FieldInputPolicy.canCorrect(_field(key: key, mode: mode)),
              isTrue,
            );
          }
        },
      );
    }

    test('reserved metadata remains immutable regardless of mode or label', () {
      const List<String> reserved = <String>[
        'record_uid',
        'record_number',
        'template_key',
        'template_version',
        'captured_by_user_id',
        'captured_by_name',
        'device_id',
        'created_at',
        'updated_at',
        'updated_by_user_id',
        'record_status',
        'sync_state',
      ];
      for (final String key in reserved) {
        for (final InputMode mode in InputMode.values) {
          for (final String spelling in <String>[key, key.toUpperCase()]) {
            expect(
              FieldInputPolicy.canCorrect(_field(key: spelling, mode: mode)),
              isFalse,
              reason: '$spelling/${mode.name}',
            );
          }
        }
      }
    });

    test(
      'GPS evidence has a removal workflow rather than manual correction',
      () {
        for (final String key in <String>[
          'gps_latitude',
          'gps_longitude',
          'gps_accuracy_m',
          'gps_captured_at',
          'gpsLat',
          'latitude',
          'longitude',
        ]) {
          expect(FieldInputPolicy.canCorrect(_field(key: key)), isFalse);
        }
        expect(
          FieldInputPolicy.canCorrect(_field(source: AutoFill.gps)),
          isFalse,
        );
        expect(
          FieldInputPolicy.canCorrect(
            _field(
              validation: <String, Object?>{
                '_tapture': <String, Object?>{'autoFill': 'GPS'},
              },
            ),
          ),
          isFalse,
        );
      },
    );

    test(
      'hidden definitions cannot become editable through automatic filling',
      () {
        for (final AutoFill source in AutoFill.values) {
          expect(
            FieldInputPolicy.canCorrect(_field(hidden: true, source: source)),
            isFalse,
            reason: source.name,
          );
        }
        expect(
          FieldInputPolicy.canCorrect(_field(source: AutoFill.operator)),
          isTrue,
        );
        expect(
          FieldInputPolicy.canCorrect(_field(source: AutoFill.context)),
          isTrue,
        );
      },
    );
  });
}

FieldDef _field({
  String key = 'business_value',
  FieldType type = FieldType.text,
  InputMode mode = InputMode.any,
  AutoFill? source,
  int? contextLevel,
  bool hidden = false,
  bool stickable = false,
  Requiredness requiredness = Requiredness.optional,
  String? defaultValue,
  Map<String, Object?> validation = const <String, Object?>{},
}) => FieldDef(
  fieldKey: key,
  label: 'Business value',
  type: type,
  inputMode: mode,
  autoFill: source,
  contextLevel: contextLevel,
  hidden: hidden,
  stickable: stickable,
  requiredness: requiredness,
  defaultValue: defaultValue,
  validation: validation,
);
