import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:tapture/features/capture/domain/photo_draft.dart';

import '../../support/factories.dart';
import '../../support/pump_app.dart';

/// Offline widget frame and evidence fixtures for the project layout matrix.
abstract final class EvidenceLayoutHarness {
  static Uint8List photoBytes() => image.encodePng(
    image.Image(width: 32, height: 32)..clear(image.ColorRgb8(40, 80, 120)),
  );

  static PhotoDraft photo({String? parent}) {
    final seed = aPhoto();
    return PhotoDraft(
      id: seed.id,
      projectId: seed.projectId,
      relativePath: seed.relativePath,
      sha256: seed.sha256,
      photoType: 'Front',
      width: 32,
      height: 32,
      derivedFrom: parent,
    );
  }

  static Future<void> pump(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
    double textScale = 1,
    Brightness brightness = Brightness.light,
    bool outdoor = false,
    List<Override> overrides = const <Override>[],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pumpApp(
      tester,
      Builder(
        builder: (BuildContext context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: true,
          ),
          child: child,
        ),
      ),
      overrides: overrides,
      brightness: brightness,
      outdoor: outdoor,
      useScreenFonts: true,
    );
    await tester.pumpAndSettle();
  }
}
