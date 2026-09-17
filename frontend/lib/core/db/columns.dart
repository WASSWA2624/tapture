import 'package:drift/drift.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

/// The type this file is named for (FE-STR-06). The contract name is
/// [MergeColumns].
typedef Columns = MergeColumns;

final IdService _ids = UuidV7Service(const SystemClock());

/// Time-ordered UUIDv7 text for a new row id. Never an autoincrement integer.
String uuidV7() => _ids.newId();

/// Identity, timestamps, device stamp and revision every table reuses.
///
/// Later table tasks mix this in; they never declare `id`, `createdAt`,
/// `updatedAt`, `updatedByDevice` or `rev` by hand.
mixin MergeColumns on Table {
  /// Merge identity. Minted as UUIDv7 text when the insert omits it.
  TextColumn get id => text().clientDefault(uuidV7)();

  /// When the row was first written. Later updates leave this alone.
  DateTimeColumn get createdAt => dateTime()();

  /// When the row last changed. The write helper advances this.
  DateTimeColumn get updatedAt => dateTime()();

  /// Device that last wrote the row.
  TextColumn get updatedByDevice => text()();

  /// Monotonic write counter. The write helper adds one on every update.
  IntColumn get rev => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
