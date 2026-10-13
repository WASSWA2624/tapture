import 'package:flutter/widgets.dart';
import 'package:tapture/app/theme/dimensions.dart';

import 'app_card.dart';
import 'app_page_layout.dart';
import 'app_page_layout_scope.dart';
import 'app_section_header.dart';

/// Groups existing controls using the shared heading, card and spacing tokens.
class AppSection extends StatelessWidget {
  /// Creates a group without introducing a new scrolling or focus boundary.
  const AppSection({
    super.key,
    this.title,
    required this.children,
    this.layout,
  });

  /// Existing localized heading; omitted for an unnamed form group.
  final String? title;

  /// Controls in reading and keyboard order.
  final List<Widget> children;

  /// Overrides the owning page only when this group needs another layout.
  final AppPageLayout? layout;

  @override
  Widget build(BuildContext context) {
    final AppPageLayout effective = layout ?? AppPageLayoutScope.of(context);
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (title case final String heading) ...<Widget>[
          AppSectionHeader(
            title: heading,
            dense: effective == AppPageLayout.compact,
            wrapText: true,
          ),
          SizedBox(height: effective.fieldGap),
        ],
        for (int index = 0; index < children.length; index++) ...<Widget>[
          if (index > 0) SizedBox(height: effective.fieldGap),
          children[index],
        ],
      ],
    );
    return AppPageLayoutScope(
      layout: effective,
      child: effective == AppPageLayout.sectioned
          ? AppCard(padding: const EdgeInsets.all(Space.x3), child: content)
          : content,
    );
  }
}
