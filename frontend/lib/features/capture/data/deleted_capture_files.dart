import 'package:drift/drift.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/restore_deleted_row.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';
import 'package:tapture/core/time/clock.dart';

/// Shared database ownership checks for the photo and attachment repositories.
final class DeletedCaptureFiles {
  const DeletedCaptureFiles({
    required this.db,
    required this.reader,
    required this.clock,
    required this.deviceId,
    required this.ids,
  });
  final AppDatabase db;
  final FileReader reader;
  final Clock clock;
  final String deviceId;
  final IdService ids;

  Stream<List<DeletedEntity>> watchPhotos() => _watch(photos: true);
  Stream<List<DeletedEntity>> watchAttachments() => _watch(photos: false);

  Stream<List<DeletedEntity>> _watch({required bool photos}) {
    final String table = photos ? 'photos' : 'attachments';
    return db
        .customSelect(
          "SELECT f.id, f.project_id, p.name AS project_name, f.relative_path, ${photos ? 'f.original_filename AS name' : "f.kind AS kind"}, t.id AS deletion_id, t.deleted_at, t.reason FROM $table f JOIN projects p ON p.id = f.project_id JOIN tombstones t ON t.entity_type = '$table' AND t.entity_id = f.id WHERE $_liveProject AND ${photos ? _livePhotoParent : _liveAttachmentParent} ORDER BY t.deleted_at DESC, f.id",
          readsFrom: <TableInfo<dynamic, dynamic>>{
            db.projects,
            db.photos,
            db.attachments,
            db.attachmentOwners,
            db.records,
            db.tombstones,
          },
        )
        .watch()
        .map(
          (List<QueryRow> rows) => <DeletedEntity>[
            for (final QueryRow row in rows)
              DeletedEntity(
                id: row.read<String>('id'),
                kind: photos
                    ? DeletedEntityKind.photo
                    : row.read<String>('kind') == 'audio'
                    ? DeletedEntityKind.audio
                    : DeletedEntityKind.document,
                name: photos && row.read<String>('name').isNotEmpty
                    ? row.read<String>('name')
                    : row.read<String>('relative_path').split('/').last,
                projectId: row.read<String>('project_id'),
                projectName: row.read<String>('project_name'),
                deletedAt: row.read<DateTime>('deleted_at'),
                deletionId: row.read<String>('deletion_id'),
                reason: row.read<String>('reason'),
              ),
          ],
        );
  }

  Future<Result<void>> restorePhoto(String id) => _restore(id, photos: true);
  Future<Result<void>> restoreAttachment(String id) =>
      _restore(id, photos: false);

  Future<Result<void>> _restore(
    String id, {
    required bool photos,
  }) => runInTransaction(db, () async {
    final String table = photos ? 'photos' : 'attachments';
    final QueryRow? row = await db
        .customSelect(
          'SELECT f.id, f.relative_path, f.file_size, p.folder_name, ($_liveProject AND ${photos ? _livePhotoParent : _liveAttachmentParent}) AS parent_live FROM $table f JOIN projects p ON p.id = f.project_id WHERE f.id = ?',
          variables: <Variable<Object>>[Variable<String>(id)],
        )
        .getSingleOrNull();
    if (row == null) {
      throw StorageFailure(
        localizedMessage: Copy.messages.failureThatRowIsNoLongerOnThis,
        localizedRecovery: Copy.messages.failureRefreshTheListAndTryAgain,
      );
    }
    if (!row.read<bool>('parent_live')) {
      throw StorageFailure(
        localizedMessage: Copy.messages.recycleParentDeleted,
        localizedRecovery: Copy.messages.recycleParentDeletedRecovery,
      );
    }
    final String path =
        'projects/${row.read<String>('folder_name')}/${row.read<String>('relative_path')}';
    if ((await reader.length(path)).getOrThrow() !=
        row.read<int>('file_size')) {
      final StorageFailure unreadableFailure = FileReader.unreadable(path);
      throw unreadableFailure;
    }
    if (photos) {
      await restoreDeletedRow(
        db,
        table: db.photos,
        id: id,
        clock: clock,
        deviceId: deviceId,
        ids: ids,
      );
    } else {
      await restoreDeletedRow(
        db,
        table: db.attachments,
        id: id,
        clock: clock,
        deviceId: deviceId,
        ids: ids,
      );
    }
  });
}

const String _liveProject =
    "p.status <> 'deleted' AND NOT EXISTS (SELECT 1 FROM tombstones pt WHERE pt.entity_type = 'projects' AND pt.entity_id = p.id)";
const String _livePhotoParent =
    "(f.record_id IS NULL OR EXISTS (SELECT 1 FROM records r WHERE r.id = f.record_id AND r.status <> 'deleted' AND NOT EXISTS (SELECT 1 FROM tombstones rt WHERE rt.entity_type = 'records' AND rt.entity_id = r.id)))";
// A shared attachment remains recoverable when any owner is live. Unfiled
// project attachments have no owner links and remain independently recoverable.
const String _liveAttachmentParent =
    "(NOT EXISTS (SELECT 1 FROM attachment_owners o WHERE o.attachment_id = f.id) OR EXISTS (SELECT 1 FROM attachment_owners o WHERE o.attachment_id = f.id AND NOT EXISTS (SELECT 1 FROM tombstones ot WHERE ot.entity_type = 'attachment_owners' AND ot.entity_id = o.id) AND ((o.owner_type = 'record' AND EXISTS (SELECT 1 FROM records r WHERE r.id = o.owner_id AND r.status <> 'deleted' AND NOT EXISTS (SELECT 1 FROM tombstones rt WHERE rt.entity_type = 'records' AND rt.entity_id = r.id))) OR (o.owner_type = 'photo' AND EXISTS (SELECT 1 FROM photos ph WHERE ph.id = o.owner_id AND NOT EXISTS (SELECT 1 FROM tombstones ht WHERE ht.entity_type = 'photos' AND ht.entity_id = ph.id) AND (ph.record_id IS NULL OR EXISTS (SELECT 1 FROM records r WHERE r.id = ph.record_id AND r.status <> 'deleted' AND NOT EXISTS (SELECT 1 FROM tombstones rt WHERE rt.entity_type = 'records' AND rt.entity_id = r.id))))))))";
