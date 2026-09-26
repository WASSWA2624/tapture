import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/processing/domain/background_ocr.dart';

void main() {
  bool run({
    bool enabled = true,
    bool charging = true,
    bool idle = true,
    bool foreground = false,
  }) {
    return BackgroundOcr.shouldRun(
      enabled: enabled,
      charging: charging,
      idle: idle,
      foreground: foreground,
    );
  }

  test('charging, idle and in the background it may run', () {
    expect(run(), isTrue);
  });

  test('off by default means never', () {
    expect(run(enabled: false), isFalse);
  });

  test('it needs both charging and idle', () {
    expect(run(charging: false), isFalse);
    expect(run(idle: false), isFalse);
  });

  test('a resume stops it: nothing runs in the foreground', () {
    expect(run(foreground: true), isFalse);
  });
}
