import 'dart:math';

/// Private probe names that cannot replace an existing user filename.
abstract final class CloudProbeName {
  /// Creates a cryptographically unique ASCII name for a connection test.
  static String create() {
    final Random random = Random.secure();
    return '.tapture-check-${List<String>.generate(24, (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join()}';
  }
}
