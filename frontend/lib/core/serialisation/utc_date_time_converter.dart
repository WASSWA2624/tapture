part of 'converters.dart';

/// Encodes a [DateTime] as a UTC ISO-8601 string, regardless of the device's
/// offset.
final class UtcDateTimeConverter implements JsonConverter<DateTime, String> {
  /// Creates the converter.
  const UtcDateTimeConverter();

  @override
  DateTime fromJson(String json) {
    return DateTime.parse(json).toUtc();
  }

  @override
  String toJson(DateTime object) {
    return object.toUtc().toIso8601String();
  }
}
