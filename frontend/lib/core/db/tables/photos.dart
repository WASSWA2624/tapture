import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

/// Captured image metadata. Unique on [projectId] plus [sha256].
///
/// [recordId] is null for unfiled captures. [relativePath] is stored relative
/// to the project folder so the tree survives a move of the storage root.
/// [sha256] and [capturedAt] are written once at insert.
class Photos extends Table with MergeColumns {
  /// Project this file belongs to.
  TextColumn get projectId => text()();

  /// Record this photo is filed on, or null while it is still unfiled.
  TextColumn get recordId => text().nullable()();

  /// Capture session that produced the file.
  TextColumn get captureSessionId => text()();

  /// Filename as imported or captured, stored as data.
  TextColumn get originalFilename => text()();

  /// Filename under the project folder.
  TextColumn get storedFilename => text()();

  /// Path relative to the project folder.
  TextColumn get relativePath => text()();

  /// Photo type name, stored as text so this table does not import Flutter.
  TextColumn get photoType => text()();

  /// Order within the record or session.
  IntColumn get sortOrder => integer()();

  /// Pixel width of the stored file.
  IntColumn get width => integer()();

  /// Pixel height of the stored file.
  IntColumn get height => integer()();

  /// Size of the stored file in bytes.
  IntColumn get fileSize => integer()();

  /// MIME type of the stored file.
  TextColumn get mimeType => text()();

  /// Content hash. Merge identity for the file.
  TextColumn get sha256 => text()();

  /// When the photo was captured. Written once at insert.
  DateTimeColumn get capturedAt => dateTime()();

  /// GPS latitude at capture, when location recording is on.
  RealColumn get gpsLat => real().nullable()();

  /// GPS longitude at capture, when location recording is on.
  RealColumn get gpsLon => real().nullable()();

  /// Parent photo when this row is an edit. Null marks an original.
  TextColumn get derivedFrom => text().nullable()();

  /// Display rotation in degrees. Null is the original orientation.
  IntColumn get rotationDegrees => integer().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{projectId, sha256},
  ];
}

/// Inserts or updates a photo. A second row with the same project and hash is
/// refused by the unique index, not by a check in this function.
Future<Result<Photo>> upsertPhoto(
  GeneratedDatabase db, {
  required Insertable<Photo> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    _ensureRelativePath(row);
    final AppDatabase database = db as AppDatabase;
    final _PhotosDao dao = _PhotosDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    );
    final Map<String, Expression<Object>> columns =
        Map<String, Expression<Object>>.of(row.toColumns(false));
    final String? id = _idOf(row);
    final Photo? existing = id == null
        ? null
        : (await dao.getById(
            id,
          )).fold((Failure failure) => throw failure, (Photo? value) => value);
    if (existing != null) {
      columns.remove('sha256');
      columns.remove('captured_at');
    }
    return dao.upsert(RawValuesInsertable<Photo>(columns));
  } on Failure catch (failure) {
    return FailureResult<Photo>(failure);
  } on Object catch (error) {
    return FailureResult<Photo>(storageFailureFrom(error));
  }
}

void _ensureRelativePath(Insertable<Photo> row) {
  final Expression<Object>? expression = row.toColumns(false)['relative_path'];
  if (expression is! Variable<String>) {
    return;
  }
  final String? path = expression.value;
  if (path == null) {
    return;
  }
  if (path.isEmpty || _isAbsolutePath(path)) {
    throw const StorageFailure(
      message: 'The file path must stay inside the project folder.',
      recoveryAction: 'Save the file under the project folder and try again.',
    );
  }
}

bool _isAbsolutePath(String path) {
  if (path.startsWith('/') || path.startsWith(r'\')) {
    return true;
  }
  return path.length >= 2 && path[1] == ':';
}

String? _idOf(Insertable<Photo> row) {
  final Expression<Object>? expression = row.toColumns(false)['id'];
  if (expression is Variable<String>) {
    return expression.value;
  }
  return null;
}

final class _PhotosDao extends BaseDao<Photos, Photo> {
  _PhotosDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.photos);
}
