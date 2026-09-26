import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/photo_picker.dart';
import 'package:tapture/core/widgets/photo_source_sheet.dart';

void main() {
  final Uint8List photo = Uint8List.fromList(<int>[1, 2, 3]);

  for (final String choice in <String>[
    Copy.captureTakePhoto,
    Copy.captureChoosePhoto,
  ]) {
    testWidgets('$choice returns the picked photo', (
      WidgetTester tester,
    ) async {
      final List<Result<List<Uint8List>>?> picked =
          <Result<List<Uint8List>>?>[];
      await _open(
        tester,
        PhotoPicker.fake(photos: <Uint8List>[photo], canTakePhoto: true),
        picked.add,
      );
      expect(find.text(Copy.captureTakePhoto), findsOneWidget);
      await tester.tap(find.text(choice));
      await tester.pumpAndSettle();

      final Result<List<Uint8List>>? result = picked.single;
      expect(result, isA<Success<List<Uint8List>>>());
      expect((result! as Success<List<Uint8List>>).value.single, photo);
    });
  }

  testWidgets('without a camera only Choose shows, and closing picks nothing', (
    WidgetTester tester,
  ) async {
    final List<Result<List<Uint8List>>?> picked = <Result<List<Uint8List>>?>[];
    await _open(
      tester,
      PhotoPicker.fake(photos: <Uint8List>[photo], canTakePhoto: false),
      picked.add,
    );
    expect(find.text(Copy.captureTakePhoto), findsNothing);
    expect(find.text(Copy.captureChoosePhoto), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    expect(picked, <Result<List<Uint8List>>?>[null]);
  });
}

Future<void> _open(
  WidgetTester tester,
  PhotoPicker picker,
  void Function(Result<List<Uint8List>>? picked) onPicked,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return TextButton(
              onPressed: () async {
                onPicked(
                  await showPhotoSourceSheet(
                    context,
                    picker: picker,
                    limit: 1,
                    longEdge: 1600,
                  ),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}
