import 'package:tapture/core/errors/result.dart';

import 'operator_profile.dart';

/// Where the local operator identity is kept: the single device-profile
/// row (task 007 step 1). Presentation reads and saves through this and
/// never sees a database row (FE-STR-03, FE-STATE-05).
abstract interface class OperatorProfileRepository {
  /// The stored operator. Empty fields when none has been saved yet; a
  /// failure only when the row cannot be read.
  Future<Result<OperatorProfile>> load();

  /// Writes [profile] onto the row, keeping every other stored preference.
  Future<Result<OperatorProfile>> save(OperatorProfile profile);
}
