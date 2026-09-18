import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/states/app_empty_state.dart';

import '../domain/feedback_entry.dart';
import '../domain/feedback_filter.dart';
import 'feedback_filter_panel.dart';

/// Filters, the count that matches, and a page of matching entries: the
/// body download and delete share, so both read and behave the same.
class FeedbackBrowser extends StatelessWidget {
  /// Creates the browser over [all] entries, of which [matching] pass the
  /// filter and the first [visible] are shown.
  const FeedbackBrowser({
    super.key,
    required this.all,
    required this.matching,
    required this.visible,
    required this.filter,
    required this.clock,
    required this.moreFilters,
    required this.onFilter,
    required this.onToggleMoreFilters,
    required this.onShowMore,
    required this.tile,
    this.lead,
    this.error,
  });

  /// Every stored entry.
  final List<FeedbackEntry> all;

  /// The entries the filter lets through, newest first.
  final List<FeedbackEntry> matching;

  /// How many of [matching] are shown.
  final int visible;

  /// The current facets.
  final FeedbackFilter filter;

  /// Source of "now" for the date pickers.
  final Clock clock;

  /// Whether the folded facets are showing.
  final bool moreFilters;

  /// Receives a replacement filter.
  final ValueChanged<FeedbackFilter> onFilter;

  /// Opens or folds the extra facets.
  final VoidCallback onToggleMoreFilters;

  /// Shows another page.
  final VoidCallback onShowMore;

  /// One matching entry as a row.
  final Widget Function(FeedbackEntry entry) tile;

  /// Shown between the count and the rows, such as select-all.
  final Widget? lead;

  /// Why the last action failed, when it did.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final String? error = this.error;
    final Widget? lead = this.lead;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        FeedbackFilterPanel(
          filter: filter,
          entries: all,
          clock: clock,
          onChanged: onFilter,
          expanded: moreFilters,
          onToggleExpanded: onToggleMoreFilters,
        ),
        Semantics(
          liveRegion: true,
          child: AppSectionHeader(
            title: Copy.feedbackMatching(matching.length, all.length),
            dense: true,
            action: filter.isEmpty
                ? null
                : AppButton(
                    label: Copy.feedbackClearFilters,
                    variant: AppButtonVariant.text,
                    onPressed: () => onFilter(const FeedbackFilter()),
                  ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x4),
            child: Text(
              error,
              style: AppText.body.copyWith(color: context.colors.onSurface),
            ),
          ),
        if (matching.isEmpty)
          const AppEmptyState(
            icon: Icons.filter_alt_outlined,
            headline: Copy.feedbackNoMatchHeadline,
            message: Copy.feedbackNoMatchMessage,
          )
        else ...<Widget>[
          ?lead,
          for (final FeedbackEntry entry in matching.take(visible)) tile(entry),
          if (visible < matching.length)
            AppButton(
              label: Copy.feedbackShowMore,
              variant: AppButtonVariant.text,
              onPressed: onShowMore,
            ),
        ],
      ],
    );
  }
}
