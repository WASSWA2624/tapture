import 'dart:math';

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
    final String prefix = (ms ~/ 0x10000).toRadixString(16).padLeft(8, '0');

    expect(id.startsWith(prefix), isTrue);
  });

  // The web compiles ints to JS numbers, whose bitwise operators keep only 32
  // bits. These exact values fail there if a timestamp byte above bit 32 or a
  // tail with bit 31 set is built with `&` or `>>` on the full value.
  test('encodes the timestamp and tail bytes exactly', () {
    final Clock clock = FixedClock(DateTime.utc(2026, 9, 17, 8));
    final IdService sequence = UuidV7Service.sequence(clock);
    final IdService random = UuidV7Service(
      clock,
      random: _FixedRandom(0x7ffffffe),
    );

    expect(sequence.newId(), '01a0ae61-3000-7000-8000-000000000000');
    expect(sequence.newId(), '01a0ae61-3000-7000-8000-000000000001');
    expect(random.newId(), '01a0ae61-3000-7000-8000-00007ffffffe');
    expect(random.newId(), '01a0ae61-3000-7000-8000-00007fffffff');
    expect(random.newId(), '01a0ae61-3000-7000-8000-000080000000');
  });
}

/// A [Random] whose every draw is [value].
final class _FixedRandom implements Random {
  _FixedRandom(this.value);

  final int value;

  @override
  int nextInt(int max) => value;

  @override
  double nextDouble() => throw UnimplementedError();

  @override
  bool nextBool() => throw UnimplementedError();
}
