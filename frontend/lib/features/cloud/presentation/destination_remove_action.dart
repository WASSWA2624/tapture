import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/destination_repository.dart';

/// Removes a destination only after the person confirms.
///
/// The repository tombstones the row and forgets the secret together.
/// Cancelling leaves both in place.
final class DestinationRemoveAction {
  /// Deletes [id] when [confirmed] is true.
  static Future<Result<void>> apply({
    required DestinationRepository repository,
    required String id,
    required bool confirmed,
  }) {
    if (!confirmed) {
      return Future<Result<void>>.value(
        const FailureResult<void>(
          CancelledFailure(
            message: 'The destination was kept.',
            recoveryAction: 'Remove it later if you still want to.',
          ),
        ),
      );
    }
    return repository.remove(id);
  }
}
