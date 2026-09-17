import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/network/connectivity_service.dart';

void main() {
  test('each radio state is reported when the override is off', () async {
    final StreamController<NetworkState> radio = _radio();
    addTearDown(radio.close);
    final ConnectivityService service = ConnectivityService.fake(
      source: radio.stream,
    );
    addTearDown(service.dispose);

    final List<NetworkState> seen = <NetworkState>[];
    final StreamSubscription<NetworkState> subscription = service
        .watch()
        .listen(seen.add);
    addTearDown(subscription.cancel);

    radio.add(NetworkState.online);
    radio.add(NetworkState.metered);
    radio.add(NetworkState.offline);

    expect(seen, <NetworkState>[
      NetworkState.online,
      NetworkState.metered,
      NetworkState.offline,
    ]);
  });

  test('the manual override reports offline from every radio state', () async {
    final StreamController<NetworkState> radio = _radio();
    final StreamController<bool> override = StreamController<bool>(sync: true);
    addTearDown(radio.close);
    addTearDown(override.close);
    final ConnectivityService service = ConnectivityService.fake(
      source: radio.stream,
      offlineOverride: override.stream,
    );
    addTearDown(service.dispose);

    final List<NetworkState> seen = <NetworkState>[];
    final StreamSubscription<NetworkState> subscription = service
        .watch()
        .listen(seen.add);
    addTearDown(subscription.cancel);

    for (final NetworkState state in NetworkState.values) {
      radio.add(state);
      expect(seen.last, state);
      override.add(true);
      expect(seen.last, NetworkState.offline);
      override.add(false);
      expect(seen.last, state);
    }
  });

  test('dispose releases the radio subscription', () async {
    final StreamController<NetworkState> radio = _radio();
    addTearDown(radio.close);
    final StreamController<bool> override = StreamController<bool>(sync: true);
    addTearDown(override.close);
    final ConnectivityService service = ConnectivityService.fake(
      source: radio.stream,
      offlineOverride: override.stream,
    );

    expect(radio.hasListener, isTrue);
    expect(override.hasListener, isTrue);
    await service.dispose();
    expect(radio.hasListener, isFalse);
    expect(override.hasListener, isFalse);
    await service.dispose();
  });
}

/// A sync radio so the test can assert in the same turn as an event (FE-TEST-07).
StreamController<NetworkState> _radio() {
  return StreamController<NetworkState>(sync: true);
}
