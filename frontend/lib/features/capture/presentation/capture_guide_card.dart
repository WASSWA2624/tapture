import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/features/templates/templates.dart';

/// Immediately shows the template's original photo guidance (task 164).
class CaptureGuideCard extends StatelessWidget {
  /// Creates the row for [guide].
  const CaptureGuideCard({required this.guide, this.targets, super.key});

  /// What the chosen template asks for.
  final CaptureGuide guide;

  /// Existing selectors displayed before the photo guidance.
  final Widget? targets;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    if (guide.photoFields.isEmpty) {
      return targets ?? const SizedBox.shrink();
    }
    return Column(
      key: const ValueKey<String>('capture-guide'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (targets case final Widget selectors) selectors,
        _GuideList(
          icon: AppIcons.camera,
          title: localCopy.captureGuidePhotos,
          labels: guide.photoFields,
        ),
      ],
    );
  }
}

/// One list of a capture guide: an icon, what it is for, and its field
/// labels as wrapping text.
class _GuideList extends StatelessWidget {
  const _GuideList({
    required this.icon,
    required this.title,
    required this.labels,
  });

  final IconData icon;
  final String title;

  /// The template's field labels, as data.
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final LocalizedCopy localCopy = Copy.of(context);

    final Color ink = context.colors.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Space.x4,
        vertical: Space.x1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ExcludeSemantics(
            child: Icon(icon, size: Space.x5, color: ink),
          ),
          const SizedBox(width: Space.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: AppText.label.copyWith(color: ink)),
                Text(
                  localCopy.captureGuideItems(labels),
                  style: AppText.caption.copyWith(color: ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
