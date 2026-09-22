import 'package:flutter/material.dart';
import 'package:tapture/core/copy/copy.dart';

/// Spec photo types with last-used default.
abstract final class PhotoTypes {
  /// Every type key in spec order.
  static const List<String> all = <String>[
    'front',
    'back',
    'serial',
    'ratingPlate',
    'damage',
    'panel',
    'location',
    'attendance',
    'document',
    'other',
  ];

  /// Catalogue label for [key].
  static String label(String key) {
    return switch (key) {
      'front' => Copy.photoFront,
      'back' => Copy.photoBack,
      'serial' => Copy.photoSerial,
      'ratingPlate' => Copy.photoRatingPlate,
      'damage' => Copy.photoDamage,
      'panel' => Copy.photoPanel,
      'location' => Copy.photoLocation,
      'attendance' => Copy.photoAttendance,
      'document' => Copy.photoDocument,
      _ => Copy.photoOther,
    };
  }
}

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
            title: Text(PhotoTypes.label(key)),
            selected: key == lastUsed,
            onTap: () => onSelected(key),
          ),
      ],
    );
  }
}
