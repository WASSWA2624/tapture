import '../domain/feedback_filter.dart';

/// Ephemeral state of the download-feedback flow.
typedef DownloadFeedbackView = ({
  FeedbackFilter filter,
  bool moreFilters,
  int visible,
  bool busy,
  String? error,
});
