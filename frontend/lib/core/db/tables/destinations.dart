import 'package:drift/drift.dart';

import '../columns.dart';

/// A cloud destination the operator configured (task 021).
///
/// [credentialRef] is an opaque handle. The secret value is never a column.
@DataClassName('DestinationRow')
class Destinations extends Table with MergeColumns {
  /// [DestinationKind.name].
  TextColumn get kind => text()();

  /// Name the operator gave this destination.
  TextColumn get label => text()();

  /// Remote folder, bucket prefix, or device-relative path.
  TextColumn get folder => text()();

  /// Handle of the credential in secure storage.
  TextColumn get credentialRef => text()();

  /// Plain-language outcome of the last connection check, when one has run.
  TextColumn get lastCheck => text().nullable()();
}
