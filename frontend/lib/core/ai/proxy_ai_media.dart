part of 'proxy_ai_service.dart';

/// Reads cancellable media bytes without sending paths or rewriting originals.
mixin _ProxyMedia {
  Future<Result<Uint8List>> Function(String path)? get readBytes;

  Future<List<Map<String, String>>> _images(
    List<String> paths, [
    CancellationToken? cancel,
  ]) async => <Map<String, String>>[
    for (final String path in paths) await _media(path, cancel),
  ];

  Future<Map<String, String>> _media(
    String path, [
    CancellationToken? cancel,
  ]) async {
    _checkCancelled(cancel);
    final reader = readBytes;
    if (reader == null) {
      throw StorageFailure(
        localizedMessage: Copy.messages.failureTheAnalysisCopyCouldNotBeRead,
        localizedRecovery: Copy.messages.failureKeepTheRecordAndTryAgain,
      );
    }
    final Result<Uint8List> result = await reader(path);
    _checkCancelled(cancel);
    if (result is FailureResult<Uint8List>) throw result.failure;
    final String extension = path.split('.').last.toLowerCase();
    final String mime = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'wav' => 'audio/wav',
      'mp3' => 'audio/mpeg',
      'm4a' || 'mp4' => 'audio/mp4',
      'aac' => 'audio/aac',
      _ => 'image/jpeg',
    };
    return <String, String>{
      'mimeType': mime,
      'base64': base64Encode((result as Success<Uint8List>).value),
    };
  }
}
