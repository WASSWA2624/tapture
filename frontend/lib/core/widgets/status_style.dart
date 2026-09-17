part of 'app_status_pill.dart';

/// The single mapping from [RecordStatus] to colour, icon and label.
///
/// An unmapped status is a compile error: the switch has no default
/// (FE-CONS-06, FE-THEME-05).
abstract final class StatusStyle {
  /// Resolves [status] against [colors]. Labels are the shared vocabulary,
  /// not invented per screen (FE-CONS-07).
  static (Color, IconData, String) of(RecordStatus status, AppColors colors) {
    return switch (status) {
      RecordStatus.draft => (
        colors.secondary,
        Icons.edit_note,
        Copy.statusDraft,
      ),
      RecordStatus.captured => (
        colors.info,
        Icons.photo_camera,
        Copy.statusCaptured,
      ),
      RecordStatus.queued => (colors.info, Icons.schedule, Copy.statusQueued),
      RecordStatus.processing => (
        colors.secondary,
        Icons.sync,
        Copy.statusProcessing,
      ),
      RecordStatus.extracted => (
        colors.info,
        Icons.auto_awesome,
        Copy.statusExtracted,
      ),
      RecordStatus.needsReview => (
        colors.warning,
        Icons.flag,
        Copy.statusNeedsReview,
      ),
      RecordStatus.approved => (
        colors.success,
        Icons.verified,
        Copy.statusApproved,
      ),
      RecordStatus.failed => (colors.danger, Icons.error_outline, Copy.failed),
      RecordStatus.archived => (
        colors.outline,
        Icons.inventory_2,
        Copy.statusArchived,
      ),
      RecordStatus.deleted => (
        colors.danger,
        Icons.delete_outline,
        Copy.statusDeleted,
      ),
    };
  }
}
