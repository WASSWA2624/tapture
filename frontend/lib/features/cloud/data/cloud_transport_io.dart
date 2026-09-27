import 'dart:io';

import 'package:tapture/core/cloud/cloud_destination.dart';

/// Sends one request and returns a redirect instead of following it.
Future<CloudReply> sendCloud(CloudCall call) async {
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest request = await client.openUrl(
      call.method,
      call.url,
    );
    request.followRedirects = false;
    call.headers.forEach((String name, String value) {
      if (name.toLowerCase() == 'host') {
        return;
      }
      request.headers.set(name, value);
    });
    request.add(call.body);
    final HttpClientResponse response = await request.close();
    final List<int> body = await response.fold<List<int>>(<int>[], (
      List<int> collected,
      List<int> chunk,
    ) {
      collected.addAll(chunk);
      return collected;
    });
    final Map<String, String> headers = <String, String>{};
    response.headers.forEach((String name, List<String> values) {
      headers[name.toLowerCase()] = values.join(',');
    });
    return (status: response.statusCode, headers: headers, body: body);
  } finally {
    client.close(force: true);
  }
}
