import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';

import 'photo_types.dart';

export 'photo_types.dart';

/// Bottom sheet listing photo types.
final class PhotoTypeSheet extends StatelessWidget {
  /// Creates a sheet.
  const PhotoTypeSheet({
    required this.onSelected,
    this.lastUsed = 'other',
    super.key,
  });

  /// Chosen type key.
  final ValueChanged<String> onSelected;

  /// Default selection.
  final String lastUsed;

  @override
  Widget build(BuildContext context) {
    final List<String> ordered = <String>[
      lastUsed,
      ...PhotoTypes.all.where((String k) => k != lastUsed),
    ];
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        for (final String key in ordered)
          ListTile(
            title: Text(PhotoTypes.label(key, localizedCopy: Copy.of(context))),
            selected: key == lastUsed,
            onTap: () => onSelected(key),
          ),
      ],
    );
  }
}
