import 'dart:typed_data';

part 'in_memory_bundle.dart';
part 'stored_bundle.dart';

/// A written project package: a file in the project's `exports/` folder on
/// a device, or bytes in a browser, which has no file system (task 076, D6).
///
/// Variants live in this library so the type stays sealed while each class
/// keeps its own file (FE-STR-06).
sealed class BundleOutput {
  /// Creates an output.
  const BundleOutput({required this.byteLength, required this.sha256});

  /// Size of the whole package.
  final int byteLength;

  /// Lower-case hex SHA-256 of the whole package.
  final String sha256;
}
