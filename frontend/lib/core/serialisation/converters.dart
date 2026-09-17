import 'package:json_annotation/json_annotation.dart';

part 'enum_wire_converter.dart';
part 'json_map_converter.dart';
part 'utc_date_time_converter.dart';

/// The converters every model reuses so a wire format does not follow a Dart
/// identifier that may be renamed.
abstract final class Converters {
  /// Date-times as UTC ISO-8601 strings.
  static const UtcDateTimeConverter utcDateTime = UtcDateTimeConverter();

  /// JSON objects as `Map<String, Object?>`.
  static const JsonMapConverter jsonMap = JsonMapConverter();
}
