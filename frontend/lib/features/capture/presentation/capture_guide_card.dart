import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/responsive/responsive_pair.dart';
import 'package:tapture/features/templates/templates.dart';

import 'capture_guide_state.dart';

/// The guide action after paired compact targets, or beside them on wider
/// windows, opening the template's complete photo and caption field labels.
class CaptureGuideCard extends ConsumerWidget {
  /// Creates the row for [guide].
  const CaptureGuideCard({required this.guide, this.targets, super.key});

  /// What the chosen template asks for.
  final CaptureGuide guide;

  /// Existing paired selectors before, or beside, the guide action.
  final Widget? targets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LocalizedCopy localCopy = Copy.of(context);

    if (guide.isEmpty) {
      return targets ?? const SizedBox.shrink();
    }
    final bool open = ref.watch(captureGuideStateProvider).open;
    final Widget action = Wrap(
      spacing: Space.x2,
      runSpacing: Space.x1,
      children: <Widget>[
        Semantics(
          expanded: open,
          child: AppButton(
            key: const ValueKey<String>('capture-guide-toggle'),
            label: localCopy.captureGuideTitle,
            icon: AppIcons.info,
            variant: AppButtonVariant.text,
            onPressed: ref.read(captureGuideStateProvider.notifier).toggle,
          ),
        ),
      ],
    );
    return Column(
      key: const ValueKey<String>('capture-guide'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (targets case final Widget selectors)
          ResponsivePair(
            start: selectors,
            end: action,
            startFlex: 2,
            stacksOnCompact: true,
            gap: Space.x2,
          )
        else
          action,
        if (open) ...<Widget>[
          if (guide.photoFields.isNotEmpty)
            _GuideList(
              icon: AppIcons.camera,
              title: localCopy.captureGuidePhotos,
              labels: guide.photoFields,
            ),
          if (guide.captionFields.isNotEmpty)
            _GuideList(
              icon: AppIcons.caption,
              title: localCopy.captureGuideCaption,
              labels: guide.captionFields,
            ),
        ],
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
