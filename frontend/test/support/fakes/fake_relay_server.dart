import 'dart:typed_data';

import 'package:tapture/core/backend/relay_queue.dart';
import 'package:tapture/core/errors/failure.dart';

/// An in-memory relay server for one project. It keeps ciphertext by id,
/// honours each device's idempotency keys, and drops a package once every
/// device has acknowledged it, as the real relay does (task 024).
final class FakeRelayServer {
  /// Creates the server for [projectId], shared by [devices].
  FakeRelayServer({
    this.projectId = 'project-1',
    this.relayEnabled = false,
    this.neverRelay = false,
    Set<String>? devices,
  }) : devices = devices ?? <String>{'device-a', 'device-b'};

  /// The one project this server relays for.
  final String projectId;

  /// The devices whose acknowledgements complete a package.
  final Set<String> devices;

  /// The project's relay switch.
  bool relayEnabled;

  /// The project's permanent never-relay marking.
  bool neverRelay;

  /// What registering a project answers: 201 for a project this account may
  /// hold, 404 for one registered to others.
  int registerStatus = 201;

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

  /// Every acknowledgement request, as `device/packageId`, in order.
  final List<String> ackRequests = <String>[];

  final Map<String, String> _authors = <String, String>{};
  final Map<String, String> _byKey = <String, String>{};

  String get _projectPath => '/api/v1/projects/$projectId';

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
          'id': projectId,
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
        return (status: registerStatus, body: <String, Object?>{});
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
          ackRequests.add('$device/$id');
          final Set<String>? seen = acks[id];
          if (seen == null) {
            continue;
          }
          seen.add(device);
          if (seen.containsAll(devices)) {
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
