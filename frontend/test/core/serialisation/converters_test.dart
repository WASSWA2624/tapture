import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/serialisation/converters.dart';

void main() {
  test('date-times round-trip as UTC regardless of the device offset', () {
    const UtcDateTimeConverter converter = Converters.utcDateTime;
    final DateTime local = DateTime(2026, 9, 17, 12, 30);

    final String json = converter.toJson(local);
    final DateTime decoded = converter.fromJson(json);

    expect(decoded.isUtc, isTrue);
    expect(decoded, local.toUtc());
    expect(converter.fromJson('2026-09-17T09:30:00.000Z').isUtc, isTrue);
    expect(
      converter.toJson(DateTime.utc(2026, 9, 17, 9, 30)),
      '2026-09-17T09:30:00.000Z',
    );
  });

  test('a JSON map round-trips and null becomes empty', () {
    const JsonMapConverter converter = Converters.jsonMap;
    const Map<String, Object?> payload = <String, Object?>{
      'label': 'pump',
      'count': 2,
      'note': null,
    };

    expect(converter.fromJson(payload), payload);
    expect(converter.toJson(payload), payload);
    expect(converter.fromJson(null), isEmpty);
    expect(
      () => converter.fromJson(<Object>['not-a-map']),
      throwsA(isA<FormatException>()),
    );
  });

  test('enum wire names are explicit and an unknown name fails loudly', () {
    const EnumWireConverter<_Switch> converter = EnumWireConverter<_Switch>({
      _Switch.on: 'enabled',
      _Switch.off: 'disabled',
    });

    expect(converter.toJson(_Switch.on), 'enabled');
    expect(converter.toJson(_Switch.on), isNot(_Switch.on.name));
    expect(converter.fromJson('disabled'), _Switch.off);
    expect(() => converter.fromJson('on'), throwsA(isA<FormatException>()));
    expect(
      () => converter.fromJson('unknown'),
      throwsA(isA<FormatException>()),
    );
  });
}

enum _Switch { on, off }
