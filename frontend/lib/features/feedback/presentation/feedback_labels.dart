import 'package:tapture/core/copy/copy.dart';

import '../domain/feedback_category.dart';
import '../domain/feedback_device_type.dart';
import '../domain/feedback_screenshot_filter.dart';
import '../domain/feedback_submitter.dart';

/// Interface copy for stored feedback values. Export labels stay on the
/// domain types so a workbook does not change language with the interface.
abstract final class FeedbackLabels {
  /// The type as shown on the form and in lists.
  static String category(
    FeedbackCategory category, {
    LocalizedCopy? localizedCopy,
  }) {
    return switch (category) {
      FeedbackCategory.general =>
        (localizedCopy ?? Copy.english).feedbackCategoryGeneral,
      FeedbackCategory.improvement =>
        (localizedCopy ?? Copy.english).feedbackCategoryImprovement,
      FeedbackCategory.error =>
        (localizedCopy ?? Copy.english).feedbackCategoryError,
      FeedbackCategory.suggestion =>
        (localizedCopy ?? Copy.english).feedbackCategorySuggestion,
      FeedbackCategory.other =>
        (localizedCopy ?? Copy.english).feedbackCategoryOther,
    };
  }

  /// Who wrote an entry, as shown on filters and lists.
  static String submitter(
    FeedbackSubmitter submitter, {
    LocalizedCopy? localizedCopy,
  }) {
    return switch (submitter) {
      FeedbackSubmitter.signedInUser =>
        (localizedCopy ?? Copy.english).feedbackSubmitterSignedIn,
      FeedbackSubmitter.localOperator =>
        (localizedCopy ?? Copy.english).feedbackSubmitterLocal,
      FeedbackSubmitter.anonymous =>
        (localizedCopy ?? Copy.english).feedbackSubmitterAnonymous,
    };
  }

  /// The device kind as shown on filters.
  static String deviceType(
    FeedbackDeviceType type, {
    LocalizedCopy? localizedCopy,
  }) {
    return switch (type) {
      FeedbackDeviceType.mobile =>
        (localizedCopy ?? Copy.english).feedbackDeviceMobile,
      FeedbackDeviceType.tablet =>
        (localizedCopy ?? Copy.english).feedbackDeviceTablet,
      FeedbackDeviceType.desktop =>
        (localizedCopy ?? Copy.english).feedbackDeviceDesktop,
    };
  }

  /// Whether a screenshot is attached, as shown on filters.
  static String screenshot(
    FeedbackScreenshotFilter filter, {
    LocalizedCopy? localizedCopy,
  }) {
    return switch (filter) {
      FeedbackScreenshotFilter.any =>
        (localizedCopy ?? Copy.english).feedbackScreenshotAny,
      FeedbackScreenshotFilter.attached =>
        (localizedCopy ?? Copy.english).feedbackScreenshotWith,
      FeedbackScreenshotFilter.missing =>
        (localizedCopy ?? Copy.english).feedbackScreenshotWithout,
    };
  }
}
