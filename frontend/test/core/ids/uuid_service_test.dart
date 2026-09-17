import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

final RegExp _uuidV7 = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  test('identifiers generated in order sort in order as strings', () {
    final Clock clock = FixedClock(DateTime.utc(2026, 9, 17, 8));
    final IdService ids = UuidV7Service.sequence(clock);
    const int count = 10000;
    final List<String> minted = <String>[
      for (int index = 0; index < count; index++) ids.newId(),
    ];

    expect(minted.toSet(), hasLength(count));
    expect(List<String>.from(minted)..sort(), minted);
    expect(minted.every(_uuidV7.hasMatch), isTrue);
  });

  test('a later clock instant sorts after an earlier one', () {
    final IdService earlier = UuidV7Service.sequence(
      FixedClock(DateTime.utc(2026, 1, 1)),
    );
    final IdService later = UuidV7Service.sequence(
      FixedClock(DateTime.utc(2026, 1, 2)),
    );

    expect(earlier.newId().compareTo(later.newId()), lessThan(0));
  });

  test('the timestamp half comes from the clock, not the wall clock', () {
    final Clock clock = FixedClock(DateTime.utc(2020, 1, 1));
    final String id = UuidV7Service.sequence(clock).newId();
    final int ms = DateTime.utc(2020, 1, 1).millisecondsSinceEpoch;
    final String prefix = (ms >> 16).toRadixString(16).padLeft(8, '0');

    expect(id.startsWith(prefix), isTrue);
  });
}
