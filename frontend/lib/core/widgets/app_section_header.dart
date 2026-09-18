import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';

/// Group heading used inside lists and forms, from the [AppText.section]
/// type role.
class AppSectionHeader extends StatelessWidget {
  /// Creates a section heading. [action] is an optional trailing control
  /// that must already meet 48dp and carry a label (FE-A11Y-01, FE-A11Y-02).
  const AppSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.dense = false,
  });

  /// Visible heading; also the semantic name of the section.
  final String title;

  /// Optional trailing action (filter, "see all", overflow).
  final Widget? action;

  /// When true, vertical padding shrinks so the heading sits closer to the
  /// list it names.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      header: true,
      explicitChildNodes: true,
      label: title,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            Space.x4,
            dense ? Space.x2 : Space.x4,
            Space.x4,
            Space.x1,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.section.copyWith(
                    color: context.colors.primary,
                  ),
                ),
              ),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}
