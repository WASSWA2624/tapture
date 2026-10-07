import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/lifecycle/deleted_entity.dart';
import 'package:tapture/features/capture/domain/capture_document_repository.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/document_draft.dart';
import 'package:tapture/features/capture/presentation/capture_controller.dart';

void main() {
  test(
    'document intent waits for durable import then checkpoints the original',
    () async {
      final Completer<Result<DocumentDraft>> imported =
          Completer<Result<DocumentDraft>>();
      final _Documents documents = _Documents(imported.future);
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          captureDocumentRepositoryProvider.overrideWith((Ref _) => documents),
        ],
      );
      addTearDown(container.dispose);
      final CaptureController controller = container.read(
        captureControllerProvider('p1').notifier,
      );
      final Uint8List bytes = Uint8List.fromList(<int>[1, 2, 3]);
      final Future<Result<void>> result = controller.importDocument(
        bytes: bytes,
        filename: 'Survey.pdf',
        projectId: 'p1',
        folder: 'site',
      );
      expect(controller.state.documents, isEmpty);
      expect(documents.received, (
        bytes: bytes,
        filename: 'Survey.pdf',
        projectId: 'p1',
        folder: 'site',
      ));
      imported.complete(const Success<DocumentDraft>(_document));
      expect(await result, isA<Success<void>>());
      expect(controller.state.documents.single, same(_document));
      final Success<CaptureSession?> restored =
          await container.read(capturePersistenceProvider).loadSession('p1')
              as Success<CaptureSession?>;
      expect(restored.value!.documents.single.toJson(), _document.toJson());
    },
  );

  test(
    'failed document import preserves the original failure and draft',
    () async {
      const ValidationFailure failure = ValidationFailure(
        message: 'Unreadable PDF',
        recoveryAction: 'Choose a complete file',
      );
      final _Documents documents = _Documents(
        Future<Result<DocumentDraft>>.value(
          const FailureResult<DocumentDraft>(failure),
        ),
      );
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          captureDocumentRepositoryProvider.overrideWith((Ref _) => documents),
        ],
      );
      addTearDown(container.dispose);
      final CaptureController controller = container.read(
        captureControllerProvider('p1').notifier,
      );
      final CaptureSession before = controller.state;
      final Result<void> result = await controller.importDocument(
        bytes: Uint8List(0),
        filename: 'broken.pdf',
        projectId: 'p1',
        folder: 'site',
      );
      expect((result as FailureResult<void>).failure, same(failure));
      expect(controller.state, same(before));
    },
  );

  test(
    'unavailable document storage cannot publish a draft attachment',
    () async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final CaptureController controller = container.read(
        captureControllerProvider('p1').notifier,
      );
      expect(
        await controller.importDocument(
          bytes: Uint8List(0),
          filename: 'Survey.pdf',
          projectId: 'p1',
          folder: 'site',
        ),
        isA<FailureResult<void>>(),
      );
      expect(controller.state.documents, isEmpty);
    },
  );
}

const DocumentDraft _document = DocumentDraft(
  id: 'document-1',
  projectId: 'p1',
  relativePath: 'documents/original.pdf',
  originalFilename: 'Survey.pdf',
  sha256: 'original-hash',
  fileSize: 3,
  pageCount: 20,
);

final class _Documents implements CaptureDocumentRepository {
  @override
  Stream<List<DeletedEntity>> watchDeleted() => Stream<List<DeletedEntity>>.value(const <DeletedEntity>[]);

  @override
  Future<Result<void>> restore(String id) async => const Success<void>(null);

  _Documents(this._result);
  final Future<Result<DocumentDraft>> _result;
  ({Uint8List bytes, String filename, String projectId, String folder})?
  received;
  @override
  Future<Result<DocumentDraft>> import({
    required Uint8List bytes,
    required String filename,
    required String projectId,
    required String folder,
  }) {
    received = (
      bytes: bytes,
      filename: filename,
      projectId: projectId,
      folder: folder,
    );
    return _result;
  }
}
