import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/relay_queue.dart';
import 'package:tapture/core/backend/relay_snapshot.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/security/secure_storage.dart';

import '../../support/fakes/fake_id_service.dart';
import '../../support/fakes/fake_relay_server.dart';

const String _project = 'project-1';
const String _key = 'shared relay key 0123';

void main() {
  test(
    'oversized relay input is refused before encryption or outbox writes',
    () async {
      final Map<String, Uint8List> backing = <String, Uint8List>{};
      final FakeRelayServer server = FakeRelayServer();
      final RelayQueue queue = _device(server, 'device-a', blobs: backing);
      final Uint8List plain = Uint8List(AppConstants.backend.relayMaxBytes)
        ..first = 17
        ..last = 29;
      final Result<void> result = await queue.enqueue(_project, plain);
      expect(_failure(result), isA<ValidationFailure>());
      expect(backing, isEmpty);
      expect(server.uploads, 0);
      expect(plain.first, 17);
      expect(plain.last, 29);
    },
  );

  test('relay finds project policy on a later authorized page', () async {
    final FakeRelayServer server = FakeRelayServer()..relayEnabled = true;
    final List<String> pages = <String>[];
    final RelayQueue queue = _device(
      server,
      'device-a',
      send:
          ({
            required String method,
            required String path,
            Object? body,
            String? idempotencyKey,
          }) async {
            final Uri uri = Uri.parse(path);
            if (uri.path == '/api/v1/projects' && method == 'GET') {
              pages.add(path);
              return (
                status: 200,
                body: <String, Object?>{
                  'items': <Object?>[
                    if (uri.queryParameters['cursor'] == null)
                      <String, Object?>{
                        'id': 'other-project',
                        'relayEnabled': false,
                      }
                    else
                      <String, Object?>{
                        'id': _project,
                        'relayEnabled': true,
                        'neverRelay': false,
                      },
                  ],
                  'nextCursor': uri.queryParameters['cursor'] == null
                      ? 'next+opaque/page'
                      : null,
                },
              );
            }
            return server.sendFor('device-a')(
              method: method,
              path: path,
              body: body,
              idempotencyKey: idempotencyKey,
            );
          },
    );
    await queue.saveKey(_project, _key);
    await queue.enqueue(_project, _package('change'));
    expect(await queue.sync(_project), isA<Success<void>>());
    expect(pages, hasLength(2));
    expect(Uri.parse(pages.last).queryParameters['cursor'], 'next+opaque/page');
    expect(server.uploads, 1);
  });

  test('a repeated project cursor fails before any upload', () async {
    final FakeRelayServer server = FakeRelayServer();
    var reads = 0;
    final RelayQueue queue = _device(
      server,
      'device-a',
      send:
          ({
            required String method,
            required String path,
            Object? body,
            String? idempotencyKey,
          }) async {
            if (Uri.parse(path).path == '/api/v1/projects' && method == 'GET') {
              reads++;
              return (
                status: 200,
                body: <String, Object?>{
                  'items': <Object?>[],
                  'nextCursor': 'same',
                },
              );
            }
            return server.sendFor('device-a')(
              method: method,
              path: path,
              body: body,
              idempotencyKey: idempotencyKey,
            );
          },
    );
    expect(_failure(await queue.sync(_project)), isA<CorruptionFailure>());
    expect(reads, 2);
    expect(server.uploads, 0);
  });

  test(
    'a removed project cannot upload using cached relay permission',
    () async {
      final FakeRelayServer server = FakeRelayServer()..relayEnabled = true;
      var visible = true;
      final RelayQueue queue = _device(
        server,
        'device-a',
        send:
            ({
              required String method,
              required String path,
              Object? body,
              String? idempotencyKey,
            }) async {
              if (!visible &&
                  Uri.parse(path).path == '/api/v1/projects' &&
                  method == 'GET') {
                return (
                  status: 200,
                  body: <String, Object?>{
                    'items': <Object?>[],
                    'nextCursor': null,
                  },
                );
              }
              return server.sendFor('device-a')(
                method: method,
                path: path,
                body: body,
                idempotencyKey: idempotencyKey,
              );
            },
      );
      await queue.saveKey(_project, _key);
      await queue.sync(_project);
      expect(_value(await queue.snapshot(_project)).enabled, isTrue);
      await queue.enqueue(_project, _package('change'));
      visible = false;
      expect(await queue.sync(_project), isA<Success<void>>());
      expect(_value(await queue.snapshot(_project)).enabled, isFalse);
      expect(_value(await queue.snapshot(_project)).queued, 1);
      expect(server.uploads, 0);
    },
  );

  test('nothing queues without a key; the outbox holds ciphertext', () async {
    final Map<String, Uint8List> blobs = <String, Uint8List>{};
    final RelayQueue queue = _device(
      FakeRelayServer(),
      'device-a',
      blobs: blobs,
    );
    final Uint8List plain = _package('first change');

    expect(
      _failure(await queue.enqueue(_project, plain)),
      isA<ValidationFailure>(),
    );
    expect(blobs, isEmpty);

    expect(await queue.saveKey(_project, _key), isA<Success<void>>());
    expect(await queue.enqueue(_project, plain), isA<Success<void>>());
    final Uint8List stored = blobs['packages/a-1']!;
    expect(stored, isNot(equals(plain)));
    expect(
      utf8.decode(stored, allowMalformed: true),
      isNot(contains('first change')),
    );
    expect(
      utf8.decode(blobs['state/$_project']!),
      isNot(contains('first change')),
    );
    final RelaySnapshot view = _value(await queue.snapshot(_project));
    expect(view.queued, 1);
    expect(view.sent, 0);
    expect(view.hasKey, isTrue);
    expect(view.enabled, isFalse);
  });

  test('relay stays off until enabled; never-relay never uploads', () async {
    final FakeRelayServer server = FakeRelayServer();
    final RelayQueue queue = _device(server, 'device-a');
    await queue.saveKey(_project, _key);
    await queue.enqueue(_project, _package('change'));

    expect(await queue.sync(_project), isA<Success<void>>());
    expect(server.uploads, 0);
    RelaySnapshot view = _value(await queue.snapshot(_project));
    expect(view.enabled, isFalse);
    expect(view.queued, 1);

    server.relayEnabled = true;
    server.neverRelay = true;
    expect(await queue.sync(_project), isA<Success<void>>());
    expect(server.uploads, 0);
    view = _value(await queue.snapshot(_project));
    expect(view.enabled, isTrue);
    expect(view.neverRelay, isTrue);
    expect(view.queued, 1);
    expect(view.sent, 0);
  });

  test('a dropped upload replays under one key and is stored once', () async {
    final FakeRelayServer server = FakeRelayServer();
    final Map<String, Uint8List> blobs = <String, Uint8List>{};
    final RelayQueue queue = _device(server, 'device-a', blobs: blobs);
    await queue.saveKey(_project, _key);
    expect(await queue.enable(_project, true), isA<Success<void>>());
    expect(server.relayEnabled, isTrue);
    await queue.enqueue(_project, _package('change'));

    server.dropNextUploadResponse = true;
    expect(_failure(await queue.sync(_project)), isA<NetworkFailure>());
    expect(_value(await queue.snapshot(_project)).queued, 1);
    expect(blobs.containsKey('packages/a-1'), isTrue);

    expect(await queue.sync(_project), isA<Success<void>>());
    expect(server.uploads, 2);
    expect(server.uploadKeys, <String>['a-1', 'a-1']);
    expect(server.packages, hasLength(1));
    final RelaySnapshot view = _value(await queue.snapshot(_project));
    expect(view.queued, 0);
    expect(view.sent, 1);
    expect(view.purged, 0);
    expect(blobs.containsKey('packages/a-1'), isFalse);
  });

  test('received packages preview unacknowledged and ack on apply', () async {
    final FakeRelayServer server = FakeRelayServer(relayEnabled: true);
    final RelayQueue sender = _device(server, 'device-a');
    final RelayQueue receiver = _device(server, 'device-b');
    final Uint8List plain = _package('shared change');
    await sender.saveKey(_project, _key);
    await sender.enqueue(_project, plain);
    expect(await sender.sync(_project), isA<Success<void>>());
    expect(_value(await sender.snapshot(_project)).incoming, isEmpty);

    await receiver.saveKey(_project, 'another relay key 0123');
    expect(await receiver.sync(_project), isA<Success<void>>());
    final String id = server.packages.keys.single;
    expect(_value(await receiver.snapshot(_project)).incoming, <String>[id]);
    expect(
      _failure(await receiver.receive(_project, id)),
      isA<ValidationFailure>(),
    );

    await receiver.saveKey(_project, _key);
    expect(_value(await receiver.receive(_project, id)), plain);
    expect(server.acks[id], <String>{'device-a'});
    expect(_value(await receiver.snapshot(_project)).incoming, <String>[id]);

    expect(await receiver.applied(_project, id), isA<Success<void>>());
    expect(server.acks[id], <String>{'device-a', 'device-b'});
    expect(server.packages, isEmpty);
    expect(_value(await receiver.snapshot(_project)).incoming, isEmpty);
    expect(await receiver.sync(_project), isA<Success<void>>());
    expect(_value(await receiver.snapshot(_project)).incoming, isEmpty);

    expect(await sender.sync(_project), isA<Success<void>>());
    final RelaySnapshot view = _value(await sender.snapshot(_project));
    expect(view.sent, 1);
    expect(view.purged, 1);
    expect(view.queued, 0);
  });

  test('byte transport: maps travel as JSON, ciphertext as bytes', () async {
    final List<_Call> calls = <_Call>[];
    final Uint8List cipher = Uint8List.fromList(<int>[84, 65, 80, 84, 1, 2]);
    Future<({int status, Uint8List body})> transport({
      required String method,
      required String path,
      Uint8List? body,
      String? idempotencyKey,
      bool json = false,
    }) async {
      final _Call call = (
        method: method,
        path: path,
        body: body,
        key: idempotencyKey,
        json: json,
      );
      calls.add(call);
      if (path.endsWith('/relay/packages/server-1')) {
        return (status: 200, body: cipher);
      }
      if (path.endsWith('/relay/ack')) {
        return (status: 200, body: Uint8List(0));
      }
      final Map<String, Object?> created = <String, Object?>{'id': 'server-1'};
      return (status: 201, body: _package(jsonEncode(created)));
    }

    final RelaySend send = RelayQueue.overBytes(transport);

    final ({int status, Object? body}) uploaded = await send(
      method: 'POST',
      path: '/api/v1/projects/$_project/relay/packages',
      body: cipher,
      idempotencyKey: 'a-1',
    );
    expect(uploaded.status, 201);
    expect(uploaded.body, <String, Object?>{'id': 'server-1'});
    expect(calls.last.json, isFalse);
    expect(calls.last.body, cipher);
    expect(calls.last.key, 'a-1');

    final Map<String, Object?> ack = <String, Object?>{
      'packageIds': <String>['server-1'],
    };
    final ({int status, Object? body}) acknowledged = await send(
      method: 'POST',
      path: '/api/v1/relay/ack',
      body: ack,
    );
    expect(acknowledged.status, 200);
    expect(acknowledged.body, isNull);
    expect(calls.last.json, isTrue);
    expect(jsonDecode(utf8.decode(calls.last.body!)), ack);

    final ({int status, Object? body}) downloaded = await send(
      method: 'GET',
      path: '/api/v1/projects/$_project/relay/packages/server-1',
    );
    expect(downloaded.body, isA<Uint8List>());
    expect(downloaded.body, cipher);
    expect(calls.last.body, isNull);

    final ({int status, Object? body}) listed = await send(
      method: 'GET',
      path: '/api/v1/projects/$_project/relay/packages?cursor=next',
    );
    expect(listed.body, <String, Object?>{'id': 'server-1'});
  });
}

/// One request the byte transport received.
typedef _Call = ({
  String method,
  String path,
  Uint8List? body,
  String? key,
  bool json,
});

/// A device's queue over its own stores, talking to [server] as [device].
RelayQueue _device(
  FakeRelayServer server,
  String device, {
  Map<String, Uint8List>? blobs,
  RelaySend? send,
}) {
  return RelayQueue(
    store: BlobStore.memory(backing: blobs),
    secrets: SecureStorage.fake(backing: <SecretKey, String>{}),
    ids: FakeIdService(prefix: device.substring(device.length - 1)),
    send: send ?? server.sendFor(device),
    deviceId: device,
  );
}

Uint8List _package(String text) => Uint8List.fromList(utf8.encode(text));

T _value<T>(Result<T> result) {
  return switch (result) {
    Success<T>(:final T value) => value,
    FailureResult<T>(:final Failure failure) => throw TestFailure(
      failure.message,
    ),
  };
}

Failure _failure<T>(Result<T> result) {
  return switch (result) {
    Success<T>() => throw TestFailure('Expected a failure.'),
    FailureResult<T>(:final Failure failure) => failure,
  };
}
