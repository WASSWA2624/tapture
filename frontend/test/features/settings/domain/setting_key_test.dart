import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/settings/domain/setting_key.dart';

void main() {
  test('a key keeps the name and default it was declared with', () {
    const SettingKey<bool> key = SettingKey<bool>('capture.gps', false);
    expect(key.name, 'capture.gps');
    expect(key.defaultValue, isFalse);
  });

  test('keys with the same name compare equal regardless of type argument', () {
    const SettingKey<bool> left = SettingKey<bool>('capture.gps', false);
    const SettingKey<Object?> right = SettingKey<Object?>('capture.gps', false);
    expect(left, right);
    expect(right, left);
    expect(left.hashCode, right.hashCode);
    expect(left == const SettingKey<bool>('capture.grid', false), isFalse);
  });
}
