import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_icon_button.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/fields/app_checkbox_group.dart';
import 'package:tapture/core/widgets/fields/app_date_field.dart';
import 'package:tapture/core/widgets/fields/app_multi_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_radio_group.dart';
import 'package:tapture/core/widgets/fields/choice.dart';
import 'package:tapture/core/widgets/responsive/breakpoints.dart';

import '../domain/feedback_category.dart';
import '../domain/feedback_device_type.dart';
import '../domain/feedback_entry.dart';
import '../domain/feedback_filter.dart';
import '../domain/feedback_screenshot_filter.dart';
import '../domain/feedback_submitter.dart';
import 'feedback_labels.dart';

/// Shared facets for download and delete.
///
/// Search and a filter toggle share the first line, and the types sit under
/// them as checkboxes: the two facets used most. The rest fold behind the
/// toggle (FE-SIMP-06), which counts the folded facets in use so a hidden
/// filter is never a surprise, and pair up side by side where there is room.
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

  /// All stored entries, used to offer type, screen and platform values.
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
    final AppColors colors = context.colors;
    final int folded = _foldedInUse(filter);
    final String toggle = expanded
        ? Copy.feedbackFewerFilters
        : Copy.feedbackMoreFilters(folded);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        Space.x4,
        Space.x2,
        Space.x4,
        Space.x0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: AppSearchField(
                  // A cleared filter starts a fresh field.
                  key: ValueKey<bool>(filter.isEmpty),
                  hint: Copy.feedbackSearch,
                  onChanged: (String value) {
                    onChanged(filter.copyWith(search: value));
                  },
                ),
              ),
              const SizedBox(width: Space.x2),
              Semantics(
                expanded: expanded,
                child: Badge.count(
                  key: const ValueKey<String>('feedback-more-filters'),
                  count: folded,
                  isLabelVisible: folded > 0 && !expanded,
                  backgroundColor: colors.primary,
                  textColor: colors.onPrimary,
                  child: AppIconButton(
                    icon: Icons.tune,
                    semanticLabel: toggle,
                    tooltip: toggle,
                    selected: expanded,
                    onPressed: onToggleExpanded,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.x2),
          AppCheckboxGroup<FeedbackCategory>(
            label: Copy.feedbackTypes,
            value: filter.categories,
            options: <Choice<FeedbackCategory>>[
              for (final FeedbackCategory category
                  in FeedbackCategory.filterable(
                    entries.map((FeedbackEntry entry) => entry.category),
                  ))
                Choice<FeedbackCategory>(
                  category,
                  FeedbackLabels.category(category),
                ),
            ],
            onChanged: (Set<FeedbackCategory> value) {
              onChanged(filter.copyWith(categories: value));
            },
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
    final bool paired = context.responsive(compact: false, medium: true);
    final List<Widget> facets = <Widget>[
      _pair(
        paired,
        AppDateField(
          label: Copy.feedbackFrom,
          mode: DateFieldMode.dateTime,
          value: filter.fromUtc?.toLocal(),
          clock: clock,
          onChanged: (DateTime? value) {
            onChanged(
              filter.copyWith(
                fromUtc: value?.toUtc(),
                clearFrom: value == null,
              ),
            );
          },
        ),
        AppDateField(
          label: Copy.feedbackTo,
          mode: DateFieldMode.dateTime,
          value: filter.toUtc?.toLocal(),
          clock: clock,
          onChanged: (DateTime? value) {
            onChanged(
              filter.copyWith(toUtc: value?.toUtc(), clearTo: value == null),
            );
          },
        ),
      ),
      if (filter.isRangeBackwards)
        Semantics(
          liveRegion: true,
          child: Text(
            Copy.feedbackRangeBackwards,
            style: AppText.caption.copyWith(color: context.colors.onSurface),
          ),
        ),
      _pair(
        paired,
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
      ),
      AppRadioGroup<FeedbackScreenshotFilter>(
        label: Copy.feedbackScreenshot,
        direction: Axis.horizontal,
        value: filter.screenshot,
        options: <Choice<FeedbackScreenshotFilter>>[
          for (final FeedbackScreenshotFilter option
              in FeedbackScreenshotFilter.values)
            Choice<FeedbackScreenshotFilter>(
              option,
              FeedbackLabels.screenshot(option),
            ),
        ],
        onChanged: (FeedbackScreenshotFilter value) {
          onChanged(filter.copyWith(screenshot: value));
        },
      ),
      _pair(
        paired,
        AppCheckboxGroup<FeedbackDeviceType>(
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
        AppCheckboxGroup<FeedbackSubmitter>(
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
      ),
    ];
    return <Widget>[
      for (int i = 0; i < facets.length; i++) ...<Widget>[
        if (i > 0) const SizedBox(height: Space.x2),
        facets[i],
      ],
    ];
  }
}

/// [first] and [second] side by side when [paired], else stacked.
Widget _pair(bool paired, Widget first, Widget second) {
  if (!paired) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        first,
        const SizedBox(height: Space.x2),
        second,
      ],
    );
  }
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Expanded(child: first),
      const SizedBox(width: Space.x3),
      Expanded(child: second),
    ],
  );
}

/// How many folded facets narrow the list, for the toggle's badge.
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
