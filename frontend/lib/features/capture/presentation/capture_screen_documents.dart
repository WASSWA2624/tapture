part of 'capture_screen.dart';

extension _CaptureDocuments on _CaptureScreenState {
  Future<void> _documentImported(
    Project project,
    Uint8List bytes,
    String name, {
    String? sessionKey,
  }) async {
    final String key = sessionKey ?? _sessionKey();
    final Result<void> stored = await ref
        .read(captureControllerProvider(key).notifier)
        .importDocument(
          bytes: bytes,
          filename: name,
          projectId: project.id,
          folder: project.folderName,
        );
    if (!mounted) return;
    if (stored case FailureResult<void>(:final Failure failure)) {
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
    }
  }

  Future<void> _importDocument(Project project, String key) async {
    final Result<void> imported = await ImportCaptureDocument.run(
      picker: ref.read(platform.documentPickerProvider),
      onImported: (Uint8List bytes, String name) async {
        if (mounted) {
          await _documentImported(project, bytes, name, sessionKey: key);
        }
      },
    );
    if (!mounted) return;
    if (imported case FailureResult<void>(
      :final Failure failure,
    ) when failure is! CancelledFailure) {
      final LocalizedCopy localCopy = Copy.of(context);
      showAppSnack(
        context,
        localCopy.captureImportRejected(localCopy.resolve(failure.explanation)),
        tone: SnackTone.warning,
      );
    }
  }

  Future<void> _openDocument(Project project, DocumentDraft document) async {
    if (!document.canRenderPages) return;
    final String key = _sessionKey();
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CaptureDocumentViewer(
          document: document,
          folder: project.folderName,
          onAddPage: (Uint8List bytes) async {
            final Result<PhotoDraft> stored = await CapturePhotoIntake.store(
              ref,
              sessionKey: key,
              projectId: project.id,
              bytes: bytes,
            );
            if (stored case FailureResult<PhotoDraft>(:final Failure failure)) {
              return FailureResult<void>(failure);
            }
            if (mounted) {
              showAppSnack(
                context,
                Copy.of(context).captureAddPhoto,
                tone: SnackTone.success,
              );
            }
            return const Success<void>(null);
          },
        ),
      ),
    );
  }
}
