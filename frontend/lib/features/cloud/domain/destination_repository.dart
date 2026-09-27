import 'package:tapture/core/cloud/cloud_destination.dart';
import 'package:tapture/core/errors/result.dart';

/// Persistence for configured destinations (task 021).
///
/// Signatures stay free of Drift. [remove] deletes the row and its secret
/// together. A half-finished removal names which half is still there.
abstract interface class DestinationRepository {
  /// Every saved destination, label order.
  Stream<List<Destination>> watchAll();

  /// Inserts or updates [destination]. The credential value is not a field.
  Future<Result<void>> save(Destination destination);

  /// Deletes [id] and the secret stored under its credential ref.
  Future<Result<void>> remove(String id);
}
