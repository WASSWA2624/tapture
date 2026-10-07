import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';
import 'package:tapture/features/capture/domain/capture_document_repository.dart';
import 'package:tapture/features/capture/domain/document_draft.dart';

void main() {
  test('the document import port returns durable source metadata', () async {
    const DocumentDraft draft = DocumentDraft(
      id: 'document-a',
      projectId: 'project-a',
      relativePath: 'documents/document-a.pdf',
      originalFilename: 'Original.PDF',
      sha256: 'source-sha',
      fileSize: 120,
      pageCount: 2,
    );
    final _DocumentRepository fake = _DocumentRepository(
      const Success<DocumentDraft>(draft),
    );
    final CaptureDocumentRepository repository = fake;
    final Uint8List bytes = Uint8List.fromList('%PDF-original'.codeUnits);
    final Result<DocumentDraft> result = await repository.import(
      bytes: bytes,
      filename: 'Original.PDF',
      projectId: 'project-a',
      folder: 'project-folder',
    );
    expect((result as Success<DocumentDraft>).value, same(draft));
    expect(fake.received, (
      bytes: bytes,
      filename: 'Original.PDF',
      projectId: 'project-a',
      folder: 'project-folder',
    ));
  });

  test(
    'the document import port exposes a typed refusal without a draft',
    () async {
      const StorageFailure failure = StorageFailure(
        message: 'The original could not be stored.',
        recoveryAction: 'Free space and try again.',
      );
      final CaptureDocumentRepository repository = _DocumentRepository(
        const FailureResult<DocumentDraft>(failure),
      );
      final Result<DocumentDraft> result = await repository.import(
        bytes: Uint8List(0),
        filename: 'Original.PDF',
        projectId: 'project-a',
        folder: 'project-folder',
      );
      expect((result as FailureResult<DocumentDraft>).failure, same(failure));
    },
  );
}

final class _DocumentRepository implements CaptureDocumentRepository {
  @override
  Stream<List<DeletedEntity>> watchDeleted() => Stream<List<DeletedEntity>>.value(const <DeletedEntity>[]);

  @override
  Future<Result<void>> restore(String id) async => const Success<void>(null);

  _DocumentRepository(this.result);
  final Result<DocumentDraft> result;
  ({Uint8List bytes, String filename, String projectId, String folder})?
  received;

  @override
  Future<Result<DocumentDraft>> import({
    required Uint8List bytes,
    required String filename,
    required String projectId,
    required String folder,
  }) async {
    received = (
      bytes: bytes,
      filename: filename,
      projectId: projectId,
      folder: folder,
    );
    return result;
  }
}
