import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/time/clock.dart';

void main() {
  test('FixedClock freezes now, today and the offset exactly', () {
    final Clock clock = FixedClock(DateTime.utc(2026, 9, 17, 8, 15, 30));

    expect(clock.nowUtc(), DateTime.utc(2026, 9, 17, 8, 15, 30));
    expect(clock.today(), DateTime.utc(2026, 9, 17));
    expect(clock.offset, Duration.zero);
  });

  test('FixedClock today follows the device offset across midnight', () {
    final Clock clock = FixedClock(
      DateTime.utc(2026, 9, 17, 22),
      offset: const Duration(hours: 3),
    );

    expect(clock.nowUtc(), DateTime.utc(2026, 9, 17, 22));
    expect(clock.today(), DateTime.utc(2026, 9, 18));
    expect(clock.offset, const Duration(hours: 3));
  });

  test('SystemClock reports the platform instant and zone', () {
    const SystemClock clock = SystemClock();
    final DateTime before = DateTime.now().toUtc();
    final DateTime now = clock.nowUtc();
    final DateTime after = DateTime.now().toUtc();

    expect(now.isUtc, isTrue);
    expect(!now.isBefore(before) && !now.isAfter(after), isTrue);
    expect(clock.offset, DateTime.now().timeZoneOffset);
    expect(clock.today(), isA<DateTime>());
    expect(clock.today().isUtc, isTrue);
  });
}
