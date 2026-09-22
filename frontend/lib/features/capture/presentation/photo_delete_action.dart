import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/feedback/app_dialog.dart';
import 'package:tapture/core/widgets/feedback/app_snackbar.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';

/// Confirm delete, tombstone, snack with undo.
final class PhotoDeleteAction {
  /// Runs the delete flow.
  static Future<PhotoDraft?> run({
    required BuildContext context,
    required PhotoDraft photo,
    required Future<PhotoDraft?> Function(String photoId) delete,
    required Future<void> Function(PhotoDraft photo) undo,
  }) async {
    final bool ok = await showAppConfirm(
      context,
      title: Copy.captureDeletePhotoTitle,
      message: Copy.captureDeletePhotoMessage,
      confirmLabel: Copy.captureDeletePhotoTitle,
      destructive: true,
    );
    if (!ok) {
      return null;
    }
    final PhotoDraft? removed = await delete(photo.id);
    if (removed == null || !context.mounted) {
      return null;
    }
    showAppSnack(
      context,
      Copy.capturePhotoDeleted,
      undoLabel: Copy.captureUndoDelete,
      onUndo: () {
        undo(removed);
      },
    );
    return removed;
  }
}
