import 'dart:typed_data';

/// Unsupported platforms fail through the shared transport boundary.
Future<({int status, String body})> send({
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  String? body,
}) async => throw UnsupportedError('HTTP is unavailable.');

/// Unsupported platforms fail through the shared transport boundary.
Future<({int status, Uint8List body})> sendBytes({
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  Uint8List? body,
}) async => throw UnsupportedError('HTTP is unavailable.');
