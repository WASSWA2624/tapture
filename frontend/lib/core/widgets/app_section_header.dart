import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/widgets/app_icons.dart';

/// Group heading used inside lists and forms, from the [AppText.section]
/// type role.
class AppSectionHeader extends StatelessWidget {
  /// Creates a section heading. [action] is an optional trailing control
  /// that must already meet 48dp and carry a label (FE-A11Y-01, FE-A11Y-02).
  ///
  /// With [expanded] and [onToggle] the whole heading is one button that
  /// opens and closes the section below it.
  const AppSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.dense = false,
    this.expanded,
    this.onToggle,
  }) : assert(
         (expanded == null) == (onToggle == null),
         'expanded and onToggle are set together',
       );

  /// Visible heading; also the semantic name of the section.
  final String title;

  /// Optional trailing action (filter, "see all", overflow).
  final Widget? action;

  /// When true, vertical padding shrinks so the heading sits closer to the
  /// list it names.
  final bool dense;

  /// Whether the section below shows. Null keeps a plain heading.
  final bool? expanded;

  /// Opens or closes the section. Set with [expanded].
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final bool? open = expanded;
    if (open != null) {
      return _toggle(context, open);
    }
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

  /// The heading as one 48dp button, its state told by glyph and by the
  /// announcement, never by colour alone (FE-A11Y-05).
  Widget _toggle(BuildContext context, bool open) {
    final Color ink = context.colors.primary;
    return Semantics(
      container: true,
      header: true,
      button: true,
      expanded: open,
      label: title,
      onTap: onToggle,
      excludeSemantics: action == null,
      explicitChildNodes: action != null,
      child: InkWell(
        onTap: onToggle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.minTapTarget),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              Space.x4,
              dense ? Space.x2 : Space.x4,
              Space.x2,
              Space.x1,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.section.copyWith(color: ink),
                  ),
                ),
                ?action,
                const SizedBox(width: Space.x2),
                ExcludeSemantics(
                  child: Icon(
                    open ? AppIcons.collapse : AppIcons.expand,
                    color: ink,
                    size: Space.x6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
