import 'dart:convert';
import 'dart:typed_data';

import 'package:tapture/core/bundle/bundle_encryption.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/security/secure_storage.dart';

import 'relay_client.dart';
import 'relay_snapshot.dart';

/// Durable ciphertext outbox; received bytes stay unacknowledged until applied.
final class RelayQueue {
  /// Reuses the platform stores and bundle encryption; the server never gets a key.
  RelayQueue({
    required this._store,
    required this._secrets,
    required this._ids,
    required this.send,
    required this.deviceId,
  });

  final BlobStore _store;
  final SecureStorage _secrets;
  final IdService _ids;

  /// Authenticated, offline-aware transport supplied at bootstrap.
  final RelaySend send;

  /// Used to exclude this device's outgoing packages from its inbox.
  final String deviceId;

  /// Adapts [sendBytes], such as `BackendSession.sendBytes`, to [RelaySend].
  ///
  /// A map travels as JSON and bytes as `application/octet-stream`. A single
  /// package download answers with ciphertext, which passes through as bytes;
  /// every other answer is the server's JSON envelope and is decoded here. An
  /// empty or unreadable envelope becomes null, so the caller's status and
  /// shape checks decide what it means.
  static RelaySend overBytes(RelayBytesSend sendBytes) {
    return ({
      required String method,
      required String path,
      Object? body,
      String? idempotencyKey,
    }) async {
      final ({int status, Uint8List body}) response = await sendBytes(
        method: method,
        path: path,
        body: switch (body) {
          null => null,
          final Uint8List bytes => bytes,
          final List<int> bytes => Uint8List.fromList(bytes),
          _ => Uint8List.fromList(utf8.encode(jsonEncode(body))),
        },
        idempotencyKey: idempotencyKey,
        json: body is! List<int>,
      );
      if (method == 'GET' && _packageDownload.hasMatch(path)) {
        return (status: response.status, body: response.body);
      }
      return (status: response.status, body: _envelope(response.body));
    };
  }

  /// One package's ciphertext, as opposed to the paged package list.
  static final RegExp _packageDownload = RegExp(r'/relay/packages/[^/?]+$');

  static Object? _envelope(Uint8List bytes) {
    if (bytes.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(utf8.decode(bytes));
    } on FormatException {
      return null;
    }
  }

  /// Stores an exchanged project key only in platform secure storage.
  Future<Result<void>> saveKey(
    String projectId,
    String key,
  ) async => _guard(() async {
    if (key.trim().length < 16) {
      throw const ValidationFailure(
        message: 'Use a shared key of at least 16 characters.',
        recoveryAction:
            'Ask the project manager for the same key used on the other devices.',
      );
    }
    final Map<String, Object?> keys = await _keys();
    keys[projectId] = key;
    _unwrap(await _secrets.putSecret(SecretKey.relayKeys, jsonEncode(keys)));
  });

  /// Encrypts first and persists the ciphertext before the UI confirms queueing.
  Future<Result<void>> enqueue(String projectId, Uint8List plain) async =>
      _guard(() async {
        final String key = await _key(projectId);
        final String id = _ids.newId();
        final Uint8List encrypted = BundleEncryption().seal(plain, key);
        _unwrap(await _store.write('packages/$id', encrypted));
        final Map<String, Object?> state = await _read(projectId);
        final List<Map<String, Object?>> rows = _rows(state);
        rows.add(<String, Object?>{'id': id, 'status': 'queued'});
        state['packages'] = rows;
        _unwrap(await _write(projectId, state));
      });

  /// Reads local counters immediately. This call never requires the server.
  Future<Result<RelaySnapshot>> snapshot(String projectId) async {
    try {
      final Map<String, Object?> state = await _read(projectId);
      return Success<RelaySnapshot>(
        _snapshot(state, (await _keys())[projectId] is String),
      );
    } on Object catch (error) {
      return FailureResult<RelaySnapshot>(Failure.from(error));
    }
  }

