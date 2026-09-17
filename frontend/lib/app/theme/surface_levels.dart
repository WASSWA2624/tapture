import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'dimensions.dart';
import 'elevation.dart';
import 'typography.dart';

/// Gallery page of surface depth levels in the active mode (FE-CONS-03).
class SurfaceLevels extends StatelessWidget {
  /// Creates the elevation gallery.
  const SurfaceLevels({super.key});

  @override
  Widget build(BuildContext context) {
    final Color color = context.colors.onSurface;
    return ListView(
      padding: const EdgeInsets.all(Space.x4),
      children: <Widget>[
        for (int level = 0; level <= 3; level++)
          Container(
            margin: const EdgeInsets.only(bottom: Space.x4),
            padding: const EdgeInsets.all(Space.x4),
            decoration: Elevation.surface(context, level: level),
            child: Text(
              'Level $level',
              style: AppText.body.copyWith(color: color),
            ),
          ),
      ],
    );
  }
}
