part of 'capture_record_writer.dart';

extension _CaptureRecordDocuments on CaptureRecordWriter {
  Future<void> _fileDocument(
    DocumentDraft document, {
    required String recordId,
    required int index,
    required DateTime now,
  }) async {
    _expect(
      await upsertAttachment(
        _db,
        row: sqlite.AttachmentsCompanion(
          id: Value<String>(document.id),
          projectId: Value<String>(document.projectId),
          relativePath: Value<String>(document.relativePath),
          mimeType: Value<String>(document.mimeType),
          fileSize: Value<int>(document.fileSize),
          sha256: Value<String>(document.sha256),
          kind: const Value<AttachmentKind>(AttachmentKind.document),
          pageCount: Value<int?>(document.pageCount),
        ),
        clock: _clock,
        deviceId: _deviceId,
        ids: _ids,
      ),
    );
    await _linkAttachment(
      attachmentId: document.id,
      ownerType: AttachmentOwnerType.record,
      ownerId: recordId,
      sortOrder: index,
      now: now,
    );
  }

  Future<List<DocumentDraft>> _documents(String recordId) async {
    final List<QueryRow> rows = await _db
        .customSelect(
          'SELECT a.*, (SELECT l.new_value FROM audit_log l WHERE l.entity_type = ? '
          'AND l.entity_id = a.id AND l.field_key = ? ORDER BY l.at DESC, l.id DESC LIMIT 1) AS original_filename '
          'FROM attachments a INNER JOIN attachment_owners o ON o.attachment_id = a.id '
          'WHERE o.owner_type = ? AND o.owner_id = ? AND a.kind = ? '
          'AND NOT EXISTS (SELECT 1 FROM tombstones t WHERE t.entity_type = ? AND t.entity_id = a.id) '
          'ORDER BY o.sort_order',
          variables: <Variable<Object>>[
            const Variable<String>('attachments'),
            const Variable<String>('originalFilename'),
            const Variable<String>('record'),
            Variable<String>(recordId),
            const Variable<String>('document'),
            const Variable<String>('attachments'),
          ],
        )
        .get();
    return <DocumentDraft>[
      for (final QueryRow row in rows)
        DocumentDraft(
          id: row.read<String>('id'),
          projectId: row.read<String>('project_id'),
          relativePath: row.read<String>('relative_path'),
          originalFilename:
              row.readNullable<String>('original_filename') ??
              row.read<String>('relative_path').split('/').last,
          mimeType: row.read<String>('mime_type'),
          sha256: row.read<String>('sha256'),
          fileSize: row.read<int>('file_size'),
          pageCount:
              row.readNullable<int>('page_count') ??
              (row.read<String>('mime_type') == 'application/pdf' ? 1 : null),
        ),
    ];
  }
}
