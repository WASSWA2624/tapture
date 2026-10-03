part of 'app_status_pill.dart';

/// The single mapping from [RecordStatus] to colour, icon and label.
///
/// An unmapped status is a compile error: the switch has no default
/// (FE-CONS-06, FE-THEME-05).
abstract final class StatusStyle {
  /// Resolves [status] against [colors]. Labels are the shared vocabulary,
  /// not invented per screen (FE-CONS-07).
  static (Color, IconData, String) of(
    RecordStatus status,
    AppColors colors, {
    LocalizedCopy? localizedCopy,
  }) {
    return switch (status) {
      RecordStatus.draft => (
        colors.secondary,
        AppIcons.draft,
        (localizedCopy ?? Copy.english).statusDraft,
      ),
      RecordStatus.captured => (
        colors.info,
        AppIcons.captured,
        (localizedCopy ?? Copy.english).statusCaptured,
      ),
      RecordStatus.queued => (
        colors.info,
        AppIcons.queued,
        (localizedCopy ?? Copy.english).statusQueued,
      ),
      RecordStatus.processing => (
        colors.secondary,
        AppIcons.processing,
        (localizedCopy ?? Copy.english).statusProcessing,
      ),
      RecordStatus.extracted => (
        colors.info,
        AppIcons.ai,
        (localizedCopy ?? Copy.english).statusExtracted,
      ),
      RecordStatus.needsReview => (
        colors.warning,
        AppIcons.review,
        (localizedCopy ?? Copy.english).statusNeedsReview,
      ),
      RecordStatus.approved => (
        colors.success,
        AppIcons.verified,
        (localizedCopy ?? Copy.english).statusApproved,
      ),
      RecordStatus.failed => (
        colors.danger,
        AppIcons.error,
        (localizedCopy ?? Copy.english).failed,
      ),
      RecordStatus.archived => (
        colors.outline,
        AppIcons.archive,
        (localizedCopy ?? Copy.english).statusArchived,
      ),
      RecordStatus.deleted => (
        colors.danger,
        AppIcons.delete,
        (localizedCopy ?? Copy.english).statusDeleted,
      ),
    };
  }
}
