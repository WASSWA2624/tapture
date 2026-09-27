import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/relay_client.dart';

void main() {
  test('two devices relay one package and a replay does not duplicate it', () async {
    final Map<String, List<int>> packages = <String, List<int>>{};
    final List<String> order = <String>[];
    var pushes = 0;

    RelaySend server({required bool enabled}) {
      return ({
        required String method,
        required String path,
        Object? body,
        String? idempotencyKey,
      }) async {
        if (method == 'POST' && path.endsWith('/relay/packages')) {
          pushes += 1;
          final String id = idempotencyKey ?? 'generated';
          packages.putIfAbsent(id, () => body as List<int>);
          return (status: 201, body: <String, Object?>{'id': id});
        }
        if (method == 'GET') {
          final String id = path.split('/').last;
          return (status: 200, body: packages[id]);
        }
        order.add('ack');
        packages.clear();
        return (status: 200, body: <String, Object?>{'acknowledged': <String>[]});
      };
    }

    final List<int> bytes = <int>[1, 2, 3, 4];
    final RelayClient sender = RelayClient(
      send: server(enabled: true),
      apply: (_) async {},
      enabled: true,
    );
    final String first = await sender.push(
      projectId: 'project-1',
      bytes: bytes,
      idempotencyKey: 'key-1',
    );
    final String replay = await sender.push(
      projectId: 'project-1',
      bytes: bytes,
      idempotencyKey: 'key-1',
    );
    expect(replay, first);
    expect(packages.length, 1);

    final RelayClient receiver = RelayClient(
      send: server(enabled: true),
      apply: (List<int> incoming) async {
        order.add('merge');
        expect(incoming, bytes);
      },
      enabled: true,
    );
    await receiver.fetchMergeAck(
      projectId: 'project-1',
      packageId: first,
      idempotencyKey: 'ack-1',
    );
    expect(order, <String>['merge', 'ack']);
    expect(packages, isEmpty);
    expect(pushes, 2);
  });

  test('a disabled or never-relay project cannot send', () async {
    final RelayClient off = RelayClient(
      send: ({
        required String method,
        required String path,
        Object? body,
        String? idempotencyKey,
      }) async {
        return (status: 500, body: null);
      },
      apply: (_) async {},
    );
    expect(
      () => off.push(projectId: 'project-1', bytes: <int>[1], idempotencyKey: 'k'),
      throwsStateError,
    );
    final RelayClient never = RelayClient(
      send: ({
        required String method,
        required String path,
        Object? body,
        String? idempotencyKey,
      }) async {
        return (status: 500, body: null);
      },
      apply: (_) async {},
      enabled: true,
      neverRelay: true,
    );
    expect(
      () => never.push(
        projectId: 'project-1',
        bytes: <int>[1],
        idempotencyKey: 'k',
      ),
      throwsStateError,
    );
  });
}
