import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/attachments.dart';
import 'package:tapture/core/db/tables/audit_log.dart';
import 'package:tapture/core/db/tables/tombstones.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/hash/hashing_service.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/import/pdf_pages.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';
import 'package:tapture/core/time/clock.dart';

import '../domain/capture_document_format.dart';
import '../domain/capture_document_repository.dart';
import '../domain/document_draft.dart';
import 'deleted_capture_files.dart';

/// Stores untouched document originals; PDF pages are disposable derivatives.
final class CaptureDocumentRepositoryImpl implements CaptureDocumentRepository {
  /// Uses shared database, atomic writer, ids and real renderer.
  CaptureDocumentRepositoryImpl({
    required this._db,
    required this._writer,
    required this._reader,
    required this._pages,
    required this._ids,
    required this._clock,
    required this._deviceId,
  });
  final AppDatabase _db;
  final FileWriter _writer;
  final FileReader _reader;
  final PdfPages _pages;
  final IdService _ids;
  final Clock _clock;
  final String _deviceId;
  Future<void> _pending = Future<void>.value();

  DeletedCaptureFiles get _deleted => DeletedCaptureFiles(db: _db, reader: _reader, clock: _clock, deviceId: _deviceId, ids: _ids);

  @override
  Stream<List<DeletedEntity>> watchDeleted() => _deleted.watchAttachments();

  @override
  Future<Result<void>> restore(String id) => _deleted.restoreAttachment(id);

  @override
  Future<Result<DocumentDraft>> import({
    required Uint8List bytes,
    required String filename,
    required String projectId,
    required String folder,
  }) {
    final Future<Result<DocumentDraft>> result = _pending.then(
      (_) => _import(
        bytes: bytes,
        filename: filename,
        projectId: projectId,
        folder: folder,
      ),
    );
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<Result<DocumentDraft>> _import({
    required Uint8List bytes,
    required String filename,
    required String projectId,
    required String folder,
  }) async {
    try {
      final CaptureDocumentFormat format =
          (await CaptureDocumentFormat.validate(bytes, filename)).getOrThrow();
      final int? count = format == CaptureDocumentFormat.pdf
          ? (await _pages.pageCount(bytes)).getOrThrow()
          : null;
      final String hash = (await HashingService.sha256OfBytes(
        bytes,
      )).getOrThrow();
      final Attachment? existing =
          await (_db.select(_db.attachments)..where(
                ($AttachmentsTable row) =>
                    row.projectId.equals(projectId) & row.sha256.equals(hash),
              ))
              .getSingleOrNull();
      if (existing != null) {
        final String sourcePath = 'projects/$folder/${existing.relativePath}';
        final int? size = (await _reader.length(sourcePath)).getOrThrow();
        final bool missing = size != existing.fileSize;
        if (missing) {
          (await _writer.write(
            Stream<List<int>>.value(bytes),
            sourcePath,
          )).getOrThrow();
        }
        final bool deleted =
            await (_db.select(_db.tombstones)..where(
                  ($TombstonesTable row) =>
                      row.entityType.equals('attachments') &
                      row.entityId.equals(existing.id),
                ))
                .getSingleOrNull() !=
            null;
        if (missing || deleted) {
          await _db.transaction(() async {
            (await upsertAttachment(
              _db,
              row: AttachmentsCompanion(id: Value<String>(existing.id)),
              clock: _clock,
              deviceId: _deviceId,
              ids: _ids,
            )).getOrThrow();
            await removeTombstone(
              _db,
              entityType: 'attachments',
              entityId: existing.id,
            );
            await appendAudit(
              _db,
              entityType: 'attachments',
              entityId: existing.id,
              action: AuditAction.updated,
              fieldKey: 'restored',
              newValue: filename,
              clock: _clock,
              device: _deviceId,
            );
          });
        }
        final QueryRow? metadata = await _db
            .customSelect(
              'SELECT new_value FROM audit_log WHERE entity_type = ? AND entity_id = ? '
              'AND field_key = ? ORDER BY at DESC, id DESC LIMIT 1',
              variables: <Variable<Object>>[
                const Variable<String>('attachments'),
                Variable<String>(existing.id),
                const Variable<String>('originalFilename'),
              ],
            )
            .getSingleOrNull();
        return Success<DocumentDraft>(
          DocumentDraft(
            id: existing.id,
            projectId: projectId,
            relativePath: existing.relativePath,
            originalFilename:
                metadata?.readNullable<String>('new_value') ??
                existing.relativePath.split('/').last,
            sha256: existing.sha256,
            fileSize: existing.fileSize,
            pageCount: existing.pageCount ?? count,
            mimeType: existing.mimeType,
          ),
        );
      }
      final String id = _ids.newId();
      final String relativePath = 'documents/$id.${format.extension}';
      final WrittenFile written = (await _writer.write(
        Stream<List<int>>.value(bytes),
        'projects/$folder/$relativePath',
      )).getOrThrow();
      final DocumentDraft draft = DocumentDraft(
        id: id,
        projectId: projectId,
        relativePath: relativePath,
        originalFilename: filename,
        sha256: written.sha256,
        fileSize: written.byteLength,
        pageCount: count,
        mimeType: format.mimeType,
      );
      await _db.transaction(() async {
        (await upsertAttachment(
          _db,
          row: AttachmentsCompanion(
            id: Value<String>(id),
            projectId: Value<String>(projectId),
            relativePath: Value<String>(relativePath),
            mimeType: Value<String>(format.mimeType),
            fileSize: Value<int>(written.byteLength),
            sha256: Value<String>(written.sha256),
            kind: const Value<AttachmentKind>(AttachmentKind.document),
            pageCount: Value<int?>(count),
          ),
          clock: _clock,
          deviceId: _deviceId,
          ids: _ids,
        )).getOrThrow();
        await appendAudit(
          _db,
          entityType: 'attachments',
          entityId: id,
          action: AuditAction.created,
          fieldKey: 'originalFilename',
          newValue: filename,
          clock: _clock,
          device: _deviceId,
        );
      });
      return Success<DocumentDraft>(draft);
    } on Object catch (error) {
      return FailureResult<DocumentDraft>(
        error is Failure ? error : storageFailureFrom(error),
      );
    }
  }
}
