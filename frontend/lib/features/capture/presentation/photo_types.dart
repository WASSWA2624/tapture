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
  static String label(String key, {LocalizedCopy? localizedCopy}) {
    return switch (key) {
      'front' => (localizedCopy ?? Copy.english).photoFront,
      'back' => (localizedCopy ?? Copy.english).photoBack,
      'serial' => (localizedCopy ?? Copy.english).photoSerial,
      'ratingPlate' => (localizedCopy ?? Copy.english).photoRatingPlate,
      'damage' => (localizedCopy ?? Copy.english).photoDamage,
      'panel' => (localizedCopy ?? Copy.english).photoPanel,
      'location' => (localizedCopy ?? Copy.english).photoLocation,
      'attendance' => (localizedCopy ?? Copy.english).photoAttendance,
      'document' => (localizedCopy ?? Copy.english).photoDocument,
      _ => (localizedCopy ?? Copy.english).photoOther,
    };
  }
}
