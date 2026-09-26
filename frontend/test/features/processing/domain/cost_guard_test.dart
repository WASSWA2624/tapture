import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/cost_guard.dart';

void main() {
  final DateTime now = DateTime.utc(2026, 9, 26, 14, 30);

  CostGuard guard(int requests) {
    return CostGuard(
      requestsToday: requests,
      imagesToday: requests * 3,
      requestCap: 5,
      now: now,
    );
  }

  test('below the cap online work may start', () {
    expect(guard(0).isBlocked, isFalse);
    expect(guard(4).isBlocked, isFalse);
  });

  test('at and above the cap online work is blocked', () {
    expect(guard(5).isBlocked, isTrue);
    expect(guard(6).isBlocked, isTrue);
  });

  test('each request counts one call and its images', () {
    final CostGuard after = guard(4).record(images: 2);
    expect(after.requestsToday, 5);
    expect(after.imagesToday, 14);
    expect(after.isBlocked, isTrue);
  });

  test('the block message names the cap and when it resets', () {
    final CostGuard blocked = guard(5);
    expect(blocked.resetsAt, DateTime.utc(2026, 9, 27));
    expect(blocked.blockMessage, contains('5'));
    expect(blocked.blockMessage, contains('2026-09-27'));
    expect(blocked.blockMessage, contains('00:00 UTC'));
  });
}
