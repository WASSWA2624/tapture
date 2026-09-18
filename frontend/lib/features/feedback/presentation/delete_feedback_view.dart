import '../domain/feedback_filter.dart';

/// Ephemeral state of the delete-feedback flow.
typedef DeleteFeedbackView = ({
  FeedbackFilter filter,
  Set<String> selected,
  int visible,
  bool busy,
  String? error,
});
