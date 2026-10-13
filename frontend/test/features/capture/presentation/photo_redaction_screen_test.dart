import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/app/theme/app_theme.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/image_redaction.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/core/files/photo_privacy_service.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/presentation/photo_redaction_screen.dart';
import 'package:tapture/features/capture/presentation/redaction_editor.dart';

import '../../../support/factories.dart';

void main() {
  testWidgets('save confirms only after the marked photo policy is durable', (
    WidgetTester tester,
  ) async {
    final _Fixture fixture = (await tester.runAsync(_fixture))!;
    bool? result;
    await _pump(
      tester,
      fixture,
      fixture.photoId,
      (bool? saved) => result = saved,
    );
    expect(
      find.byKey(const ValueKey<String>('redaction-photo')),
      findsOneWidget,
    );
    expect(find.text(Copy.redactionCount(1)), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text(Copy.redactionSave));
      await Future<void>.delayed(const Duration(milliseconds: 40));
    });
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(find.byType(PhotoRedactionScreen), findsNothing);
    final Result<List<ImageRect>> saved = (await tester.runAsync(
      () => fixture.service.marks(fixture.photoId),
    ))!;
    expect((saved as Success<List<ImageRect>>).value, _marks);
  });

  testWidgets(
    'a failed policy write keeps the bitmap and masks open for retry',
    (WidgetTester tester) async {
      final _Fixture fixture = (await tester.runAsync(_fixture))!;
      bool? result;
      await _pump(
        tester,
        fixture,
        'missing-photo',
        (bool? saved) => result = saved,
      );
      await tester.runAsync(() async {
        await tester.tap(find.text(Copy.redactionSave));
        await Future<void>.delayed(const Duration(milliseconds: 40));
      });
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(find.byType(RedactionEditor), findsOneWidget);
      expect(find.text(Copy.redactionCount(1)), findsOneWidget);
      expect(find.text('That photo is no longer available.'), findsOneWidget);
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  _Fixture fixture,
  String photoId,
  ValueChanged<bool?> onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(brightness: Brightness.light),
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: TextButton(
            onPressed: () => unawaited(
              Navigator.of(context)
                  .push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (BuildContext _) => PhotoRedactionScreen(
                        photoId: photoId,
                        preview: (
                          bytes: img.encodePng(img.Image(width: 8, height: 8)),
                          width: 8,
                          height: 8,
                        ),
                        marks: _marks,
                        privacy: fixture.service,
                      ),
                    ),
                  )
                  .then(onResult),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<_Fixture> _fixture() async {
  final AppDatabase db = await seededDatabase(records: 1);
  addTearDown(db.close);
  final Directory documents = await Directory.systemTemp.createTemp(
    'tapture_redaction_ui_',
  );
  addTearDown(() => documents.delete(recursive: true));
  final StorageRoot root = StorageRoot.fake(documentsDirectory: documents);
  final Photo photo = await db.select(db.photos).getSingle();
  return _Fixture(
    photo.id,
    PhotoPrivacyService(
      db: db,
      files: FileReader(storageRoot: root),
      writer: FileWriter(storageRoot: root),
      clock: FixedClock(DateTime.utc(2026, 9, 30)),
      deviceId: 'device-a',
    ),
  );
}

const List<ImageRect> _marks = <ImageRect>[
  (x: 0, y: 0, width: 0.5, height: 0.5),
];

final class _Fixture {
  _Fixture(this.photoId, this.service);
  final String photoId;
  final PhotoPrivacyService service;
}
