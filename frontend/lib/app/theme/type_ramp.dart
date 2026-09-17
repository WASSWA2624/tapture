import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'dimensions.dart';
import 'typography.dart';

/// Gallery page of every type role in the active mode (FE-CONS-03).
class TypeRamp extends StatelessWidget {
  /// Creates the type-ramp gallery.
  const TypeRamp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color color = context.colors.onSurface;
    const List<(String, TextStyle)> roles = <(String, TextStyle)>[
      ('display', AppText.display),
      ('title', AppText.title),
      ('section', AppText.section),
      ('body', AppText.body),
      ('bodyStrong', AppText.bodyStrong),
      ('label', AppText.label),
      ('caption', AppText.caption),
      ('mono', AppText.mono),
    ];
    return ListView(
      padding: const EdgeInsets.all(Space.x4),
      children: <Widget>[
        for (final (String name, TextStyle style) in roles)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.x4),
            child: Text(
              'The $name role — Tap it. It\'s data.',
              style: style.copyWith(color: color),
            ),
          ),
      ],
    );
  }
}
