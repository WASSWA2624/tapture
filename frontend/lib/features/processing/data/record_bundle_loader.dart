import 'package:drift/drift.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/attachment_owners.dart';
import 'package:tapture/core/db/tables/attachments.dart';
import 'package:tapture/core/errors/failure.dart';

import 'record_bundle.dart';

/// Reads a [RecordBundle] for one record.
final class RecordBundleLoader {
  /// Creates a loader over [db].
  const RecordBundleLoader({required this._db});

  final AppDatabase _db;

  /// Loads the record [recordId] with its project, template and evidence.
  ///
  /// Throws a [StorageFailure] when the record is gone and a
  /// [ValidationFailure] when its project or template is missing.
  Future<RecordBundle> load(String recordId) async {
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
          await (_db.select(_db.photos)
                ..where(
                  ($PhotosTable table) => table.recordId.equals(record.id),
                )
                ..orderBy(<OrderClauseGenerator<$PhotosTable>>[
                  ($PhotosTable table) => OrderingTerm.asc(table.sortOrder),
                ]))
              .get(),
      captions:
          await (_db.select(_db.captions)..where(
                ($CaptionsTable table) =>
                    (table.ownerId.equals(record.id)) |
                    table.ownerId.isInQuery(
                      _db.selectOnly(_db.photos)
                        ..addColumns(<Expression<Object>>[_db.photos.id])
                        ..where(_db.photos.recordId.equals(record.id)),
                    ),
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
      existing:
          await (_db.select(_db.recordFields)..where(
                ($RecordFieldsTable table) => table.recordId.equals(record.id),
              ))
              .get(),
    );
  }
}
