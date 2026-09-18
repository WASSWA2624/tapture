import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/screen_capture.dart';

import 'feedback_draft.dart';
import 'feedback_draft_controller.dart';
import 'feedback_providers.dart';
import 'feedback_shot_fit.dart';

/// Holds whether an external window is being shared for repeat stills.
final class FeedbackWindowShareController extends Notifier<bool> {
  /// Creates the holder.
  FeedbackWindowShareController();

  @override
  bool build() {
    final ScreenCapture capture = ref.read(feedbackScreenCaptureProvider);
    final StreamSubscription<void> ended = capture.ended.listen((void _) {
      Future<void>.microtask(() {
        if (ref.mounted) {
          state = false;
        }
      });
    });
    ref.onDispose(() {
      ended.cancel();
      capture.stop();
    });
    ref.listen<FeedbackDraft?>(feedbackDraftProvider, (
      FeedbackDraft? previous,
      FeedbackDraft? next,
    ) {
      if (next == null) {
        Future<void>.microtask(() {
          if (ref.mounted) {
            stop();
          }
        });
      }
    });
    return false;
  }

  /// Adds one still of the shared window, starting the picker if needed.
  ///
  /// Returns why none was added, or null; a cancelled picker is not a
  /// failure. A full draft keeps sharing.
  Future<String?> addStill() async {
    final FeedbackDraft? draft = ref.read(feedbackDraftProvider);
    if (draft == null) {
      return Copy.somethingWentWrong;
    }
    if (draft.shots.length >= AppConstants.userFeedback.maxShots) {
      return Copy.feedbackShotsFull;
    }
    final ScreenCapture capture = ref.read(feedbackScreenCaptureProvider);
    if (!state) {
      final Result<bool> started = await capture.start();
      switch (started) {
        case FailureResult<bool>(:final Failure failure):
          return failure.message;
        case Success<bool>(:final bool value):
          if (!value) {
            return null;
          }
      }
      state = true;
    }
    final Result<Uint8List> still = await capture.still(
      longEdge: AppConstants.userFeedback.screenshotLongEdge,
    );
    switch (still) {
      case FailureResult<Uint8List>(:final Failure failure):
        return failure.message;
      case Success<Uint8List>(:final Uint8List value):
        if (value.isEmpty) {
          return null;
        }
        return ref
            .read(feedbackDraftProvider.notifier)
            .addShot(
              await FeedbackShotFit.cap(value),
              label: Copy.feedbackOtherWindow,
            );
    }
  }

  /// Stops sharing. Safe when nothing is shared.
  void stop() {
    ref.read(feedbackScreenCaptureProvider).stop();
    state = false;
  }
}

/// Whether an external window is being shared. Kept alive so the folded
/// bar can take another still after the form disposes (FE-STATE-09).
final NotifierProvider<FeedbackWindowShareController, bool>
feedbackWindowShareProvider =
    NotifierProvider<FeedbackWindowShareController, bool>(
      FeedbackWindowShareController.new,
    );