  /// Registers only metadata and toggles the optional server policy.
  Future<Result<void>> enable(String projectId, bool enabled) async =>
      _guard(() async {
        final registered = await send(
          method: 'POST',
          path: '/api/v1/projects',
          body: <String, Object?>{'id': projectId, 'name': projectId},
        );
        if (registered.status != 201 && registered.status != 409) {
          _require(registered.status);
        }
        final response = await send(
          method: 'PATCH',
          path: '/api/v1/projects/$projectId',
          body: <String, Object?>{'relayEnabled': enabled},
        );
        _require(response.status);
        final Map<String, Object?> state = await _read(projectId);
        state['enabled'] = enabled;
        _unwrap(await _write(projectId, state));
      });

  /// Flushes the durable queue, retries committed acknowledgements and reads inbox.
  Future<Result<void>> sync(String projectId) async => _guard(() async {
    final Map<String, Object?> state = await _read(projectId);
    final List<Map<String, Object?>> rows = _rows(state);
    // Read project settings before any upload; a never-relay project cannot send.
    final projects = await send(method: 'GET', path: '/api/v1/projects');
    _require(projects.status);
    final Object? list = projects.body is Map
        ? (projects.body as Map)['items']
        : projects.body;
    if (list is List) {
      for (final Object? value in list) {
        if (value is Map && value['id'] == projectId) {
          state['enabled'] = value['relayEnabled'] == true;
          state['neverRelay'] = value['neverRelay'] == true;
        }
      }
    }
    if (state['enabled'] != true || state['neverRelay'] == true) {
      _unwrap(await _write(projectId, state));
      return;
    }
    for (final Map<String, Object?> row in rows) {
      if (row['status'] != 'queued') continue;
      final String localId = row['id']! as String;
      final Uint8List? bytes = _unwrap(await _store.read('packages/$localId'));
      if (bytes == null) throw const StorageFailure();
      final response = await send(
        method: 'POST',
        path: '/api/v1/projects/$projectId/relay/packages',
        body: bytes,
        idempotencyKey: localId,
      );
      _require(response.status);
      final Object? body = response.body;
      if (body is! Map || body['id'] is! String) {
        throw const CorruptionFailure();
      }
      row['serverId'] = body['id'];
      row['status'] = 'sent';
      state['acks'] = <String>{
        ..._strings(state['acks']),
        body['id'] as String,
      }.toList();
      state['packages'] = rows;
      _unwrap(await _write(projectId, state));
      _unwrap(await _store.remove('packages/$localId'));
    }
    final List<String> acknowledgements = _strings(state['acks']);
    for (final String id in List<String>.of(acknowledgements)) {
      final response = await send(
        method: 'POST',
        path: '/api/v1/relay/ack',
        body: <String, Object?>{
          'packageIds': <String>[id],
        },
        idempotencyKey: 'ack-$deviceId-$id',
      );
      _require(response.status);
      acknowledgements.remove(id);
      state['acks'] = acknowledgements;
      _unwrap(await _write(projectId, state));
    }
    final List<String> incoming = <String>[];
    final Set<String> remote = <String>{};
    String? cursor;
    final Set<String> cursors = <String>{};
    do {
      final response = await send(
        method: 'GET',
        path:
            '/api/v1/projects/$projectId/relay/packages${cursor == null ? '' : '?cursor=${Uri.encodeQueryComponent(cursor)}'}',
      );
      _require(response.status);
      final Object? body = response.body;
      if (body is! Map || body['items'] is! List) {
        throw const CorruptionFailure();
      }
      for (final Object? value in body['items'] as List) {
        if (value is Map && value['id'] is String) {
          final String id = value['id'] as String;
          remote.add(id);
          if (value['authorDeviceId'] != deviceId &&
              !_strings(state['received']).contains(id)) {
            incoming.add(id);
          }
        }
      }
      cursor = body['nextCursor'] as String?;
      if (cursor != null && !cursors.add(cursor)) {
        throw const CorruptionFailure();
      }
    } while (cursor != null);
    for (final Map<String, Object?> row in rows) {
      if (row['status'] == 'sent' && !remote.contains(row['serverId'])) {
        final response = await send(
          method: 'GET',
          path: '/api/v1/projects/$projectId/relay/packages/${row['serverId']}',
        );
        if (response.status == 404) row['status'] = 'purged';
      }
    }
    state['incoming'] = incoming;
    state['packages'] = rows;
    _unwrap(await _write(projectId, state));
  });

