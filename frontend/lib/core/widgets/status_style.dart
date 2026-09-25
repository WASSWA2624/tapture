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
        AppIcons.draft,
        Copy.statusDraft,
      ),
      RecordStatus.captured => (
        colors.info,
        AppIcons.captured,
        Copy.statusCaptured,
      ),
      RecordStatus.queued => (colors.info, AppIcons.queued, Copy.statusQueued),
      RecordStatus.processing => (
        colors.secondary,
        AppIcons.processing,
        Copy.statusProcessing,
      ),
      RecordStatus.extracted => (
        colors.info,
        AppIcons.ai,
        Copy.statusExtracted,
      ),
      RecordStatus.needsReview => (
        colors.warning,
        AppIcons.review,
        Copy.statusNeedsReview,
      ),
      RecordStatus.approved => (
        colors.success,
        AppIcons.verified,
        Copy.statusApproved,
      ),
      RecordStatus.failed => (colors.danger, AppIcons.error, Copy.failed),
      RecordStatus.archived => (
        colors.outline,
        AppIcons.archive,
        Copy.statusArchived,
      ),
      RecordStatus.deleted => (
        colors.danger,
        AppIcons.delete,
        Copy.statusDeleted,
      ),
    };
  }
}
