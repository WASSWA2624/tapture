import 'dart:async';

/// Uploads an opaque package, applies it with the existing merge, then acks.
final class RelayClient {
  /// Creates a client. [apply] is the project's merge path.
  const RelayClient({
    required this.send,
    required this.apply,
    this.enabled = false,
    this.neverRelay = false,
  });

  /// Transport.
  final RelaySend send;

  /// Applies downloaded bytes through the existing bundle merge.
  final Future<void> Function(List<int> bytes) apply;

  /// False until a project manager enables relay.
  final bool enabled;

  /// A never-relay project cannot send.
  final bool neverRelay;

  /// Pushes [bytes]. A repeated [idempotencyKey] returns the first id.
  Future<String> push({
    required String projectId,
    required List<int> bytes,
    required String idempotencyKey,
  }) async {
    if (!enabled || neverRelay) {
      throw StateError('Relay is not enabled for this project.');
    }
    final ({int status, Object? body}) response = await send(
      method: 'POST',
      path: '/api/v1/projects/$projectId/relay/packages',
      body: bytes,
      idempotencyKey: idempotencyKey,
    );
    final Object? body = response.body;
    if (response.status != 201 || body is! Map || body['id'] is! String) {
      throw StateError('The package was not accepted.');
    }
    return body['id'] as String;
  }

  /// Downloads [packageId], merges it, then acknowledges.
  Future<void> fetchMergeAck({
    required String projectId,
    required String packageId,
    required String idempotencyKey,
  }) async {
    final ({int status, Object? body}) response = await send(
      method: 'GET',
      path: '/api/v1/projects/$projectId/relay/packages/$packageId',
    );
    final Object? body = response.body;
    if (body is! List<int>) {
      throw StateError('The package could not be read.');
    }
    await apply(body);
    await send(
      method: 'POST',
      path: '/api/v1/relay/ack',
      body: <String, Object?>{
        'packageIds': <String>[packageId],
      },
      idempotencyKey: idempotencyKey,
    );
  }
}

/// One relay HTTP call.
typedef RelaySend =
    Future<({int status, Object? body})> Function({
      required String method,
      required String path,
      Object? body,
      String? idempotencyKey,
    });
