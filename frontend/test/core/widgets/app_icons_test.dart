import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/widgets/app_icons.dart';

void main() {
  test('everyday actions use the glyphs people already know', () {
    expect(AppIcons.search, Icons.search);
    expect(AppIcons.edit, Icons.edit_outlined);
    expect(AppIcons.delete, Icons.delete_outline);
    expect(AppIcons.archive, Icons.archive_outlined);
    expect(AppIcons.add, Icons.add);
    expect(AppIcons.close, Icons.close);
    expect(AppIcons.back, Icons.arrow_back);
    expect(AppIcons.more, Icons.more_vert);
    expect(AppIcons.settings, Icons.settings_outlined);
    expect(AppIcons.camera, Icons.photo_camera_outlined);
    expect(AppIcons.download, Icons.download_outlined);
  });

  test('export saves to the device, so it shares the download glyph', () {
    expect(AppIcons.export, AppIcons.download);
  });

  test('dictation and audio recording are told apart', () {
    expect(AppIcons.dictate, isNot(AppIcons.recordAudio));
    expect(AppIcons.dictating, isNot(AppIcons.recordAudio));
    expect(AppIcons.recordAudio, isNot(AppIcons.stop));
  });

  test('actions a person could confuse never share a glyph', () {
    final List<IconData> distinct = <IconData>[
      AppIcons.add,
      AppIcons.edit,
      AppIcons.delete,
      AppIcons.archive,
      AppIcons.unarchive,
      AppIcons.duplicate,
      AppIcons.download,
      AppIcons.import,
      AppIcons.search,
      AppIcons.filter,
      AppIcons.pin,
      AppIcons.remove,
    ];
    expect(distinct.toSet(), hasLength(distinct.length));
  });

  testWidgets('share draws each platform own share glyph', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final IconData ios = AppIcons.share;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final IconData android = AppIcons.share;
    debugDefaultTargetPlatformOverride = null;

    expect(ios, Icons.ios_share);
    expect(android, Icons.share);
  });
}
