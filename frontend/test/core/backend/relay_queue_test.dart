import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/backend/relay_client.dart';
import 'package:tapture/core/backend/relay_queue.dart';
import 'package:tapture/core/backend/relay_snapshot.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/security/secure_storage.dart';

import '../../support/fakes/fake_id_service.dart';

const String _project = 'project-1';
const String _key = 'shared relay key 0123';

void main() {
  test('nothing queues without a key; the outbox holds ciphertext', () async {
    final Map<String, Uint8List> blobs = <String, Uint8List>{};
    final RelayQueue queue = _device(_RelayServer(), 'device-a', blobs: blobs);
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
    final _RelayServer server = _RelayServer();
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
    final _RelayServer server = _RelayServer();
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
    final _RelayServer server = _RelayServer(relayEnabled: true);
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
  _RelayServer server,
  String device, {
  Map<String, Uint8List>? blobs,
}) {
  return RelayQueue(
    store: BlobStore.memory(backing: blobs),
    secrets: SecureStorage.fake(backing: <SecretKey, String>{}),
    ids: FakeIdService(prefix: device.substring(device.length - 1)),
    send: server.sendFor(device),
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

/// An in-memory relay server. It keeps ciphertext by id, honours each
/// device's idempotency keys, and drops a package once every device has
/// acknowledged it.
final class _RelayServer {
  _RelayServer({this.relayEnabled = false});

  static const String _projectPath = '/api/v1/projects/$_project';

  /// The project's relay switch.
  bool relayEnabled;

  /// The project's permanent never-relay marking.
  bool neverRelay = false;

  /// Stores the next upload, then fails its response as a dropped
  /// connection would.
  bool dropNextUploadResponse = false;

  /// Upload attempts, including refused and replayed ones.
  int uploads = 0;

  /// The idempotency key of every upload attempt, in order.
  final List<String> uploadKeys = <String>[];

  /// Ciphertext the server still holds, by package id.
  final Map<String, Uint8List> packages = <String, Uint8List>{};

  /// The devices that acknowledged each package id.
  final Map<String, Set<String>> acks = <String, Set<String>>{};

  final Set<String> _devices = <String>{'device-a', 'device-b'};
  final Map<String, String> _authors = <String, String>{};
  final Map<String, String> _byKey = <String, String>{};

  /// The transport [device] uses, authenticated as that device.
  RelaySend sendFor(String device) {
    return ({
      required String method,
      required String path,
      Object? body,
      String? idempotencyKey,
    }) async {
      if (method == 'GET' && path == '/api/v1/projects') {
        final Map<String, Object?> project = <String, Object?>{
          'id': _project,
          'relayEnabled': relayEnabled,
          'neverRelay': neverRelay,
        };
        return (
          status: 200,
          body: <String, Object?>{
            'items': <Object?>[project],
          },
        );
      }
      if (method == 'POST' && path == '/api/v1/projects') {
        return (status: 409, body: <String, Object?>{});
      }
      if (method == 'PATCH' && path == _projectPath) {
        relayEnabled = (body! as Map<String, Object?>)['relayEnabled'] == true;
        return (status: 200, body: <String, Object?>{});
      }
      if (method == 'POST' && path == '$_projectPath/relay/packages') {
        uploads++;
        uploadKeys.add(idempotencyKey!);
        if (!relayEnabled || neverRelay) {
          return (status: 409, body: <String, Object?>{});
        }
        final String id = _byKey.putIfAbsent('$device/$idempotencyKey', () {
          final String minted = 'server-${_byKey.length + 1}';
          packages[minted] = Uint8List.fromList(body! as List<int>);
          _authors[minted] = device;
          acks[minted] = <String>{};
          return minted;
        });
        if (dropNextUploadResponse) {
          dropNextUploadResponse = false;
          throw const NetworkFailure();
        }
        return (status: 201, body: <String, Object?>{'id': id});
      }
      if (method == 'POST' && path == '/api/v1/relay/ack') {
        final Object? ids = (body! as Map<String, Object?>)['packageIds'];
        for (final Object? id in ids! as List<Object?>) {
          final Set<String>? seen = acks[id];
          if (seen == null) {
            continue;
          }
          seen.add(device);
          if (seen.containsAll(_devices)) {
            packages.remove(id);
          }
        }
        return (status: 200, body: <String, Object?>{});
      }
      if (method == 'GET' && path.startsWith('$_projectPath/relay/packages/')) {
        final Uint8List? bytes = packages[path.split('/').last];
        if (bytes == null) {
          return (status: 404, body: <String, Object?>{});
        }
        return (status: 200, body: bytes);
      }
      if (method == 'GET' && path == '$_projectPath/relay/packages') {
        final List<Object?> items = <Object?>[
          for (final String id in packages.keys)
            <String, Object?>{'id': id, 'authorDeviceId': _authors[id]},
        ];
        return (
          status: 200,
          body: <String, Object?>{'items': items, 'nextCursor': null},
        );
      }
      return (status: 404, body: <String, Object?>{});
    };
  }
}
