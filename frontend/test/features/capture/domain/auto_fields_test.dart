import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/location/location_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/domain/auto_fields.dart';
import 'package:tapture/features/templates/domain/field_def.dart';

/// The instant the frozen clock reports for every test here.
final DateTime _frozen = DateTime.utc(2026, 9, 28, 12, 5, 9);

String _two(int value) => value.toString().padLeft(2, '0');

FieldDef _field(String key, AutoFill? autoFill, {String? defaultValue}) {
  return FieldDef(
    fieldKey: key,
    label: key,
    type: FieldType.text,
    autoFill: autoFill,
    defaultValue: defaultValue,
  );
}

/// One field per [AutoFill] value, keyed by the value's name.
final List<FieldDef> _everyAutoFill = <FieldDef>[
  for (final AutoFill fill in AutoFill.values) _field(fill.name, fill),
];

final GeoFix _fix = GeoFix(
  latitude: 0.3476,
  longitude: 32.5825,
  accuracyMetres: 8,
  capturedAt: DateTime.utc(2026, 9, 28, 12, 4),
);

Map<String, Object?> _values({
  Iterable<FieldDef>? fields,
  bool autoFillDates = true,
  GeoFix? location,
  Map<String, String> context = const <String, String>{},
  String? localAddress,
}) {
  return AutoFields.forTemplate(
    fields: fields ?? _everyAutoFill,
    nowUtc: _frozen,
    operatorName: 'Ada',
    deviceId: 'device-7',
    sequence: 12,
    context: context,
    location: location,
    autoFillDates: autoFillDates,
    localAddress: localAddress,
  );
}

