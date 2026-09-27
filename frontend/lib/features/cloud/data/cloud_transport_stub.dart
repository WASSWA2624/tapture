import 'package:tapture/core/cloud/cloud_destination.dart';

/// Web stand-in. Uploads from this device use the IO transport.
Future<CloudReply> sendCloud(CloudCall call) async {
  return (
    status: call.url.host.isEmpty ? 400 : 503,
    headers: const <String, String>{},
    body: const <int>[],
  );
}
