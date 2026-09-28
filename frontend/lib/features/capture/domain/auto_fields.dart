import 'package:tapture/core/location/location_service.dart';
import 'package:tapture/features/templates/templates.dart';

/// Automatic field values applied on first save with source `AUTO`.
abstract final class AutoFields {
  /// Resolves declared defaults and automatic sources at the save instant.
  /// Existing typed and context values take precedence when the writer merges.
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
    final Map<String, Object?> values = <String, Object?>{};
    for (final FieldDef field in fields) {
      final Object? value = switch (field.autoFill) {
        AutoFill.now => autoFillDates ? nowUtc.toIso8601String() : null,
        AutoFill.today =>
          autoFillDates ? _formatDate(nowUtc, 'yyyy-MM-dd') : null,
        AutoFill.time => autoFillDates ? _formatTime(nowUtc) : null,
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

  /// Builds auto values honouring [autoFill] flags and [dateFormat].
  static Map<String, Object?> build({
    required DateTime nowUtc,
    required String operatorId,
    required String deviceId,
    required Map<String, bool> autoFill,
    String dateFormat = 'yyyy-MM-dd',
    double? gpsLat,
    double? gpsLon,
  }) {
    final Map<String, Object?> out = <String, Object?>{};
    void put(String key, Object? value) {
      if (autoFill[key] ?? true) {
        out[key] = value;
      }
    }

    put('capturedAt', nowUtc.toIso8601String());
    put('date', _formatDate(nowUtc, dateFormat));
    put('time', _formatTime(nowUtc));
    put('operator', operatorId);
    put('device', deviceId);
    if (gpsLat != null && gpsLon != null) {
      put('gpsLat', gpsLat);
      put('gpsLon', gpsLon);
    }
    return out;
  }

  static String _formatDate(DateTime utc, String pattern) {
    final DateTime local = utc.toLocal();
    final String y = local.year.toString().padLeft(4, '0');
    final String m = local.month.toString().padLeft(2, '0');
    final String d = local.day.toString().padLeft(2, '0');
    return pattern
        .replaceAll('yyyy', y)
        .replaceAll('MM', m)
        .replaceAll('dd', d);
  }

  static String _formatTime(DateTime utc) {
    final DateTime local = utc.toLocal();
    final String h = local.hour.toString().padLeft(2, '0');
    final String m = local.minute.toString().padLeft(2, '0');
    final String s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
