import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tapture/app/route_paths.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/features/capture/capture.dart' show CaptureEditOutcome;

import 'record_photos_editor_controller.dart';

/// Adds and removes a saved record's photos long after capture (task 014
/// step 5), through the capture edit page, so photos are taken, picked,
/// cropped and captioned exactly as at capture (FE-CONS-01).
///
/// Saving there writes the record's history and flags any value whose photo
/// evidence was removed; the value itself is kept. When the save added
/// photos, the operator is offered to process the record again, so the new
/// photos are read for values too.
abstract final class RecordPhotosEditor {
  /// Opens the photo edit of record [recordId] in project [projectId] and,
  /// once a save that added photos returns to [context], offers to process
  /// the record again. Leaving without saving, or a save that only removed
  /// or reordered photos, offers nothing.
  static Future<void> open(
    BuildContext context,
    WidgetRef ref, {
    required String projectId,
    required String recordId,
  }) async {
    final LocalizedCopy localCopy = Copy.of(context);

    final Object? outcome = await GoRouter.of(
      context,
    ).push<Object?>(RoutePaths.projectRecordEdit(projectId, recordId));
    final int added = outcome is CaptureEditOutcome ? outcome.photosAdded : 0;
    if (added <= 0 || !context.mounted) {
      return;
    }
    final bool confirmed = await showAppConfirm(
      context,
      title: localCopy.recordPhotosProcessTitle,
      message: localCopy.recordPhotosProcessMessage(added),
      confirmLabel: localCopy.recordPhotosProcessConfirm,
    );
    if (!confirmed || !context.mounted) {
      return;
    }
    await processAgain(context, ref, recordId: recordId);
  }

  /// Puts record [recordId] back in the processing queue and says how it
  /// went: a confirmation, or the reason it could not be queued with Retry.
  /// Returns the queue's answer.
  static Future<Result<String>> processAgain(
    BuildContext context,
    WidgetRef ref, {
    required String recordId,
  }) {
    final RecordPhotosEditorController controller = ref.read(
      recordPhotosEditorControllerProvider.notifier,
    );
    return _queue(_snackHost(context), controller, recordId);
  }
}

/// Queues [recordId] and reports the outcome on [host]. A retry from the
/// snack goes through the same [controller], so it still works after the
/// page that asked has closed.
Future<Result<String>> _queue(
  BuildContext host,
  RecordPhotosEditorController controller,
  String recordId,
) async {
  final LocalizedCopy localCopy = Copy.of(host);

  final Result<String> queued = await controller.processAgain(recordId);
  if (!host.mounted) {
    return queued;
  }
  switch (queued) {
    case Success<String>():
      showAppSnack(
        host,
        localCopy.recordPhotosProcessQueued,
        tone: SnackTone.success,
      );
    case FailureResult<String>(:final Failure failure):
      showAppSnack(
        host,
        failure.message,
        tone: SnackTone.error,
        undoLabel: localCopy.queueRetry,
        onUndo: () => unawaited(_queue(host, controller, recordId)),
        localizedMessage: failure.explanation,
      );
  }
  return queued;
}

/// A context that outlives the record page: the root navigator sits under
/// the app's scaffold messenger, so the snack lands where the operator is
/// looking even when the page has closed.
BuildContext _snackHost(BuildContext context) {
  return Navigator.maybeOf(context, rootNavigator: true)?.context ?? context;
}
