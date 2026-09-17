part of 'ai_service.dart';

/// Images to read on a provider, identified by path rather than by bytes.
final class ReadTextRequest {
  /// Creates a read-text request.
  const ReadTextRequest({required this.imagePaths});

  /// Compressed copies. Originals stay on the device.
  final List<String> imagePaths;
}
