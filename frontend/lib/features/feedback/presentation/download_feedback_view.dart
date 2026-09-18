import '../domain/feedback_filter.dart';

/// Ephemeral state of the download-feedback flow.
typedef DownloadFeedbackView = ({
  FeedbackFilter filter,
  int visible,
  bool busy,
  String? error,
});
