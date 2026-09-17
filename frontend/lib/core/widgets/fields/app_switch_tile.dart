import 'package:flutter/material.dart';
import 'package:tapture/app/theme/color_tokens.dart';
import 'package:tapture/app/theme/dimensions.dart';
import 'package:tapture/app/theme/typography.dart';

/// Boolean input as a full-width tile. Settings and boolean template fields
/// share this control. The whole tile is the tap target.
class AppSwitchTile extends StatelessWidget {
  /// Creates a switch tile. [description] is optional supporting copy.
  const AppSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
    this.enabled = true,
  }) : _useCheckbox = false;

  /// Creates the same layout with a checkbox instead of a switch.
  const AppSwitchTile.checkbox({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.description,
    this.enabled = true,
  }) : _useCheckbox = true;

  /// Visible title; also the semantic name of the control (FE-A11Y-02).
  final String title;

  /// Optional supporting line under [title].
  final String? description;

  /// Whether the switch or checkbox is on.
  final bool value;

  /// Called with the toggled value. The tile and the control share this.
  final ValueChanged<bool> onChanged;

  /// When false, taps are ignored and the control looks disabled.
  final bool enabled;

  final bool _useCheckbox;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    return MergeSemantics(
      child: Semantics(
        label: title,
        hint: description,
        enabled: enabled,
        checked: _useCheckbox ? value : null,
        toggled: _useCheckbox ? null : value,
        onTap: enabled ? _toggle : null,
        child: Material(
          color: colors.surface,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: colors.outline, width: Space.x0 / 2),
              ),
            ),
            child: InkWell(
              onTap: enabled ? _toggle : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: Sizes.minTapTarget + Space.x6,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.x4,
                    vertical: Space.x2,
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: AppText.bodyStrong.copyWith(
                                color: colors.onSurface,
                              ),
                            ),
                            if (description != null) ...<Widget>[
                              const SizedBox(height: Space.x1),
                              Text(
                                description!,
                                style: AppText.caption.copyWith(
                                  color: colors.onSurface,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: Space.x3),
                      IgnorePointer(
                        child: ExcludeSemantics(
                          child: _useCheckbox
                              ? Checkbox(
                                  value: value,
                                  onChanged: enabled ? (_) {} : null,
                                )
                              : Switch(
                                  value: value,
                                  onChanged: enabled ? (_) {} : null,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggle() => onChanged(!value);
}