  /// Downloads and decrypts for the existing import preview, without acknowledging.
  Future<Result<Uint8List>> receive(String projectId, String packageId) async {
    try {
      final response = await send(
        method: 'GET',
        path: '/api/v1/projects/$projectId/relay/packages/$packageId',
      );
      _require(response.status);
      if (response.body is! List<int>) throw const CorruptionFailure();
      return Success<Uint8List>(
        BundleEncryption().open(
          Uint8List.fromList(response.body! as List<int>),
          await _key(projectId),
        ),
      );
    } on Object catch (error) {
      return FailureResult<Uint8List>(Failure.from(error));
    }
  }

  /// Persists an applied receipt before attempting its network acknowledgement.
  Future<Result<void>> applied(String projectId, String packageId) async =>
      _guard(() async {
        final Map<String, Object?> state = await _read(projectId);
        state['received'] = <String>{
          ..._strings(state['received']),
          packageId,
        }.toList();
        state['acks'] = <String>{
          ..._strings(state['acks']),
          packageId,
        }.toList();
        state['incoming'] = _strings(state['incoming'])..remove(packageId);
        _unwrap(await _write(projectId, state));
        // A failed acknowledgement stays durable and is retried by Sync.
        await sync(projectId);
      });

  Future<Map<String, Object?>> _keys() async {
    final String? raw = _unwrap(await _secrets.readSecret(SecretKey.relayKeys));
    return raw == null
        ? <String, Object?>{}
        : Map<String, Object?>.from(jsonDecode(raw) as Map);
  }

  Future<String> _key(String projectId) async {
    final Object? key = (await _keys())[projectId];
    if (key is! String || key.isEmpty) {
      throw const ValidationFailure(
        message: 'Add the shared project key first.',
        recoveryAction: 'Ask the project manager for the key.',
      );
    }
    return key;
  }

  Future<Map<String, Object?>> _read(String projectId) async {
    final Uint8List? bytes = _unwrap(await _store.read('state/$projectId'));
    return bytes == null
        ? <String, Object?>{}
        : Map<String, Object?>.from(jsonDecode(utf8.decode(bytes)) as Map);
  }

  Future<Result<void>> _write(String projectId, Map<String, Object?> state) =>
      _store.write(
        'state/$projectId',
        Uint8List.fromList(utf8.encode(jsonEncode(state))),
      );
  List<Map<String, Object?>> _rows(
    Map<String, Object?> state,
  ) => <Map<String, Object?>>[
    for (final Object? value in state['packages'] as List? ?? const <Object?>[])
      if (value is Map) Map<String, Object?>.from(value),
  ];
  List<String> _strings(Object? value) =>
      value is List ? value.whereType<String>().toList() : <String>[];
  RelaySnapshot _snapshot(Map<String, Object?> state, bool hasKey) {
    final rows = _rows(state);
    return RelaySnapshot(
      queued: rows.where((row) => row['status'] == 'queued').length,
      sent: rows
          .where((row) => row['status'] == 'sent' || row['status'] == 'purged')
          .length,
      purged: rows.where((row) => row['status'] == 'purged').length,
      hasKey: hasKey,
      enabled: state['enabled'] == true,
      neverRelay: state['neverRelay'] == true,
      incoming: _strings(state['incoming']),
    );
  }

  Future<Result<void>> _guard(Future<void> Function() work) async {
    try {
      await work();
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(Failure.from(error));
    }
  }

  T _unwrap<T>(Result<T> result) => switch (result) {
    Success<T>(:final value) => value,
    FailureResult<T>(:final failure) => throw failure,
  };
  void _require(int status) {
    if (status < 200 || status >= 300) {
      throw const NetworkFailure(
        message: 'Relay could not complete this request.',
        recoveryAction: 'Keep working locally and try Sync again.',
      );
    }
  }
}

/// A byte transport with the session's token rotation and offline policy.
typedef RelayBytesSend =
    Future<({int status, Uint8List body})> Function({
      required String method,
      required String path,
      Uint8List? body,
      String? idempotencyKey,
      bool json,
    });
