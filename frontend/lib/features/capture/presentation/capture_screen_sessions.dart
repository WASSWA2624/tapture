part of 'capture_screen.dart';

/// The capture page's session flows: offering an interrupted session back
/// before anything writes to it, keeping the session for the next visit,
/// the saves, and pinning a template to a place (task 012 steps 17 to 22).
extension _CaptureSessionFlows on _CaptureScreenState {
  /// Checks the stored copy of session [key] and offers an interrupted one
  /// back, then lets the page write to the session. Until the operator
  /// answers, nothing on the page stores a change, so the interrupted copy
  /// is never overwritten (task 012 step 19, task 073).
  Future<void> _restore(String key) async {
    if (_editing) {
      await _restoreEdit();
    } else {
      await _restoreCapture(key);
    }
    if (mounted) {
      ref.read(_captureUiProvider(key).notifier).checked();
    }
  }

  Future<void> _restoreCapture(String key) async {
    final CaptureController controller = ref.read(
      captureControllerProvider(key).notifier,
    );
    final CaptureSession? stored = await controller.interrupted();
    if (stored == null || !mounted) {
      return;
    }
    final CaptureRecoveryChoice choice = await CaptureRecoveryPrompt.show(
      context,
      photoCount: stored.photos.length,
    );
    if (!mounted) {
      return;
    }
    switch (choice) {
      case CaptureRecoveryChoice.resume:
        await _resume(controller, stored);
      case CaptureRecoveryChoice.discard:
        await _discard(controller, stored);
    }
  }

  /// Offers a stored, changed edit of this record, and otherwise loads the
  /// record as it is saved now.
  Future<void> _restoreEdit() async {
    final String recordId = widget.recordId!;
    final CaptureController controller = ref.read(
      captureControllerProvider(_sessionKey()).notifier,
    );
    final CaptureSession? interrupted = await controller.interrupted();
    if (!mounted) {
      return;
    }
    if (interrupted == null) {
      await _loadRecord(recordId);
      return;
    }
    final CaptureRecoveryChoice choice = await CaptureRecoveryPrompt.show(
      context,
      photoCount: interrupted.photos.length,
    );
    if (!mounted) {
      return;
    }
    switch (choice) {
      case CaptureRecoveryChoice.resume:
        await _resume(controller, interrupted);
      case CaptureRecoveryChoice.discard:
        await controller.replaceSession(interrupted);
        await _discard(controller, interrupted);
        if (mounted) {
          await _loadRecord(recordId);
        }
    }
  }

  /// Makes [interrupted] the live session again, photos, captions and
  /// values as they were.
  Future<void> _resume(
    CaptureController controller,
    CaptureSession interrupted,
  ) async {
    final Result<void> resumed = await controller.replaceSession(interrupted);
    if (!mounted) {
      return;
    }
    switch (resumed) {
      case FailureResult<void>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      case Success<void>():
        final Result<void> recovered = await controller.finaliseAudio();
        if (!mounted) return;
        if (recovered case FailureResult<void>(:final Failure failure)) {
          showAppSnack(
            context,
            failure.message,
            tone: SnackTone.error,
            localizedMessage: failure.explanation,
          );
        }
        await _refreshThumbs(_activePhotos(interrupted));
    }
  }

  /// Tombstones [interrupted]'s photos, keeping them and their files
  /// recoverable, and offers the session back through Undo rather than a
  /// second confirmation. A discard that fails keeps the session in the
  /// tray (FE-SIMP-09).
  Future<void> _discard(
    CaptureController controller,
    CaptureSession interrupted,
  ) async {
    final Result<void> discarded = await controller.discardSession(
      interrupted: interrupted,
    );
    if (!mounted) {
      return;
    }
    if (discarded case FailureResult<void>(:final Failure failure)) {
      showAppSnack(
        context,
        failure.message,
        tone: SnackTone.error,
        localizedMessage: failure.explanation,
      );
      await _resume(controller, interrupted);
      return;
    }
    showAppSnack(
      context,
      Copy.of(context).captureSessionDiscarded,
      undoLabel: Copy.of(context).undo,
      onUndo: () => unawaited(_undoDiscard(controller, interrupted)),
    );
  }

  Future<void> _undoDiscard(
    CaptureController controller,
    CaptureSession interrupted,
  ) async {
    final Result<void> restored = await controller.restoreDiscarded(
      interrupted,
    );
    if (!mounted) {
      return;
    }
    switch (restored) {
      case FailureResult<void>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      case Success<void>():
        await _refreshThumbs(_activePhotos(interrupted));
    }
  }

  Future<void> _loadRecord(String recordId) async {
    final Result<void> loaded = await ref
        .read(captureControllerProvider(_sessionKey()).notifier)
        .loadRecord(recordId);
    if (!mounted) {
      return;
    }
    switch (loaded) {
      case FailureResult<void>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      case Success<void>():
        await _refreshThumbs(
          _activePhotos(ref.read(captureControllerProvider(_sessionKey()))),
        );
    }
  }

