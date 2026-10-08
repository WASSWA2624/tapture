import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';

part 'probe_database.g.dart';

/// In-memory table used to exercise [MergeColumns] and [BaseDao].
class ProbeRows extends Table with MergeColumns {
  /// A unique payload so uniqueness mapping can be hit through [BaseDao].
  TextColumn get label => text().unique()();
}

/// Generated database holding only [ProbeRows].
@DriftDatabase(tables: <Type>[ProbeRows])
class ProbeDatabase extends _$ProbeDatabase {
  /// In-memory connection. Tests never touch the on-disk file.
  ProbeDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;
}

/// [BaseDao] bound to [ProbeRows].
final class ProbeDao extends BaseDao<ProbeRows, ProbeRow> {
  /// Creates a DAO against [db].
  ProbeDao(
    ProbeDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.probeRows);
}
