import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_search_field.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/fields/app_choice_field.dart';
import 'package:tapture/core/widgets/fields/app_date_field.dart';
import 'package:tapture/core/widgets/fields/app_multi_choice_field.dart';
import 'package:tapture/core/widgets/fields/choice.dart';

import '../domain/feedback_category.dart';
import '../domain/feedback_device_type.dart';
import '../domain/feedback_entry.dart';
import '../domain/feedback_filter.dart';
import '../domain/feedback_screenshot_filter.dart';
import '../domain/feedback_submitter.dart';
import 'feedback_labels.dart';

/// Shared facets for download and delete: type, range, screen, platform,
/// device, submitter, screenshot and text search.
class FeedbackFilterPanel extends StatelessWidget {
  /// Creates the panel. [onChanged] receives a new filter; [filter] is not
  /// mutated.
  const FeedbackFilterPanel({
    super.key,
    required this.filter,
    required this.entries,
    required this.onChanged,
    required this.clock,
  });

  /// The current facets.
  final FeedbackFilter filter;

  /// All stored entries, used to offer screen and platform values.
  final List<FeedbackEntry> entries;

  /// Called with a replacement filter.
  final ValueChanged<FeedbackFilter> onChanged;

  /// Source of "now" for the date pickers.
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const AppSectionHeader(title: Copy.feedbackWhich),
        AppMultiChoiceField<FeedbackCategory>(
          label: Copy.feedbackTypes,
          value: filter.categories,
          options: <Choice<FeedbackCategory>>[
            for (final FeedbackCategory category in FeedbackCategory.values)
              Choice<FeedbackCategory>(
                category,
                FeedbackLabels.category(category),
              ),
          ],
          onChanged: (Set<FeedbackCategory> value) {
            onChanged(filter.copyWith(categories: value));
          },
        ),
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
        AppSearchField(
          key: ValueKey<bool>(filter.isEmpty),
          hint: Copy.feedbackSearch,
          onChanged: (String value) {
            onChanged(filter.copyWith(search: value));
          },
        ),
        if (!filter.isEmpty)
          AppButton(
            label: Copy.feedbackClearFilters,
            variant: AppButtonVariant.text,
            onPressed: () => onChanged(const FeedbackFilter()),
          ),
      ],
    );
  }
}
