import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/feedback/haptics.dart';

void main() {
  test('each named pattern fires once', () {
    final List<String> played = <String>[];
    final Haptics haptics = Haptics.fake(played: played);

    haptics.shutter();
    haptics.save();
    haptics.warning();
    haptics.error();
    haptics.selection();

    expect(played, <String>[
      'shutter',
      'save',
      'warning',
      'error',
      'selection',
    ]);
    expect(played.toSet(), hasLength(5));
    expect(played[0], isNot(played[1]));
  });

  test('all five are suppressed when haptics are disabled', () {
    final List<String> played = <String>[];
    final Haptics haptics = Haptics.fake(played: played, enabled: false);

    haptics.shutter();
    haptics.save();
    haptics.warning();
    haptics.error();
    haptics.selection();

    expect(played, isEmpty);
  });

  test('reduced motion skips selection and keeps capture and save', () {
    final List<String> played = <String>[];
    final Haptics haptics = Haptics.fake(played: played, reduceMotion: true);

    haptics.shutter();
    haptics.save();
    haptics.warning();
    haptics.error();
    haptics.selection();

    expect(played, <String>['shutter', 'save', 'warning', 'error']);
  });
}
