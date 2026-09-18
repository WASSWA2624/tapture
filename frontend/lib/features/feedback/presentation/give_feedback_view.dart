import '../domain/feedback_category.dart';

/// Ephemeral state of the give-feedback form.
typedef GiveFeedbackView = ({
  FeedbackCategory category,
  bool attachScreenshot,
  String? messageError,
  String? otherError,
  String? saveError,
});
