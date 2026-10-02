import 'cloud_destination.dart';

/// A replayable bounded stream request. The factory is invoked per request.
typedef CloudStreamCall = ({
  String method,
  Uri url,
  Map<String, String> headers,
  int contentLength,
  Stream<List<int>> Function() openBody,
});

/// The streaming counterpart of [CloudSend].
typedef CloudStreamSend = Future<CloudReply> Function(CloudStreamCall call);
