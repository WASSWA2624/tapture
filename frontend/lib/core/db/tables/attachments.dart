import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/base_dao.dart';
import 'package:tapture/core/db/columns.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';

/// A document or audio file hanging off a project. Unique on [projectId]
/// plus [sha256].
///
/// [relativePath] is stored relative to the project folder. [sha256] is
/// written once at insert.
class Attachments extends Table with MergeColumns {
  /// Project this file belongs to.
  TextColumn get projectId => text()();

  /// Path relative to the project folder.
  TextColumn get relativePath => text()();

  /// MIME type of the stored file.
  TextColumn get mimeType => text()();

  /// Size of the stored file in bytes.
  IntColumn get fileSize => integer()();

  /// Content hash. Merge identity for the file.
  TextColumn get sha256 => text()();

  /// Document or audio.
  TextColumn get kind => textEnum<AttachmentKind>()();

  /// Duration for audio, in milliseconds.
  IntColumn get durationMs => integer().nullable()();

  /// Page count for documents, when the format reports one.
  IntColumn get pageCount => integer().nullable()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{projectId, sha256},
  ];
}

/// Whether an [Attachment] is a document or an audio clip.
enum AttachmentKind {
  /// A PDF or other document.
  document,

  /// A recorded or imported audio clip.
  audio,
}

/// Inserts or updates an attachment. A second row with the same project and
/// hash is refused by the unique index, not by a check in this function.
Future<Result<Attachment>> upsertAttachment(
  GeneratedDatabase db, {
  required Insertable<Attachment> row,
  required Clock clock,
  required String deviceId,
  required IdService ids,
}) async {
  try {
    _ensureRelativePath(row);
    final AppDatabase database = db as AppDatabase;
    final _AttachmentsDao dao = _AttachmentsDao(
      database,
      clock: clock,
      deviceId: deviceId,
      ids: ids,
    );
    final Map<String, Expression<Object>> columns =
        Map<String, Expression<Object>>.of(row.toColumns(false));
    final String? id = _idOf(row);
    final Attachment? existing = id == null
        ? null
        : (await dao.getById(id)).fold(
            (Failure failure) => throw failure,
            (Attachment? value) => value,
          );
    if (existing != null) {
      columns.remove('sha256');
    }
    return dao.upsert(RawValuesInsertable<Attachment>(columns));
  } on Failure catch (failure) {
    return FailureResult<Attachment>(failure);
  } on Object catch (error) {
    return FailureResult<Attachment>(storageFailureFrom(error));
  }
}

void _ensureRelativePath(Insertable<Attachment> row) {
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

String? _idOf(Insertable<Attachment> row) {
  final Expression<Object>? expression = row.toColumns(false)['id'];
  if (expression is Variable<String>) {
    return expression.value;
  }
  return null;
}

final class _AttachmentsDao extends BaseDao<Attachments, Attachment> {
  _AttachmentsDao(
    AppDatabase super.db, {
    required super.clock,
    required super.deviceId,
    required super.ids,
  }) : super(table: db.attachments);
}
