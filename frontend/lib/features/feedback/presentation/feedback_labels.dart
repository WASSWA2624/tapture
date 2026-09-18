import 'package:tapture/core/copy/copy.dart';

import '../domain/feedback_category.dart';
import '../domain/feedback_device_type.dart';
import '../domain/feedback_screenshot_filter.dart';
import '../domain/feedback_submitter.dart';

/// Interface copy for stored feedback values. Export labels stay on the
/// domain types so a workbook does not change language with the interface.
abstract final class FeedbackLabels {
  /// The type as shown on the form and in lists.
  static String category(FeedbackCategory category) {
    return switch (category) {
      FeedbackCategory.general => Copy.feedbackCategoryGeneral,
      FeedbackCategory.improvement => Copy.feedbackCategoryImprovement,
      FeedbackCategory.error => Copy.feedbackCategoryError,
      FeedbackCategory.suggestion => Copy.feedbackCategorySuggestion,
      FeedbackCategory.other => Copy.feedbackCategoryOther,
    };
  }

  /// Who wrote an entry, as shown on filters and lists.
  static String submitter(FeedbackSubmitter submitter) {
    return switch (submitter) {
      FeedbackSubmitter.signedInUser => Copy.feedbackSubmitterSignedIn,
      FeedbackSubmitter.localOperator => Copy.feedbackSubmitterLocal,
      FeedbackSubmitter.anonymous => Copy.feedbackSubmitterAnonymous,
    };
  }

  /// The device kind as shown on filters.
  static String deviceType(FeedbackDeviceType type) {
    return switch (type) {
      FeedbackDeviceType.mobile => Copy.feedbackDeviceMobile,
      FeedbackDeviceType.tablet => Copy.feedbackDeviceTablet,
      FeedbackDeviceType.desktop => Copy.feedbackDeviceDesktop,
    };
  }

  /// Whether a screenshot is attached, as shown on filters.
  static String screenshot(FeedbackScreenshotFilter filter) {
    return switch (filter) {
      FeedbackScreenshotFilter.any => Copy.feedbackScreenshotAny,
      FeedbackScreenshotFilter.attached => Copy.feedbackScreenshotWith,
      FeedbackScreenshotFilter.missing => Copy.feedbackScreenshotWithout,
    };
  }
}
