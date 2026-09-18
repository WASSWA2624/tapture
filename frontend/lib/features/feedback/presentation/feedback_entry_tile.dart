import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';

import '../domain/feedback_entry.dart';
import 'feedback_labels.dart';

/// One stored entry as a list row.
class FeedbackEntryTile extends StatelessWidget {
  /// Creates the row. [onTap] selects or opens; [selected] shows a tick.
  const FeedbackEntryTile({
    super.key,
    required this.entry,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  /// The entry to show.
  final FeedbackEntry entry;

  /// Multi-select highlight.
  final bool selected;

  /// Invoked on a tap.
  final VoidCallback? onTap;

  /// Invoked on a long-press.
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final String locale = Localizations.localeOf(context).toString();
    final String when = DateFormat.yMMMd(
      locale,
    ).add_jm().format(entry.submittedAtUtc.toLocal());
    return AppListTile(
      title: entry.reference,
      subtitle: Copy.feedbackEntryFacts(
        FeedbackLabels.category(entry.category),
        when,
        entry.context.screen,
      ),
      selected: selected,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
