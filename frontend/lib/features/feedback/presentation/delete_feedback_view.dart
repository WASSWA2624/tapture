import 'package:tapture/core/copy/localized_message.dart';

import '../domain/feedback_filter.dart';

/// Ephemeral state of the delete-feedback flow.
typedef DeleteFeedbackView = ({
  FeedbackFilter filter,
  bool moreFilters,
  Set<String> selected,
  int visible,
  bool busy,
  String? error,
  LocalizedMessage? localizedError,
});
