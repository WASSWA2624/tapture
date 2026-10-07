import 'dart:typed_data';

import 'package:tapture/core/errors/result.dart';

import 'attachment_repository.dart';
import 'document_draft.dart';

/// Validation and durable ownership of an imported original document.
abstract interface class CaptureDocumentRepository implements AttachmentRepository {
  /// Parses before writing, then stores bytes and attachment metadata.
  Future<Result<DocumentDraft>> import({
    required Uint8List bytes,
    required String filename,
    required String projectId,
    required String folder,
  });
}
