import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_chip.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_date_field.dart';
import 'package:tapture/core/widgets/fields/app_multi_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';

import '../domain/feedback_category.dart';
import '../domain/feedback_device_type.dart';
import '../domain/feedback_entry.dart';
import '../domain/feedback_filter.dart';
import '../domain/feedback_screenshot_filter.dart';
import '../domain/feedback_submitter.dart';
import 'feedback_labels.dart';

/// Shared facets for download and delete. Search and type are always in
/// view; range, screen, platform, device, submitter and screenshot fold
/// behind More filters (FE-SIMP-06).
class FeedbackFilterPanel extends StatelessWidget {
  /// Creates the panel. [onChanged] receives a new filter; [filter] is not
  /// mutated.
  const FeedbackFilterPanel({
    super.key,
    required this.filter,
    required this.entries,
    required this.onChanged,
    required this.clock,
    required this.expanded,
    required this.onToggleExpanded,
  });

  /// The current facets.
  final FeedbackFilter filter;

  /// All stored entries, used to offer screen and platform values.
  final List<FeedbackEntry> entries;

  /// Called with a replacement filter.
  final ValueChanged<FeedbackFilter> onChanged;

  /// Source of "now" for the date pickers.
  final Clock clock;

  /// Whether the folded facets are showing.
  final bool expanded;

  /// Opens or folds them.
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final int folded = _foldedInUse(filter);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Space.x4,
        Space.x2,
        Space.x4,
        Space.x0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppSearchField(
            key: ValueKey<bool>(filter.isEmpty),
            hint: Copy.feedbackSearch,
            onChanged: (String value) {
              onChanged(filter.copyWith(search: value));
            },
          ),
          const SizedBox(height: Space.x2),
          _TypeRow(filter: filter, entries: entries, onChanged: onChanged),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              key: const ValueKey<String>('feedback-more-filters'),
              label: expanded
                  ? Copy.feedbackFewerFilters
                  : Copy.feedbackMoreFilters(folded),
              icon: expanded ? Icons.expand_less : Icons.expand_more,
              variant: AppButtonVariant.text,
              onPressed: onToggleExpanded,
            ),
          ),
          if (expanded) ...<Widget>[
            const SizedBox(height: Space.x2),
            ..._folded(context),
          ],
        ],
      ),
    );
  }

  List<Widget> _folded(BuildContext context) {
    final Widget from = AppDateField(
      label: Copy.feedbackFrom,
      mode: DateFieldMode.dateTime,
      value: filter.fromUtc?.toLocal(),
      clock: clock,
      onChanged: (DateTime? value) {
        onChanged(
          filter.copyWith(fromUtc: value?.toUtc(), clearFrom: value == null),
        );
      },
    );
    final Widget to = AppDateField(
      label: Copy.feedbackTo,
      mode: DateFieldMode.dateTime,
      value: filter.toUtc?.toLocal(),
      clock: clock,
      onChanged: (DateTime? value) {
        onChanged(
          filter.copyWith(toUtc: value?.toUtc(), clearTo: value == null),
        );
      },
    );
    final bool sideBySide = context.responsive(compact: false, medium: true);
    final List<Widget> facets = <Widget>[
      if (sideBySide)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: from),
            const SizedBox(width: Space.x3),
            Expanded(child: to),
          ],
        )
      else ...<Widget>[from, to],
      if (filter.isRangeBackwards)
        Text(
          Copy.feedbackRangeBackwards,
          style: AppText.body.copyWith(color: context.colors.onSurface),
        ),
      AppMultiChoiceField<String>(
        label: Copy.feedbackScreens,
        value: filter.screens,
        options: <Choice<String>>[
          for (final String screen in FeedbackFilter.screensIn(entries))
            Choice<String>(screen, screen),
        ],
        onChanged: (Set<String> value) {
          onChanged(filter.copyWith(screens: value));
        },
      ),
      AppMultiChoiceField<String>(
        label: Copy.feedbackPlatforms,
        value: filter.platforms,
        options: <Choice<String>>[
          for (final String platform in FeedbackFilter.platformsIn(entries))
            Choice<String>(platform, platform),
        ],
        onChanged: (Set<String> value) {
          onChanged(filter.copyWith(platforms: value));
        },
      ),
      AppMultiChoiceField<FeedbackDeviceType>(
        label: Copy.feedbackDeviceTypes,
        value: filter.deviceTypes,
        options: <Choice<FeedbackDeviceType>>[
          for (final FeedbackDeviceType type in FeedbackDeviceType.values)
            Choice<FeedbackDeviceType>(type, FeedbackLabels.deviceType(type)),
        ],
        onChanged: (Set<FeedbackDeviceType> value) {
          onChanged(filter.copyWith(deviceTypes: value));
        },
      ),
      AppMultiChoiceField<FeedbackSubmitter>(
        label: Copy.feedbackSubmittedBy,
        value: filter.submitters,
        options: <Choice<FeedbackSubmitter>>[
          for (final FeedbackSubmitter submitter in FeedbackSubmitter.values)
            Choice<FeedbackSubmitter>(
              submitter,
              FeedbackLabels.submitter(submitter),
            ),
        ],
        onChanged: (Set<FeedbackSubmitter> value) {
          onChanged(filter.copyWith(submitters: value));
        },
      ),
      AppChoiceField<FeedbackScreenshotFilter>(
        label: Copy.feedbackScreenshot,
        value: filter.screenshot,
        options: <Choice<FeedbackScreenshotFilter>>[
          for (final FeedbackScreenshotFilter option
              in FeedbackScreenshotFilter.values)
            Choice<FeedbackScreenshotFilter>(
              option,
              FeedbackLabels.screenshot(option),
            ),
        ],
        onChanged: (FeedbackScreenshotFilter? value) {
          if (value != null) {
            onChanged(filter.copyWith(screenshot: value));
          }
        },
      ),
    ];
    return <Widget>[
      for (int i = 0; i < facets.length; i++) ...<Widget>[
        if (i > 0) const SizedBox(height: Space.x3),
        facets[i],
      ],
    ];
  }
}

/// The feedback types as one row of toggles. None ticked lets every type
/// through, like the other facets.
class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.filter,
    required this.entries,
    required this.onChanged,
  });

  final FeedbackFilter filter;
  final List<FeedbackEntry> entries;
  final ValueChanged<FeedbackFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final List<FeedbackCategory> offered = FeedbackCategory.filterable(
      entries.map((FeedbackEntry entry) => entry.category),
    );
    return Semantics(
      container: true,
      label: Copy.feedbackTypes,
      child: AppChipRow(
        chips: <AppChip>[
          for (final FeedbackCategory category in offered)
            AppChip(
              label: FeedbackLabels.category(category),
              selected: filter.categories.contains(category),
              onTap: () => onChanged(
                filter.copyWith(
                  categories: _toggled(filter.categories, category),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Set<FeedbackCategory> _toggled(
  Set<FeedbackCategory> current,
  FeedbackCategory category,
) {
  final Set<FeedbackCategory> next = Set<FeedbackCategory>.of(current);
  if (!next.add(category)) {
    next.remove(category);
  }
  return next;
}

/// How many folded facets narrow the list, for the More filters label.
int _foldedInUse(FeedbackFilter filter) {
  return <bool>[
    filter.fromUtc != null || filter.toUtc != null,
    filter.screens.isNotEmpty,
    filter.platforms.isNotEmpty,
    filter.deviceTypes.isNotEmpty,
    filter.submitters.isNotEmpty,
    filter.screenshot != FeedbackScreenshotFilter.any,
  ].where((bool inUse) => inUse).length;
}
