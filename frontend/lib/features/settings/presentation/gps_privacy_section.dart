import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/core/widgets/fields/app_switch_tile.dart';

/// Location stays off until someone turns it on, and exports can omit it.
final class GpsPrivacySection extends StatelessWidget {
  /// Creates the section.
  const GpsPrivacySection({
    this.gpsOn = false,
    this.excludeCoordinates = true,
    this.onGps,
    this.onExclude,
    this.onRemove,
    this.removed,
    super.key,
  });

  /// Whether captures store coordinates. Off by default.
  final bool gpsOn;

  /// Whether exports drop coordinates. On by default.
  final bool excludeCoordinates;

  /// Flips capture location.
  final ValueChanged<bool>? onGps;

  /// Flips export exclusion.
  final ValueChanged<bool>? onExclude;

  /// Removes coordinates already stored. Returns how many records changed.
  final Future<int> Function()? onRemove;

  /// Count from the last removal, when one has run.
  final int? removed;

  /// Drops coordinate fields and returns how many records changed.
  static int strip(List<Map<String, Object?>> records) {
    var changed = 0;
    for (final Map<String, Object?> record in records) {
      final int before = record.length;
      record.removeWhere((String key, Object? _) => _coordinate(key));
      if (record.length != before) {
        changed++;
      }
    }
    return changed;
  }

  /// Whether an export value named [key] is a coordinate.
  static bool excluded(String key) => _coordinate(key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        AppSwitchTile(
          key: const ValueKey<String>('gps-capture'),
          title: Copy.gpsPrivacyCapture,
          value: gpsOn,
          onChanged: (bool value) => onGps?.call(value),
        ),
        AppSwitchTile(
          key: const ValueKey<String>('gps-exclude'),
          title: Copy.gpsPrivacyExclude,
          value: excludeCoordinates,
          onChanged: (bool value) => onExclude?.call(value),
        ),
        AppButton(
          key: const ValueKey<String>('gps-remove'),
          label: Copy.gpsPrivacyRemove,
          onPressed: () => unawaited(_remove()),
        ),
        if (removed != null) Text(Copy.gpsPrivacyRemoved(removed!)),
      ],
    );
  }

  Future<void> _remove() async {
    await onRemove?.call();
  }
}

bool _coordinate(String key) {
  final String folded = key.toLowerCase();
  return folded == 'lat' ||
      folded == 'lon' ||
      folded == 'latitude' ||
      folded == 'longitude' ||
      folded == 'gps' ||
      folded == 'gpslat' ||
      folded == 'gpslon';
}
