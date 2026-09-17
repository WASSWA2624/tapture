part of 'converters.dart';

/// Encodes an enum through an explicit wire-name map, never [Enum.name].
///
/// An unknown wire name throws [FormatException] rather than picking a
/// default.
final class EnumWireConverter<T extends Enum>
    implements JsonConverter<T, String> {
  /// [wire] maps each value to the stable name stored on the wire.
  const EnumWireConverter(this.wire);

  /// Value to wire name. The Dart identifier is not used.
  final Map<T, String> wire;

  @override
  T fromJson(String json) {
    for (final MapEntry<T, String> entry in wire.entries) {
      if (entry.value == json) {
        return entry.key;
      }
    }
    throw const FormatException('unknown enum wire name');
  }

  @override
  String toJson(T object) {
    final String? name = wire[object];
    if (name == null) {
      throw const FormatException('enum value has no wire name');
    }
    return name;
  }
}
