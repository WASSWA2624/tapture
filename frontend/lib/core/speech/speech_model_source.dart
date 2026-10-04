import 'speech_model_entry.dart';

/// Where the engine reads one catalogue model: a file on a device, or a
/// same-origin URL in a browser. Exactly one of [path] and [url] is set.
final class SpeechModelSource {
  /// Locates [entry] at [path] or [url].
  const SpeechModelSource({required this.entry, this.path, this.url})
    : assert((path == null) != (url == null), 'Set exactly one of path, url');

  /// The model expected at this place, by size and SHA-256.
  final SpeechModelEntry entry;

  /// A readable file on this device, or null in a browser.
  final String? path;

  /// A same-origin URL in a browser, or null on a device.
  final Uri? url;
}