  /// Writes the edit to its record and returns to the record's page with a
  /// [CaptureEditOutcome]. A failure keeps every change and offers Retry.
  Future<void> _saveEdits() async {
    final _CaptureUiController ui = ref.read(
      _captureUiProvider(_sessionKey()).notifier,
    );
    if (ref.read(_captureUiProvider(_sessionKey())).saving || !mounted) {
      return;
    }
    // Photos not yet filed on the record are the ones this save adds.
    final CaptureSession editing = ref.read(
      captureControllerProvider(_sessionKey()),
    );
    final int added = editing.photos
        .where((PhotoDraft photo) => photo.recordId != editing.recordId)
        .length;
    ui.setSaving(true);
    final Result<void> saved;
    try {
      saved = await ref
          .read(captureControllerProvider(_sessionKey()).notifier)
          .saveEdits();
    } finally {
      ui.setSaving(false);
    }
    if (!mounted) {
      return;
    }
    switch (saved) {
      case FailureResult<void>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          undoLabel: Copy.of(context).queueRetry,
          onUndo: () => unawaited(_saveEdits()),
          localizedMessage: failure.explanation,
        );
      case Success<void>():
        showAppSnack(
          context,
          Copy.of(context).recordEditSaved,
          tone: SnackTone.success,
        );
        unawaited(
          Navigator.of(
            context,
          ).maybePop<CaptureEditOutcome>((photosAdded: added)),
        );
    }
  }

  /// Keeps the live session in the store for the next visit.
  Future<void> _persist() async {
    if (!mounted) {
      return;
    }
    await ref
        .read(captureControllerProvider(_sessionKey()).notifier)
        .checkpoint();
  }

  Future<void> _save(bool process) async {
    final _CaptureUiController ui = ref.read(
      _captureUiProvider(_sessionKey()).notifier,
    );
    if (ref.read(_captureUiProvider(_sessionKey())).saving || !mounted) {
      return;
    }
    final CaptureRecordPersistence? writer = ref.read(
      captureRecordWriterProvider,
    );
    if (writer == null) {
      showAppSnack(
        context,
        Copy.of(context).captureSaveFailed,
        tone: SnackTone.error,
      );
      return;
    }
    ui.setSaving(true);
    final CaptureController controller = ref.read(
      captureControllerProvider(_sessionKey()).notifier,
    );
    late final Result<Object> result;
    try {
      if (process) {
        result = await controller.saveAndAnalyse(
          persist: writer.persist,
          enqueue: (String recordId) async {
            final Result<String> queued = await ref
                .read(processingRepositoryProvider)
                .enqueue(recordId);
            return queued.map(
              (String jobId) =>
                  SaveAndAnalyse.jobFor(jobId: jobId, recordId: recordId),
            );
          },
        );
      } else {
        result = await controller.saveRaw(writer.persist);
      }
    } finally {
      ui.setSaving(false);
    }
    if (!mounted) {
      return;
    }
    switch (result) {
      case FailureResult<Object>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          undoLabel: Copy.of(context).queueRetry,
          onUndo: () => unawaited(_save(process)),
          localizedMessage: failure.explanation,
        );
      case Success<Object>(:final Object value):
        if (value is SaveAndAnalyseResult && value.enqueueFailed) {
          showAppSnack(
            context,
            Copy.of(context).captureEnqueueFailed,
            tone: SnackTone.error,
            undoLabel: Copy.of(context).queueRetry,
            onUndo: () => unawaited(_save(true)),
          );
          return;
        }
        _bytes.clear();
        _thumbnailBytes.clear();
        _thumbs.clear();
        _missing.clear();
        _selected.clear();
        // The template just used moves to the front of the list.
        ref.invalidate(captureRecentTemplatesProvider(_projectId()));
        showAppSnack(
          context,
          Copy.of(context).captureSaved,
          tone: SnackTone.success,
        );
    }
  }

  /// Pins [templateId] to [place], so capture uses it whenever it is back
  /// at this context level (spec section 14.3).
  Future<void> _pinTemplateHere(
    Project project,
    String templateId,
    Map<String, String> place,
  ) async {
    final Result<void> saved = await ref
        .read(captureControllerProvider(_sessionKey()).notifier)
        .pinTemplateToPlace(
          project: project,
          templateId: templateId,
          place: place,
        );
    if (!mounted) {
      return;
    }
    switch (saved) {
      case FailureResult<void>(:final Failure failure):
        showAppSnack(
          context,
          failure.message,
          tone: SnackTone.error,
          localizedMessage: failure.explanation,
        );
      case Success<void>():
        showAppSnack(
          context,
          Copy.of(context).captureTemplatePinned,
          tone: SnackTone.success,
        );
    }
  }
}
