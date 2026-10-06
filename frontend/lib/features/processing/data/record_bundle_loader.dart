import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/attachment_owners.dart';
import 'package:tapture/core/db/tables/attachments.dart';
import 'package:tapture/core/db/tables/photos.dart';
import 'package:tapture/core/db/transactions.dart';
import 'package:tapture/core/errors/failure.dart';

import 'record_bundle.dart';

/// SQL condition on a `captions` row: true while it is not tombstoned.
const String _liveCaption =
    "NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = 'captions' "
    'AND t.entity_id = captions.id)';

/// Reads a [RecordBundle] for one record.
final class RecordBundleLoader {
  /// Creates a loader over [db].
  const RecordBundleLoader({required this._db});

  final AppDatabase _db;

  /// Loads the record [recordId] with its project, template and evidence.
  ///
  /// Evidence is what the record shows now: photos by `activePhotoCondition`
  /// (not tombstoned, not replaced by a live edited copy) in tray order, and
  /// the untombstoned captions of the record and of those photos.
  ///
  /// Throws a [StorageFailure] when the record is gone and a
  /// [ValidationFailure] when its project or template is missing.
  Future<RecordBundle> load(String recordId) async {
    try {
      return await _load(recordId);
    } on Failure {
      rethrow;
    } on Object catch (error) {
      throw Failure.from(storageFailureFrom(error));
    }
  }

  Future<RecordBundle> _load(String recordId) async {
    final RecordRow? record =
        await (_db.select(_db.records)
              ..where(($RecordsTable table) => table.id.equals(recordId)))
            .getSingleOrNull();
    if (record == null) {
      throw const StorageFailure(
        message: 'That record is no longer on this device.',
        recoveryAction: 'Refresh the queue and try again.',
      );
    }
    final Project? project =
        await (_db.select(_db.projects)..where(
              ($ProjectsTable table) => table.id.equals(record.projectId),
            ))
            .getSingleOrNull();
    final Template? template =
        await (_db.select(_db.templates)..where(
              ($TemplatesTable table) => table.id.equals(record.templateId),
            ))
            .getSingleOrNull();
    if (project == null || template == null) {
      throw const ValidationFailure(
        message: 'This record is missing its project or template.',
        recoveryAction: 'Restore it, then retry processing.',
      );
    }
    final List<AttachmentOwner> audioOwners =
        await (_db.select(_db.attachmentOwners)..where(
              ($AttachmentOwnersTable table) =>
                  table.ownerType.equalsValue(AttachmentOwnerType.record) &
                  table.ownerId.equals(record.id),
            ))
            .get();
    final List<String> attachmentIds = <String>[
      for (final AttachmentOwner owner in audioOwners) owner.attachmentId,
    ];
    final List<AttachmentOwner> photoAudioOwners = attachmentIds.isEmpty
        ? const <AttachmentOwner>[]
        : await (_db.select(_db.attachmentOwners)..where(
                ($AttachmentOwnersTable table) =>
                    table.attachmentId.isIn(attachmentIds) &
                    table.ownerType.equalsValue(AttachmentOwnerType.photo),
              ))
              .get();
    final List<TranscriptRow> transcripts = attachmentIds.isEmpty
        ? const <TranscriptRow>[]
        : await (_db.select(_db.transcripts)..where(
                ($TranscriptsTable table) =>
                    table.attachmentId.isIn(attachmentIds) &
                    table.status.equals('complete') &
                    const CustomExpression<bool>(
                      "NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = 'transcripts' AND t.entity_id = transcripts.id)",
                    ),
              ))
              .get();
    // Only the photos the record shows now: a removed photo, or an original
    // replaced by its edited copy, is never read again, so re-processing
    // cannot link fresh evidence to it (task 014 step 5).
    final $PhotosTable live = _db.alias(_db.photos, 'p');
    final Expression<bool> shown =
        live.recordId.equals(record.id) &
        const CustomExpression<bool>(activePhotoCondition);
    return RecordBundle(
      record: record,
      project: project,
      template: template,
      fields:
          await (_db.select(_db.templateFields)
                ..where(
                  ($TemplateFieldsTable table) =>
                      table.templateId.equals(template.id),
                )
                ..orderBy(<OrderClauseGenerator<$TemplateFieldsTable>>[
                  ($TemplateFieldsTable table) =>
                      OrderingTerm.asc(table.sortOrder),
                ]))
              .get(),
      rows:
          await (_db.select(_db.templateRows)..where(
                ($TemplateRowsTable table) =>
                    table.templateId.equals(template.id),
              ))
              .get(),
      photos:
          await (_db.select(live)
                ..where(($PhotosTable _) => shown)
                ..orderBy(<OrderClauseGenerator<$PhotosTable>>[
                  ($PhotosTable table) => OrderingTerm.asc(table.sortOrder),
                ]))
              .get(),
      captions:
          await (_db.select(_db.captions)..where(
                ($CaptionsTable table) =>
                    const CustomExpression<bool>(_liveCaption) &
                    (table.ownerId.equals(record.id) |
                        table.ownerId.isInQuery(
                          _db.selectOnly(live)
                            ..addColumns(<Expression<Object>>[live.id])
                            ..where(shown),
                        )),
              ))
              .get(),
      audio: attachmentIds.isEmpty
          ? const <Attachment>[]
          : await (_db.select(_db.attachments)..where(
                  ($AttachmentsTable table) =>
                      table.id.isIn(attachmentIds) &
                      table.kind.equalsValue(AttachmentKind.audio),
                ))
                .get(),
      audioPhotoIds: <String, List<String>>{
        for (final String id in attachmentIds)
          id: <String>[
            for (final AttachmentOwner owner in photoAudioOwners)
              if (owner.attachmentId == id) owner.ownerId,
          ]..sort(),
      },
      deviceTranscripts: transcripts,
      transcriptSegments: transcripts.isEmpty
          ? const <TranscriptSegmentRow>[]
          : await (_db.select(_db.transcriptSegments)..where(
                  ($TranscriptSegmentsTable table) => table.transcriptId.isIn(
                    transcripts.map((TranscriptRow row) => row.id),
                  ),
                ))
                .get(),
      existing:
          await (_db.select(_db.recordFields)..where(
                ($RecordFieldsTable table) => table.recordId.equals(record.id),
              ))
              .get(),
    );
  }
}
