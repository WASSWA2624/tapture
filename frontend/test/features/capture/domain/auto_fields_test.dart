import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/capture/domain/auto_fields.dart';

/// The instant the frozen clock reports for every test here.
final DateTime _frozen = DateTime.utc(2026, 9, 28, 12, 0, 0);

/// The keys a record gets without being asked, in the order they are put.
const List<String> _keys = <String>[
  'capturedAt',
  'date',
  'time',
  'operator',
  'device',
];

String _two(int value) => value.toString().padLeft(2, '0');

Map<String, Object?> _build({
  Map<String, bool> autoFill = const <String, bool>{},
  String dateFormat = 'yyyy-MM-dd',
  double? lat,
  double? lon,
}) {
  return AutoFields.build(
    nowUtc: _frozen,
    operatorId: 'ada',
    deviceId: 'device-7',
    autoFill: autoFill,
    dateFormat: dateFormat,
    gpsLat: lat,
    gpsLon: lon,
  );
}

void main() {
  group('with a frozen clock', () {
    test('a record captured with no typing carries a complete timestamp, '
        'operator and device', () {
      final Map<String, Object?> values = _build();
      final DateTime local = _frozen.toLocal();

      expect(values['capturedAt'], '2026-09-28T12:00:00.000Z');
      expect(
        values['date'],
        '${local.year}-${_two(local.month)}-${_two(local.day)}',
      );
      expect(
        values['time'],
        '${_two(local.hour)}:${_two(local.minute)}:${_two(local.second)}',
      );
      expect(values['operator'], 'ada');
      expect(values['device'], 'device-7');
      expect(values.keys, unorderedEquals(_keys));
    });

    test('captured-at is written in UTC whatever the device zone', () {
      expect(_build()['capturedAt'], endsWith('Z'));
    });

    test('the project date format is honoured', () {
      final DateTime local = _frozen.toLocal();

      expect(
        _build(dateFormat: 'dd/MM/yyyy')['date'],
        '${_two(local.day)}/${_two(local.month)}/${local.year}',
      );
      expect(
        _build(dateFormat: 'MM-dd')['date'],
        '${_two(local.month)}-${_two(local.day)}',
      );
    });

    test('a single-digit month, day, hour and minute are zero padded', () {
      final Map<String, Object?> values = AutoFields.build(
        nowUtc: DateTime.utc(2026, 1, 2, 3, 4, 5),
        operatorId: 'ada',
        deviceId: 'device-7',
        autoFill: const <String, bool>{},
      );

      expect(values['date'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      expect(values['time'], matches(RegExp(r'^\d{2}:\d{2}:\d{2}$')));
    });

    test('coordinates are written only when a whole fix is given', () {
      expect(_build(lat: 1.5).containsKey('gpsLat'), isFalse);
      expect(_build(lon: 2.5).containsKey('gpsLon'), isFalse);

      final Map<String, Object?> withFix = _build(lat: 1.5, lon: 2.5);
      expect(withFix['gpsLat'], 1.5);
      expect(withFix['gpsLon'], 2.5);
    });
  });

  group('autoFill', () {
    for (var mask = 0; mask < 1 << _keys.length; mask++) {
      final List<String> enabled = <String>[
        for (var i = 0; i < _keys.length; i++)
          if (mask & (1 << i) != 0) _keys[i],
      ];
      final List<String> disabled = <String>[
        for (final String key in _keys)
          if (!enabled.contains(key)) key,
      ];
      test('with ${disabled.isEmpty ? 'nothing' : disabled.join(', ')} off it '
          'writes ${enabled.isEmpty ? 'nothing' : enabled.join(', ')}', () {
        final Map<String, Object?> values = _build(
          autoFill: <String, bool>{
            for (final String key in _keys) key: enabled.contains(key),
          },
        );

        expect(values.keys, unorderedEquals(enabled));
      });
    }

    test('a key the template does not mention is filled', () {
      final Map<String, Object?> values = _build(
        autoFill: const <String, bool>{'serial': false},
      );

      expect(values.keys, unorderedEquals(_keys));
    });

    test('each coordinate honours its own flag', () {
      final Map<String, Object?> values = _build(
        autoFill: const <String, bool>{'gpsLat': false},
        lat: 1.5,
        lon: 2.5,
      );

      expect(values.containsKey('gpsLat'), isFalse);
      expect(values['gpsLon'], 2.5);
    });
  });
}
