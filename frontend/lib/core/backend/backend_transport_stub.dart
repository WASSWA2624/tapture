import 'dart:typed_data';
import 'package:tapture/core/concurrency/cancellation_token.dart';

/// Unsupported platforms fail through the shared transport boundary.
Future<({int status, String body})> send({
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  String? body,
  CancellationToken? cancellationToken,
}) async => throw UnsupportedError('HTTP is unavailable.');

/// Unsupported platforms fail through the shared transport boundary.
Future<({int status, Uint8List body})> sendBytes({
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  Uint8List? body,
}) async => throw UnsupportedError('HTTP is unavailable.');
