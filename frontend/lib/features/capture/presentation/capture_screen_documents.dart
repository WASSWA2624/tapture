part of 'capture_screen.dart';

extension _CaptureDocuments on _CaptureScreenState {
  Future<void> _documentImported(
    Project project,
    Uint8List bytes,
    String name,
  ) async {
    final String key = _sessionKey();
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
