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
      RecordStatus.draft => (colors.secondary, Icons.edit_note, 'Draft'),
      RecordStatus.captured => (colors.info, Icons.photo_camera, 'Captured'),
      RecordStatus.queued => (colors.info, Icons.schedule, 'Queued'),
      RecordStatus.processing => (colors.secondary, Icons.sync, 'Processing'),
      RecordStatus.extracted => (colors.info, Icons.auto_awesome, 'Extracted'),
      RecordStatus.needsReview => (colors.warning, Icons.flag, 'Needs review'),
      RecordStatus.approved => (colors.success, Icons.verified, 'Approved'),
      RecordStatus.failed => (colors.danger, Icons.error_outline, 'Failed'),
      RecordStatus.archived => (colors.outline, Icons.inventory_2, 'Archived'),
      RecordStatus.deleted => (colors.danger, Icons.delete_outline, 'Deleted'),
    };
  }
}
