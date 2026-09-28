import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:tapture/core/constants/app_constants.dart';

/// Executes a bounded native HTTP call and releases its connection.
Future<({int status, String body})> send({
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  String? body,
}) async {
  final response = await sendBytes(
    uri: uri,
    method: method,
    headers: headers,
    body: body == null ? null : Uint8List.fromList(utf8.encode(body)),
  );
  return (status: response.status, body: utf8.decode(response.body));
}

/// Sends or receives bounded opaque ciphertext through the same HTTPS boundary.
Future<({int status, Uint8List body})> sendBytes({
  required Uri uri,
  required String method,
  required Map<String, String> headers,
  Uint8List? body,
}) async {
  final HttpClient client = HttpClient()
    ..connectionTimeout = AppConstants.backend.proxyTimeout;
  try {
    return await (() async {
      final HttpClientRequest request = await client.openUrl(method, uri);
      request.followRedirects = false;
      headers.forEach(request.headers.set);
      if (body != null) request.add(body);
      final HttpClientResponse response = await request.close();
      final BytesBuilder bytes = BytesBuilder(copy: false);
      await for (final List<int> chunk in response) {
        bytes.add(chunk);
        if (bytes.length > AppConstants.imports.bundleMaxBytes) {
          throw const FormatException('Response too large.');
        }
      }
      return (status: response.statusCode, body: bytes.takeBytes());
    })().timeout(AppConstants.backend.proxyTimeout);
  } finally {
    client.close(force: true);
  }
}
