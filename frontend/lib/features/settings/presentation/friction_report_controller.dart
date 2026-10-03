import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/features/feedback/feedback.dart'
    show FeedbackContext, FeedbackEntry, feedbackRepositoryProvider;

import '../domain/friction_log.dart';
import 'friction_report_state.dart';

/// Owns the report's optional screenshot and durable submission.
final class FrictionReportController extends Notifier<FrictionReportState> {
  @override
  FrictionReportState build() =>
      (saving: false, screenshot: false, error: null);

  /// Explicit permission to attach an image to the report.
  void includeScreenshot(bool value) {
    if (!state.saving) {
      state = (saving: false, screenshot: value, error: null);
    }
  }

  /// Persists before success is returned; a failed screenshot can be retried or omitted.
  Future<Result<FeedbackEntry>> save({
    required FeedbackContext context,
    required String note,
    required Future<Uint8List?> Function() capture,
  }) async {
    if (state.saving) {
      return FailureResult<FeedbackEntry>(
        ValidationFailure(
          message: Copy.frictionSaving,
          localizedMessage: Copy.messages.frictionSaving,
          recoveryAction: Copy.tryAgain,
          localizedRecovery: Copy.messages.tryAgain,
        ),
      );
    }
    final bool screenshot = state.screenshot;
    final FrictionLog journal = FrictionLog(
      repository: ref.read(feedbackRepositoryProvider),
    );
    state = (saving: true, screenshot: screenshot, error: null);
    final Result<FeedbackEntry> result = await Result.captureAsync(() async {
      final Uint8List? image = screenshot ? await capture() : null;
      if (screenshot && (image == null || image.isEmpty)) {
        throw StorageFailure(
          message: Copy.frictionScreenshotFailed,
          localizedMessage: Copy.messages.frictionScreenshotFailed,
          recoveryAction: Copy.frictionScreenshotRecovery,
          localizedRecovery: Copy.messages.frictionScreenshotRecovery,
        );
      }
      return (await journal.logFriction(
        context: context,
        note: note,
        screenshot: image,
      )).getOrThrow();
    });
    if (ref.mounted) {
      state = (
        saving: false,
        screenshot: screenshot,
        error: result is FailureResult<FeedbackEntry> ? result.failure : null,
      );
    }
    return result;
  }
}

/// The sheet owns this short-lived submission state.
final frictionReportControllerProvider =
    NotifierProvider.autoDispose<FrictionReportController, FrictionReportState>(
      FrictionReportController.new,
    );

/// Tests override this flag; ordinary builds do not install trial controls.
final Provider<bool> fieldTrialProvider = Provider<bool>(
  (Ref _) => const bool.fromEnvironment('TAPTURE_FIELD_TRIAL'),
);
