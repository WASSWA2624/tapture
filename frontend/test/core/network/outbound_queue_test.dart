import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/network/network.dart';

void main() {
  test('offline holds work and an online transition drains it', () async {
    final StreamController<NetworkState> network =
        StreamController<NetworkState>.broadcast(sync: true);
    addTearDown(network.close);
    final List<String> sent = <String>[];
    final OutboundQueue queue = OutboundQueue(
      network: network.stream,
      send: (String path, String body) async {
        sent.add(body);
      },
    );
    addTearDown(queue.dispose);

    network.add(NetworkState.offline);
    await queue.submit(path: '/a', body: 'held');
    expect(sent, isEmpty);
    expect(queue.pending, 1);

    network.add(NetworkState.online);
    expect(sent, <String>['held']);
    expect(queue.pending, 0);
  });

  test('turning the override on retries nothing', () async {
    final StreamController<NetworkState> network =
        StreamController<NetworkState>.broadcast(sync: true);
    addTearDown(network.close);
    final List<String> sent = <String>[];
    final OutboundQueue queue = OutboundQueue(
      network: network.stream,
      send: (String path, String body) async {
        sent.add(body);
      },
    );
    addTearDown(queue.dispose);

    network.add(NetworkState.online);
    await queue.submit(path: '/a', body: 'now');
    expect(sent, <String>['now']);

    network.add(NetworkState.offline);
    await queue.submit(path: '/b', body: 'later');
    expect(sent, <String>['now']);
    expect(queue.pending, 1);

    network.add(NetworkState.offline);
    expect(sent, <String>['now']);
    expect(queue.pending, 1);
  });
}
