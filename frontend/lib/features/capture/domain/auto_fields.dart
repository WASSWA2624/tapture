import 'package:intl/intl.dart';
import 'package:tapture/core/location/geo_fix.dart';
import 'package:tapture/features/templates/domain/domain.dart';

/// Automatic field values applied on first save with source `AUTO`.
abstract final class AutoFields {
  /// Resolves declared defaults and automatic sources at the save instant.
  /// Existing typed and context values take precedence when the writer merges.
  ///
  /// Dates and times are the device's local calendar at [nowUtc], formatted
  /// through `intl` in the stored ISO shapes (FE-L10N-04); a screen formats
  /// them for display from the project setting.
  static Map<String, Object?> forTemplate({
    required Iterable<FieldDef> fields,
    required DateTime nowUtc,
    required String operatorName,
    required String deviceId,
    required int? sequence,
    required Map<String, String> context,
    required GeoFix? location,
    bool autoFillDates = true,
  }) {
    final DateTime local = nowUtc.toLocal();
    final Map<String, Object?> values = <String, Object?>{};
    for (final FieldDef field in fields) {
      final Object? value = switch (field.autoFill) {
        AutoFill.now => autoFillDates ? nowUtc.toIso8601String() : null,
        AutoFill.today => autoFillDates ? _date.format(local) : null,
        AutoFill.time => autoFillDates ? _time.format(local) : null,
        AutoFill.operator => operatorName,
        AutoFill.device => deviceId,
        AutoFill.sequence => sequence,
        AutoFill.context => context[field.fieldKey],
        AutoFill.gps => _gpsValue(field.fieldKey, location),
        null => field.defaultValue,
      };
      if (value != null) values[field.fieldKey] = value;
    }
    if (location != null) {
      values.addAll(<String, Object?>{
        'gps_latitude': location.latitude,
        'gps_longitude': location.longitude,
        'gps_accuracy_m': location.accuracyMetres,
        'gps_captured_at': location.capturedAt.toIso8601String(),
      });
    }
    return values;
  }

  static Object? _gpsValue(String key, GeoFix? fix) {
    if (fix == null) return null;
    if (key.contains('accuracy')) return fix.accuracyMetres;
    if (key.contains('captured')) return fix.capturedAt.toIso8601String();
    if (key.contains('latitude') || key == 'gpsLat') return fix.latitude;
    if (key.contains('longitude') || key == 'gpsLon') return fix.longitude;
    return <String, Object?>{
      'latitude': fix.latitude,
      'longitude': fix.longitude,
      'accuracy': fix.accuracyMetres,
    };
  }
}

/// The stored date shape: ISO 8601 calendar date, in ASCII digits whatever
/// the device language.
final DateFormat _date = DateFormat('yyyy-MM-dd', _storedLocale);

/// The stored time shape: 24-hour clock with seconds.
final DateFormat _time = DateFormat('HH:mm:ss', _storedLocale);

/// The locale stored values are written in; its symbols ship with `intl`.
const String _storedLocale = 'en_US';
