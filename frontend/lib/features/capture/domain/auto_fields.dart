/// Automatic field values applied on first save with source `AUTO`.
abstract final class AutoFields {
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
