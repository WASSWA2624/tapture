import 'dart:convert';
import 'dart:typed_data';

import 'package:tapture/core/errors/failure.dart';

import 'backend_transport_stub.dart'
    if (dart.library.io) 'backend_transport_io.dart'
    if (dart.library.js_interop) 'backend_transport_web.dart'
    as platform;

/// HTTPS JSON transport shared by enrolment, refresh and the AI proxy.
final class BackendTransport {
  /// Creates a transport whose address can change after configuration.
  const BackendTransport({required this.baseUrl});

  /// The organisation address, read at the moment a request is made.
  final String Function() baseUrl;

  /// Binary relay requests share validation and use no cookies or redirects.
  Future<({int status, Uint8List body})> sendBytes({
    required String method,
    required String path,
    Uint8List? body,
    required String token,
    String? idempotencyKey,
    bool json = false,
  }) async {
    final Uri base = _base();
    try {
      return await platform.sendBytes(
        uri: base.resolve(path),
        method: method,
        headers: <String, String>{
          'Content-Type': json
              ? 'application/json'
              : 'application/octet-stream',
          'X-Api-Version': '1',
          'Authorization': 'Bearer $token',
          'Idempotency-Key': ?idempotencyKey,
        },
        body: body,
      );
    } on Object {
      throw const NetworkFailure();
    }
  }

  /// Sends one request without logging or persisting its body.
  Future<({int status, Map<String, Object?> body})> send({
    required String method,
    required String path,
    Map<String, Object?>? body,
    String? token,
  }) async {
    final Uri base = _base();
    try {
      final ({int status, String body}) response = await platform.send(
        uri: base.resolve(path),
        method: method,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-Api-Version': '1',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body == null ? null : jsonEncode(body),
      );
      final Object? decoded = response.body.isEmpty
          ? <String, Object?>{}
          : jsonDecode(response.body);
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('Expected an object.');
      }
      return (status: response.status, body: decoded);
    } on Failure {
      rethrow;
    } on Object {
      throw const NetworkFailure(
        message: 'The organisation server could not be reached.',
        recoveryAction: 'Continue working offline and try again later.',
      );
    }
  }

  Uri _base() {
    final Uri? base = Uri.tryParse(baseUrl());
    if (base == null ||
        base.scheme != 'https' ||
        base.host.isEmpty ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw const ValidationFailure(
        message: 'Enter the organisation’s HTTPS server address.',
        recoveryAction: 'Check the address with your administrator.',
      );
    }
    return base;
  }
}
