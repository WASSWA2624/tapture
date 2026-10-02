import 'package:tapture/core/errors/result.dart';

import 'destination_secret_lease.dart';
import 'destination_secrets.dart';
import 'worker_cloud_destination.dart';

/// Copied credentials of one worker. Every mutation waits for parent secure
/// storage acknowledgement before the worker can use it or send more bytes.
final class CloudWorkerSecrets implements DestinationSecrets {
  /// Creates the store from [job]'s consistent leased snapshot.
  CloudWorkerSecrets(CloudWorkerJob job, this.onWrite)
    : _lease = job.lease,
      _access = job.lease.access,
      _refresh = job.lease.refresh,
      _session = job.lease.session;

  /// Persists one write in the parent isolate and returns its acknowledgement.
  final Future<Result<void>> Function(CloudSecretWrite write) onWrite;
  final DestinationSecretLease _lease;
  String? _access;
  String? _refresh;
  String? _session;

  @override
  Future<Result<void>> put(String ref, String payload) async {
    final Result<void> stored = await onWrite((
      refresh: false,
      session: false,
      ref: ref,
      value: payload,
    ));
    if (stored is Success<void>) {
      _access = payload;
    }
    return stored;
  }

  @override
  Future<Result<String?>> read(String ref) async =>
      Success<String?>(ref == _lease.ref ? _access : null);

  @override
  Future<Result<String?>> readRefresh(String ref) async =>
      Success<String?>(ref == _lease.ref ? _refresh : null);

  @override
  Future<Result<void>> putRefresh(String ref, String token) async {
    final Result<void> stored = await onWrite((
      refresh: true,
      session: false,
      ref: ref,
      value: token,
    ));
    if (stored is Success<void>) {
      _refresh = token;
    }
    return stored;
  }

  /// Provider checkpoint copied from secure storage.
  Future<String?> readSession() async => _session;

  /// Applies a token whose SDK bridge has already received durable storage ACK.
  void acknowledgedAccess(String value) => _access = value;

  /// Saves or clears a session, waiting for durable parent acknowledgement.
  Future<void> writeSession(String? value) async {
    (await onWrite((
      refresh: false,
      session: true,
      ref: _lease.ref,
      value: value,
    ))).getOrThrow();
    _session = value;
  }

  @override
  Future<Result<void>> forget(String ref) async {
    await writeSession(null);
    _access = null;
    _refresh = null;
    return const Success<void>(null);
  }

  @override
  Future<Result<DestinationSecretLease>> lease(
    String ref,
    String sessionKey,
  ) async => Success<DestinationSecretLease>(_lease);

  @override
  Future<Result<void>> putLeased(
    DestinationSecretLease lease, {
    required String? value,
    bool refresh = false,
    bool session = false,
  }) => onWrite((
    refresh: refresh,
    session: session,
    ref: lease.ref,
    value: value,
  ));
}
