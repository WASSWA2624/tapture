import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/features/feedback/domain/feedback_device_type.dart';

void main() {
  test('fromWire keeps known names and falls back to mobile', () {
    expect(FeedbackDeviceType.fromWire('desktop'), FeedbackDeviceType.desktop);
    expect(FeedbackDeviceType.fromWire('nope'), FeedbackDeviceType.mobile);
  });
}
