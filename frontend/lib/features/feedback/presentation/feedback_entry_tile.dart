import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_list_tile.dart';

import '../domain/feedback_entry.dart';
import 'feedback_labels.dart';

/// One stored entry as a list row.
class FeedbackEntryTile extends StatelessWidget {
  /// Creates the row. [number] is the 1-based list position.
  const FeedbackEntryTile({
    super.key,
    required this.entry,
    required this.number,
    this.selected = false,
    this.onTap,
    this.onLongPress,
  });

  /// The entry to show.
  final FeedbackEntry entry;

  /// 1-based position among matching entries.
  final int number;

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
    final String formattedNumber = NumberFormat.decimalPattern(
      locale,
    ).format(number);
    final String oneLineMessage = entry.message
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return AppListTile(
      title: Copy.feedbackEntryTitle(
        formattedNumber,
        entry.reference,
        oneLineMessage,
      ),
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
