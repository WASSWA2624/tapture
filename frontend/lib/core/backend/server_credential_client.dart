import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import 'backend_api_client.dart';

/// Saves personal AI credentials directly to the authenticated server keystore.
final class ServerCredentialClient {
  /// The sender never logs or persists credential bodies on the device.
  const ServerCredentialClient({required this.send});

  /// Authenticated backend transport; tests provide a hand-written fake.
  final BackendSend send;

  /// Checks credential existence without retrieving the key.
  Future<Result<bool>> configured(String provider) async {
    try {
      final response = await send(method: 'GET', path: _path(provider));
      _accepted(response.status);
      final Object? configured = response.body['configured'];
      if (configured is! bool) throw const FormatException();
      return Success<bool>(configured);
    } on Object catch (error) {
      return FailureResult<bool>(_failure(error));
    }
  }

  /// Encrypts a key on the server before reporting success.
  Future<Result<void>> save(String provider, String key) async {
    try {
      final response = await send(
        method: 'PUT',
        path: _path(provider),
        body: <String, Object?>{'apiKey': key},
      );
      _accepted(response.status);
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(_failure(error));
    }
  }

  /// Deletes the encrypted key without switching the selected billing account.
  Future<Result<void>> remove(String provider) async {
    try {
      final response = await send(method: 'DELETE', path: _path(provider));
      _accepted(response.status);
      return const Success<void>(null);
    } on Object catch (error) {
      return FailureResult<void>(_failure(error));
    }
  }

  String _path(String provider) =>
      '/api/v1/ai/credentials/${Uri.encodeComponent(provider)}';

  void _accepted(int status) {
    if (status >= 200 && status < 300) return;
    throw const NetworkFailure(
      message: 'The server could not update this AI credential.',
      recoveryAction:
          'Check your organisation access and try again. Capture remains available.',
    );
  }

  Failure _failure(Object error) => error is Failure
      ? error
      : const NetworkFailure(
          message: 'The server could not update this AI credential.',
          recoveryAction:
              'Check your organisation access and try again. Capture remains available.',
        );
}

/// Bootstrap supplies the signed-in server; the default makes no outbound call.
final Provider<ServerCredentialClient> serverCredentialClientProvider =
    Provider<ServerCredentialClient>(
      (Ref _) => const ServerCredentialClient(send: _unavailable),
    );

Future<({int status, Map<String, Object?> body})> _unavailable({
  required String method,
  required String path,
  Map<String, Object?>? body,
  String? token,
}) async => (status: 503, body: <String, Object?>{});
