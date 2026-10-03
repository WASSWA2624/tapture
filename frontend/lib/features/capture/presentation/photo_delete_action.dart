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
    final LocalizedCopy localCopy = Copy.of(context);

    final bool ok = await showAppConfirm(
      context,
      title: localCopy.captureDeletePhotoTitle,
      message: localCopy.captureDeletePhotoMessage,
      confirmLabel: localCopy.captureDeletePhotoTitle,
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
      localCopy.capturePhotoDeleted,
      undoLabel: localCopy.captureUndoDelete,
      onUndo: () {
        undo(removed);
      },
    );
    return removed;
  }
}
