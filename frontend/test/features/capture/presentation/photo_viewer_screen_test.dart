import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/widgets/app_button.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/presentation/photo_viewer_screen.dart';

void main() {
  testWidgets(
    'saved masks are reachable from the labelled compact viewer tools',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const PhotoDraft photo = PhotoDraft(
        id: 'photo-a',
        projectId: 'project-a',
        relativePath: 'photos/photo-a.jpg',
        sha256: 'photo-sha',
      );
      final ValueNotifier<List<PhotoDraft>> photos =
          ValueNotifier<List<PhotoDraft>>(<PhotoDraft>[photo]);
      addTearDown(photos.dispose);
      PhotoDraft? opened;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: PhotoViewerScreen(
            photos: photos,
            onRedact: (PhotoDraft next) => opened = next,
          ),
        ),
      );
      final Finder redact = find.widgetWithText(AppButton, Copy.redactionTitle);
      await tester.ensureVisible(redact);
      await tester.tap(redact);
      await tester.pumpAndSettle();
      expect(opened?.id, photo.id);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('no photos says the photo is missing', (
    WidgetTester tester,
  ) async {
    final ValueNotifier<List<PhotoDraft>> photos =
        ValueNotifier<List<PhotoDraft>>(<PhotoDraft>[]);
    addTearDown(photos.dispose);

    await tester.pumpWidget(
      MaterialApp(home: PhotoViewerScreen(photos: photos)),
    );

    expect(find.text(Copy.photo), findsOneWidget);
    expect(find.text(Copy.missingPhoto), findsOneWidget);
  });
}
