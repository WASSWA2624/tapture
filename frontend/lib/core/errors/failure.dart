import 'dart:async';

part 'cancelled_failure.dart';
part 'corruption_failure.dart';
part 'network_failure.dart';
part 'permission_failure.dart';
part 'provider_failure.dart';
part 'provider_failure_kind.dart';
part 'storage_failure.dart';
part 'validation_failure.dart';

/// A typed failure at a layer boundary.
///
/// Variants live in this library so the type can stay sealed (FE-CODE-06)
/// while each class keeps its own file (FE-STR-06).
sealed class Failure {
  /// Creates a failure.
  const Failure();

  /// Plain-language explanation shown to the operator.
  String get message;

  /// What the operator can do next. Always offered; never `toString`.
  String? get recoveryAction;

  /// Maps a thrown object onto the variant that fits it.
  factory Failure.from(Object error) {
    if (error is Failure) {
      return error;
    }
    if (error is FormatException) {
      return const CorruptionFailure();
    }
    if (error is ArgumentError) {
      return const ValidationFailure();
    }
    if (error is TimeoutException) {
      return const NetworkFailure();
    }
    return const ProviderFailure();
  }
}
