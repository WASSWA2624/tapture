import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_icons.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/features/templates/templates.dart';

import 'capture_guide_state.dart';

/// "What to capture", under the Template select: one line, collapsed at
/// first, that opens to what the photos should show and what to say in the
/// caption, both built from the template (FBK0000157, D14).
class CaptureGuideCard extends ConsumerWidget {
  /// Creates the row for [guide].
  const CaptureGuideCard({required this.guide, super.key});

  /// What the chosen template asks for.
  final CaptureGuide guide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (guide.isEmpty) {
      return const SizedBox.shrink();
    }
    final bool open = ref.watch(captureGuideStateProvider).open;
    return Column(
      key: const ValueKey<String>('capture-guide'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          key: const ValueKey<String>('capture-guide-toggle'),
          title: Copy.captureGuideTitle,
          dense: true,
          expanded: open,
          onToggle: ref.read(captureGuideStateProvider.notifier).toggle,
        ),
        if (open) ...<Widget>[
          if (guide.photoFields.isNotEmpty)
            _GuideList(
              icon: AppIcons.camera,
              title: Copy.captureGuidePhotos,
              labels: guide.photoFields,
            ),
          if (guide.captionFields.isNotEmpty)
            _GuideList(
              icon: AppIcons.caption,
              title: Copy.captureGuideCaption,
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
                  Copy.captureGuideItems(labels),
                  style: AppText.body.copyWith(color: ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
