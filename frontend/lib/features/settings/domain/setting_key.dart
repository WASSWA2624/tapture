/// One app-wide preference, named once beside its default.
///
/// Features read [SettingKeys] rather than a raw string. [T] is the stored
/// type; a missing or mistyped value resolves to [defaultValue].
final class SettingKey<T> implements _NamedSetting {
  /// Creates a key. [name] is the wire name in the preferences map.
  const SettingKey(this.name, this.defaultValue);

  /// Stable wire name. Never a secret, token or credential.
  @override
  final String name;

  /// Used when the stored map omits [name] or the value is the wrong type.
  final T defaultValue;

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is _NamedSetting && other.name == name);
  }
}

/// Lets [SettingKey] compare equal across type arguments.
abstract interface class _NamedSetting {
  String get name;
}
