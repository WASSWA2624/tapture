import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/copy/copy.dart';
import 'package:tapture/core/files/blob_store_io.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/feedback/data/feedback_repository_impl.dart';
import 'package:tapture/features/feedback/domain/feedback_archive.dart';
import 'package:tapture/features/feedback/domain/feedback_context.dart';
import 'package:tapture/features/feedback/domain/feedback_entry.dart';
import 'package:tapture/features/feedback/domain/feedback_filter.dart';
import 'package:tapture/features/feedback/domain/feedback_workbook.dart';
import 'package:tapture/features/settings/domain/friction_log.dart';
import 'package:tapture/features/settings/presentation/friction_log_button.dart';

import '../../../support/factories.dart';
import '../../../support/pump_app.dart';

void main() {
  test(
    'a trial report survives a native store restart with its screenshot bytes',
    () async {
      final Directory folder = await Directory.systemTemp.createTemp(
        'tapture-friction-',
      );
      addTearDown(() => folder.delete(recursive: true));
      final Clock clock = FixedClock(DateTime.utc(2026, 10, 1));
      FeedbackRepositoryImpl open() => FeedbackRepositoryImpl(
        store: folderBlobStore(() async => folder),
        clock: clock,
        ids: UuidV7Service.sequence(clock),
      );
      final FeedbackRepositoryImpl repository = open();
      final FrictionLog log = FrictionLog(repository: repository);
      final FeedbackContext context =
          FeedbackContext.fromJson(<String, Object?>{
            ...aFeedbackEntry().context.toJson(),
            'screen': 'Capture',
            'project_id': 'p1',
            'last_action': 'Save raw',
            'field_trial': true,
            'operator_name': 'Ada',
          });
      final FeedbackEntry entry = (await log.logFriction(
        context: context,
        note: 'Shutter stuck',
        screenshot: aFeedbackPng,
      )).getOrThrow();
      expect(await File('${folder.path}/index.json').exists(), isTrue);
      expect(
        await File('${folder.path}/shots/${entry.id}.png').readAsBytes(),
        aFeedbackPng,
      );
      final FeedbackRepositoryImpl restarted = open();
      final List<FeedbackEntry> restored = await restarted.watch().first;
      expect(restored.single.id, entry.id);
      expect(restored.single.context.screen, 'Capture');
      expect(restored.single.context.projectId, 'p1');
      expect(restored.single.context.lastAction, 'Save raw');
      expect(restored.single.context.operatorName, 'Ada');
      expect(restored.single.context.fieldTrial, isTrue);
      final List<Uint8List> screenshots = (await restarted.screenshots(
        entry.id,
      )).getOrThrow();
      expect(screenshots, <Uint8List>[aFeedbackPng]);
      final FeedbackWorkbook book = FeedbackWorkbook(
        entries: restored,
        screenshots: <String, Uint8List>{entry.id: screenshots.single},
        filter: const FeedbackFilter(),
        generatedAtUtc: DateTime.utc(2026, 10, 1),
        utcOffset: Duration.zero,
        timeZone: 'UTC',
        generatedBy: 'Ada',
      );
      final Archive archive = ZipDecoder().decodeBytes(
        FeedbackArchive.encode(FeedbackArchive(workbook: book)),
      );
      expect(
        archive.findFile('screenshots/${entry.reference}.png')!.content,
        aFeedbackPng,
      );
      final Archive workbook = ZipDecoder().decodeBytes(
        archive.findFile(book.fileName)!.content,
      );
      final String strings = workbook.files
          .where((ArchiveFile file) => file.name.endsWith('.xml'))
          .map((ArchiveFile file) => utf8.decode(file.content))
          .join('\n');
      for (final String value in <String>[
        'Capture',
        'p1',
        'Save raw',
        'Ada',
        'Shutter stuck',
        'Last Action',
        'Field Trial',
      ]) {
        expect(strings, contains(value));
      }
    },
  );

  test('a note and screenshot are both optional', () async {
    final FeedbackRepositoryImpl repository = FeedbackRepositoryImpl.memory();
    final FeedbackEntry entry = (await FrictionLog(
      repository: repository,
    ).logFriction(context: aFeedbackEntry().context)).getOrThrow();
    expect(entry.message, Copy.frictionLogAction);
    expect(entry.hasScreenshot, isFalse);
  });

  testWidgets('the action is absent when the trial flag is off', (
    WidgetTester tester,
  ) async {
    await pumpApp(
      tester,
      FrictionLogButton(
        trial: false,
        onReport: () => fail('No report in an ordinary build.'),
      ),
    );
    expect(find.byTooltip(Copy.frictionLogAction), findsNothing);
  });
}