void main() {
  test(
    'local address uses only the completed sample and suppresses default refill',
    () {
      const FieldDef address = FieldDef(
        fieldKey: 'address',
        label: 'Address',
        type: FieldType.text,
        autoFill: AutoFill.localAddress,
        defaultValue: 'invented',
      );
      Map<String, Object?> values(String? sample) => AutoFields.forTemplate(
        fields: const <FieldDef>[address],
        nowUtc: _frozen,
        operatorName: 'Ada',
        deviceId: 'app-id',
        sequence: null,
        context: const <String, String>{},
        location: null,
        localAddress: sample,
      );
      expect(values(null), isEmpty);
      expect(values('10.0.0.2'), <String, Object?>{'address': '10.0.0.2'});
    },
  );

  test(
    'opaque sources and malformed address types suppress every inherited and default fallback',
    () {
      const List<FieldDef> fields = <FieldDef>[
        FieldDef(
          fieldKey: 'captured_date',
          label: 'Date',
          type: FieldType.date,
          group: 'record_admin',
          inputMode: InputMode.auto,
          defaultValue: 'invented',
          validation: <String, Object?>{
            '_tapture': <String, Object?>{'autoFill': 'UNKNOWN'},
          },
        ),
        FieldDef(
          fieldKey: 'captured_time',
          label: 'Time',
          type: FieldType.time,
          group: 'record_admin',
          inputMode: InputMode.auto,
          validation: <String, Object?>{
            '_tapture': <String, Object?>{'autoFill': 17},
          },
        ),
        FieldDef(
          fieldKey: 'device_id',
          label: 'Device',
          type: FieldType.text,
          group: 'record_admin',
          inputMode: InputMode.auto,
          validation: <String, Object?>{
            '_tapture': <String, Object?>{'autoFill': 'UNKNOWN'},
          },
        ),
        FieldDef(
          fieldKey: 'bad_address',
          label: 'Address',
          type: FieldType.number,
          autoFill: AutoFill.localAddress,
          defaultValue: 'invented',
        ),
        FieldDef(
          fieldKey: 'valid_date',
          label: 'Valid date',
          type: FieldType.date,
          autoFill: AutoFill.today,
        ),
      ];
      for (final FieldDef field in fields.take(4)) {
        expect(
          AutoFields.effectiveSource(field),
          isNull,
          reason: field.fieldKey,
        );
      }
      final Map<String, Object?> values = AutoFields.forTemplate(
        fields: fields,
        nowUtc: _frozen,
        operatorName: 'Ada',
        deviceId: 'app-id',
        sequence: null,
        context: const <String, String>{},
        location: null,
        localAddress: '10.0.0.2',
      );
      expect(values.keys, <String>['valid_date']);
      expect(fields.first.validation['_tapture'], <String, Object?>{
        'autoFill': 'UNKNOWN',
      });
    },
  );

  group('automatic previews', () {
    test(
      'fixed source inputs preview values while sequence remains pending',
      () {
        final FixedClock clock = FixedClock(_frozen);
        const Map<String, String> context = <String, String>{
          'context': 'Kampala',
        };
        final Map<String, Object?> preview = AutoFields.forTemplate(
          fields: _everyAutoFill,
          nowUtc: clock.nowUtc(),
          operatorName: 'Preview operator',
          deviceId: 'app-device-id',
          sequence: null,
          context: context,
          location: _fix,
        );
        final DateTime local = clock.nowUtc().toLocal();

        expect(preview['now'], clock.nowUtc().toIso8601String());
        expect(
          preview['today'],
          '${local.year}-${_two(local.month)}-${_two(local.day)}',
        );
        expect(
          preview['time'],
          '${_two(local.hour)}:${_two(local.minute)}:${_two(local.second)}',
        );
        expect(preview['operator'], 'Preview operator');
        expect(preview['device'], 'app-device-id');
        expect(preview['context'], 'Kampala');
        expect(preview['gps'], <String, Object?>{
          'latitude': _fix.latitude,
          'longitude': _fix.longitude,
          'accuracy': _fix.accuracyMetres,
        });
        expect(preview, isNot(contains('sequence')));
        expect(context, const <String, String>{'context': 'Kampala'});
        expect(_everyAutoFill.every((field) => field.autoFill != null), isTrue);
      },
    );

    test('date filling off leaves clock and sequence previews unavailable', () {
      final FixedClock clock = FixedClock(_frozen);
      final Map<String, Object?> preview = AutoFields.forTemplate(
        fields: _everyAutoFill,
        nowUtc: clock.nowUtc(),
        operatorName: 'Preview operator',
        deviceId: 'app-device-id',
        sequence: null,
        context: const <String, String>{'context': 'Kampala'},
        location: null,
        autoFillDates: false,
      );

      expect(preview, const <String, Object?>{
        'operator': 'Preview operator',
        'device': 'app-device-id',
        'context': 'Kampala',
      });
      expect(
        AutoFields.forTemplate(
          fields: <FieldDef>[
            _field('pending_number', AutoFill.sequence, defaultValue: '99'),
          ],
          nowUtc: clock.nowUtc(),
          operatorName: 'Preview operator',
          deviceId: 'app-device-id',
          sequence: null,
          context: const <String, String>{},
          location: null,
        ),
        isEmpty,
        reason: 'An unallocated sequence cannot borrow a declared default.',
      );
    });
  });

  group('inherited capture metadata', () {
    const Map<String, AutoFill> bindings = <String, AutoFill>{
      'captured_date': AutoFill.today,
      'captured_time': AutoFill.time,
      'device_id': AutoFill.device,
    };
    FieldDef inherited(
      String key, {
      String? group = 'record_admin',
      InputMode mode = InputMode.auto,
      AutoFill? source,
      String? defaultValue,
    }) => FieldDef(
      fieldKey: key,
      label: 'User label',
      type: FieldType.text,
      group: group,
      inputMode: mode,
      autoFill: source,
      defaultValue: defaultValue,
    );

    for (final MapEntry<String, AutoFill> binding in bindings.entries) {
      test('${binding.key} resolves its source without changing the field', () {
        final FieldDef field = inherited(binding.key);
        expect(AutoFields.effectiveSource(field), binding.value);
        expect(field.autoFill, isNull);
        expect(field.defaultValue, isNull);
      });
      test('${binding.key} keeps an explicit source ahead of fallback', () {
        final FieldDef field = inherited(
          binding.key,
          source: AutoFill.context,
          defaultValue: 'Declared default',
        );
        expect(AutoFields.effectiveSource(field), AutoFill.context);
        expect(
          _values(
            fields: <FieldDef>[field],
            context: <String, String>{binding.key: 'Declared context'},
          )[binding.key],
          'Declared context',
        );
      });
      test('${binding.key} keeps a declared default instead of fallback', () {
        final FieldDef field = inherited(
          binding.key,
          defaultValue: 'Declared default',
        );
        expect(AutoFields.effectiveSource(field), isNull);
        expect(
          _values(fields: <FieldDef>[field])[binding.key],
          'Declared default',
        );
      });
      test('${binding.key} requires the exact group and automatic mode', () {
        for (final String? group in <String?>[null, 'other', 'RECORD_ADMIN']) {
          expect(
            AutoFields.effectiveSource(inherited(binding.key, group: group)),
            isNull,
          );
        }
        for (final InputMode mode in InputMode.values) {
          if (mode == InputMode.auto) continue;
          expect(
            AutoFields.effectiveSource(inherited(binding.key, mode: mode)),
            isNull,
          );
        }
      });
    }

    test('other source-less administrative keys remain unavailable', () {
      final List<FieldDef> fields = <FieldDef>[
        for (final String key in <String>[
          'record_uid',
          'record_number',
          'template_key',
          'captured_by_name',
          'created_at',
          'date',
          'time',
          'device',
        ])
          inherited(key),
      ];
      for (final FieldDef field in fields) {
        expect(
          AutoFields.effectiveSource(field),
          isNull,
          reason: field.fieldKey,
        );
      }
      expect(_values(fields: fields), isEmpty);
    });

    test(
      'disabled date filling leaves inherited dates and times unavailable',
      () {
        final List<FieldDef> fields = <FieldDef>[
          for (final String key in bindings.keys) inherited(key),
        ];
        expect(_values(fields: fields, autoFillDates: false), <String, Object?>{
          'device_id': 'device-7',
        });
      },
    );

    test('a declared empty default is preserved', () {
      final FieldDef field = inherited('captured_date', defaultValue: '');
      expect(AutoFields.effectiveSource(field), isNull);
      expect(_values(fields: <FieldDef>[field]), <String, Object?>{
        'captured_date': '',
      });
    });
  });

  group('with a frozen clock', () {
    test('a record captured with no typing carries a complete timestamp, '
        'operator and device', () {
      final Map<String, Object?> values = _values();
      final DateTime local = _frozen.toLocal();

      expect(values['now'], '2026-09-28T12:05:09.000Z');
      expect(
        values['today'],
        '${local.year}-${_two(local.month)}-${_two(local.day)}',
      );
      expect(
        values['time'],
        '${_two(local.hour)}:${_two(local.minute)}:${_two(local.second)}',
      );
      expect(values['operator'], 'Ada');
      expect(values['device'], 'device-7');
      expect(values['sequence'], 12);
    });

    test('captured-at is written in UTC whatever the device zone', () {
      expect(_values()['now'], endsWith('Z'));
    });
  });

  group('every autoFill value', () {
    test('context fills from the snapshot and is absent without it', () {
      expect(
        _values(
          context: const <String, String>{'context': 'Theatre'},
        )['context'],
        'Theatre',
      );
      expect(_values().containsKey('context'), isFalse);
    });

    test('gps fills from a fix and adds the fix columns', () {
      final Map<String, Object?> values = _values(location: _fix);
      expect(values['gps'], <String, Object?>{
        'latitude': 0.3476,
        'longitude': 32.5825,
        'accuracy': 8.0,
      });
      expect(values['gps_latitude'], 0.3476);
      expect(values['gps_longitude'], 32.5825);
      expect(values['gps_accuracy_m'], 8.0);
      expect(values['gps_captured_at'], '2026-09-28T12:04:00.000Z');
    });

    test('gps without a fix writes nothing', () {
      final Map<String, Object?> values = _values();
      expect(values.containsKey('gps'), isFalse);
      expect(values.containsKey('gps_latitude'), isFalse);
    });

    test('a field with no autoFill takes its declared default', () {
      final Map<String, Object?> values = _values(
        fields: <FieldDef>[
          _field('status', null, defaultValue: 'working'),
          _field('note', null),
        ],
      );
      expect(values, <String, Object?>{'status': 'working'});
    });

    test('each value is produced only by the field that asks for it', () {
      for (final AutoFill fill in AutoFill.values) {
        final Map<String, Object?> values = _values(
          fields: <FieldDef>[_field('only', fill)],
          location: _fix,
          context: const <String, String>{'only': 'Kampala'},
          localAddress: '10.0.0.2',
        );
        expect(values.containsKey('only'), isTrue, reason: fill.name);
        expect(
          values.keys.where((String key) => !key.startsWith('gps_')),
          <String>['only'],
          reason: fill.name,
        );
      }
    });
  });

  group('autoFillDates', () {
    test('off leaves every date and time field empty and keeps the rest', () {
      final Map<String, Object?> values = _values(autoFillDates: false);
      for (final String key in <String>['now', 'today', 'time']) {
        expect(values.containsKey(key), isFalse, reason: key);
      }
      expect(values['operator'], 'Ada');
      expect(values['device'], 'device-7');
      expect(values['sequence'], 12);
    });

    test('on fills every date and time field', () {
      final Map<String, Object?> values = _values();
      for (final String key in <String>['now', 'today', 'time']) {
        expect(values[key], isA<String>(), reason: key);
      }
    });
  });
}
