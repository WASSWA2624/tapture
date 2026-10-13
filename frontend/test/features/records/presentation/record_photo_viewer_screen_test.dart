import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/features/records/domain/record_photo.dart';
import 'package:tapture/features/records/presentation/record_photo_viewer_screen.dart';

void main() {
  testWidgets('no saved photos says the photo is missing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(brightness: Brightness.light),
          home: const RecordPhotoViewerScreen(photos: <RecordPhoto>[]),
        ),
      ),
    );

    expect(find.text(Copy.missingPhoto), findsWidgets);
    expect(find.text(Copy.photoUnreadableRecovery), findsOneWidget);
  });
}
