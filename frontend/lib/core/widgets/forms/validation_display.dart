import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/validation/severity.dart';
import 'package:tapture/core/validation/validation_issue.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';

/// Renders validation issues inline under a field, and as a summary at the
/// head of a form (task 015).
///
/// Errors and warnings differ by icon and wording, not by colour alone.
/// A change in the list is announced to a screen reader.
final class ValidationDisplay extends StatelessWidget {
  /// The issues that belong on [fieldKey], under that field.
  const ValidationDisplay.inline({
    required this.issues,
    required this.fieldKey,
    super.key,
  }) : summary = false,
       onJumpToError = null;

  /// How many issues there are, with a jump to the first error.
  const ValidationDisplay.summary({
    required this.issues,
    this.onJumpToError,
    super.key,
  }) : summary = true,
       fieldKey = null;

  /// Issues to show.
  final List<ValidationIssue> issues;

  /// The field this inline list belongs to. Null for the summary.
  final String? fieldKey;

  /// Whether this is the form summary rather than one field's lines.
  final bool summary;

  /// Scrolls to the first field that has an error.
  final VoidCallback? onJumpToError;

  @override
  Widget build(BuildContext context) {
    final List<ValidationIssue> shown = summary
        ? issues
        : <ValidationIssue>[
            for (final ValidationIssue issue in issues)
              if (issue.fieldKey == fieldKey) issue,
          ];
    if (shown.isEmpty && !summary) {
      return const SizedBox.shrink();
    }
    final int errors = shown
        .where((ValidationIssue issue) => issue.severity == Severity.error)
        .length;
    final int warnings = shown.length - errors;
    final String announcement = shown.isEmpty
        ? ''
        : Copy.validationIssueCount(errors, warnings);
    return Semantics(
      liveRegion: true,
      label: announcement,
      child: shown.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (summary) ...<Widget>[
                  Text(
                    announcement,
                    key: const ValueKey<String>('validation-summary-count'),
                    style: AppText.bodyStrong.copyWith(
                      color: context.colors.onSurface,
                    ),
                  ),
                  if (errors > 0 && onJumpToError != null) ...<Widget>[
                    const SizedBox(height: Space.x2),
                    AppButton(
                      key: const ValueKey<String>('validation-first-error'),
                      label: Copy.validationGoToFirstError,
                      variant: AppButtonVariant.secondary,
                      onPressed: onJumpToError,
                    ),
                  ],
                  const SizedBox(height: Space.x2),
                ],
                for (final ValidationIssue issue in shown) _Line(issue: issue),
              ],
            ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.issue});

  final ValidationIssue issue;

  @override
  Widget build(BuildContext context) {
    final bool error = issue.severity == Severity.error;
    final AppColors colors = context.colors;
    final String kind = error
        ? Copy.validationErrorLabel
        : Copy.validationWarningLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.x1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            error ? AppIcons.error : AppIcons.warning,
            size: Space.x4,
            color: error ? colors.danger : colors.onSurface,
          ),
          const SizedBox(width: Space.x2),
          Expanded(
            child: Text(
              '$kind. ${issue.message}',
              style: AppText.caption.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
