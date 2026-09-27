part of 'bundle_output.dart';

/// A package built in memory, as a browser builds it.
final class InMemoryBundle extends BundleOutput {
  /// Creates an in-memory package.
  const InMemoryBundle({
    required this.bytes,
    required super.byteLength,
    required super.sha256,
  });

  /// The whole package.
  final Uint8List bytes;
}
