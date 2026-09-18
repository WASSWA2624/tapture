import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'dimensions.dart';
import 'typography.dart';

/// Gallery page of every colour role in the active mode (FE-CONS-03).
class ColorSwatches extends StatelessWidget {
  /// Creates the swatch gallery.
  const ColorSwatches({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final List<(String, Color)> roles = <(String, Color)>[
      ('surface', colors.surface),
      ('surfaceVariant', colors.surfaceVariant),
      ('background', colors.background),
      ('onSurface', colors.onSurface),
      ('onSurfaceMuted', colors.onSurfaceMuted),
      ('outline', colors.outline),
      ('primary', colors.primary),
      ('onPrimary', colors.onPrimary),
      ('secondary', colors.secondary),
      ('danger', colors.danger),
      ('warning', colors.warning),
      ('success', colors.success),
      ('info', colors.info),
      ('confidenceHigh', colors.confidenceHigh),
      ('confidenceMedium', colors.confidenceMedium),
      ('confidenceLow', colors.confidenceLow),
    ];
    return ListView(
      padding: const EdgeInsets.all(Space.x4),
      children: <Widget>[
        for (final (String name, Color swatch) in roles)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.x2),
            child: Row(
              children: <Widget>[
                Container(
                  width: Sizes.minTapTarget,
                  height: Sizes.minTapTarget,
                  decoration: BoxDecoration(
                    color: swatch,
                    borderRadius: BorderRadius.circular(Radii.sm),
                    border: Border.all(color: colors.outline),
                  ),
                ),
                const SizedBox(width: Space.x3),
                Expanded(
                  child: Text(
                    name,
                    style: AppText.label.copyWith(color: colors.onSurface),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
