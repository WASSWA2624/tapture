import 'package:tapture/core/errors/result.dart';

/// Removes stored location metadata through an audited project-scoped edit.
abstract interface class CoordinatePrivacyRepository {
  /// Returns the number of affected records after the transaction commits.
  Future<Result<int>> removeFromProject(String projectId);
}
