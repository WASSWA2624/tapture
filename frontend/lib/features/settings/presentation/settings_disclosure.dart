import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';
import 'package:tapture/core/widgets/app_section_header.dart';
import 'package:tapture/core/widgets/state_refresh.dart';

/// Advanced settings revealed for this screen session, without saving a setting.
class SettingsDisclosure extends StatefulWidget {
  /// [id] is stable across locale, theme and width changes.
  const SettingsDisclosure({
    super.key,
    required this.id,
    required this.title,
    required this.children,
    this.summary,
    this.initiallyExpanded = false,
    this.maintainState = false,
  });

  final String id;
  final String title;
  final String? summary;
  final List<Widget> children;

  /// Opens this instance on first mount, for an explicit deep link.
  final bool initiallyExpanded;

  /// Retains editable children while hiding them from traversal and semantics.
  final bool maintainState;

  @override
  State<SettingsDisclosure> createState() => _SettingsDisclosureState();
}

class _SettingsDisclosureState extends State<SettingsDisclosure>
    with StateRefresh<SettingsDisclosure> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey<String>(widget.id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSectionHeader(
          title: widget.title,
          expanded: _expanded,
          onToggle: () => refresh(() => _expanded = !_expanded),
        ),
        if (!_expanded && widget.summary != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x4),
            child: Text(
              widget.summary!,
              style: AppText.caption.copyWith(color: context.colors.onSurface),
            ),
          ),
        if (widget.maintainState)
          ExcludeFocus(
            excluding: !_expanded,
            child: Visibility(
              visible: _expanded,
              maintainState: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
          )
        else if (_expanded)
          ...widget.children,
      ],
    );
  }
}
