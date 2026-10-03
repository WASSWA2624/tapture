import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';

import '../domain/destination_repository.dart';

/// Removes a destination only after the person confirms.
///
/// [destinations] tombstones the row and forgets the secret together, and a
/// half-finished removal comes back as a failure naming the half that
/// remains. Cancelling leaves both in place.
final class DestinationRemoveAction {
  /// Deletes [id] from [destinations] when [confirmed] is true.
  static Future<Result<void>> apply({
    required DestinationRepository destinations,
    required String id,
    required bool confirmed,
  }) async {
    if (!confirmed) {
      return FailureResult<void>(
        CancelledFailure(
          message: Copy.destinationKept,
          localizedMessage: Copy.messages.destinationKept,
          recoveryAction: Copy.destinationKeptRecovery,
          localizedRecovery: Copy.messages.destinationKeptRecovery,
        ),
      );
    }
    return destinations.remove(id);
  }
}
