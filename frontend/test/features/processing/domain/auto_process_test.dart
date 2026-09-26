import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/network/connectivity_service.dart';
import 'package:tapture/features/processing/domain/auto_process.dart';

void main() {
  bool start({
    bool enabled = true,
    bool wifiOnly = true,
    NetworkState? previous = NetworkState.offline,
    NetworkState next = NetworkState.online,
    bool foreground = false,
    bool underCap = true,
  }) {
    return AutoProcess.shouldStart(
      enabled: enabled,
      wifiOnly: wifiOnly,
      previous: previous,
      next: next,
      foreground: foreground,
      underCap: underCap,
    );
  }

  test('a connection gain in the background starts processing', () {
    expect(start(), isTrue);
  });

  test('off by default means never', () {
    expect(start(enabled: false), isFalse);
  });

  test('the metered restriction refuses a metered gain', () {
    expect(start(next: NetworkState.metered), isFalse);
    expect(start(next: NetworkState.metered, wifiOnly: false), isTrue);
  });

  test('moving from metered to Wi-Fi counts as a gain under Wi-Fi only', () {
    expect(
      start(previous: NetworkState.metered, next: NetworkState.online),
      isTrue,
    );
  });

  test('the cap holds it back', () {
    expect(start(underCap: false), isFalse);
  });

  test('the foreground holds it back', () {
    expect(start(foreground: true), isFalse);
  });

  test('no change, a loss, or the first reading is not a gain', () {
    expect(
      start(previous: NetworkState.online, next: NetworkState.online),
      isFalse,
    );
    expect(
      start(previous: NetworkState.online, next: NetworkState.offline),
      isFalse,
    );
    expect(start(previous: null), isFalse);
  });
}
