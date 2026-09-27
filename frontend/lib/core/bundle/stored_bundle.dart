part of 'bundle_output.dart';

/// A package written to disk, under the storage root.
final class StoredBundle extends BundleOutput {
  /// Creates a stored package.
  const StoredBundle({
    required this.relativePath,
    required super.byteLength,
    required super.sha256,
  });

  /// Where it sits: `projects/<folder>/exports/<bundleId>.zip`.
  final String relativePath;
}
