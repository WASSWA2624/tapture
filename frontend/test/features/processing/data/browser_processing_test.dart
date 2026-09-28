import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/ai/provider_registry.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/blob_file_reader.dart';
import 'package:tapture/core/files/blob_file_writer.dart';
import 'package:tapture/core/files/blob_store.dart';
import 'package:tapture/core/files/file_reader.dart';
import 'package:tapture/core/files/file_writer.dart';
import 'package:tapture/features/processing/data/processing_stage_worker.dart';
import 'package:tapture/features/processing/domain/processing_job.dart';
import 'package:tapture/features/settings/settings.dart';

import '../../../support/processing_fixture.dart';

void main() {
  test(
    'browser files pass every processing stage and cached audio is not sent twice',
    () async {
      final ProcessingFixture fixture = await ProcessingFixture.open();
      await fixture.addField('serial', required: true);
      final Attachment audio = await fixture.addAudio(0);
      final Photo photo = await fixture.db
          .select(fixture.db.photos)
          .getSingle();
      final Map<String, Uint8List> backing = <String, Uint8List>{};
      final BlobStore store = BlobStore.memory(backing: backing);
      final FileReader files = BlobFileReader(store);
      final FileWriter writer = BlobFileWriter(store);
      final Uint8List original = Uint8List.fromList(
        img.encodeJpg(img.Image(width: 300, height: 200)),
      );
      final String photoPath =
          'projects/${fixture.project.folderName}/${photo.relativePath}';
      await writer.write(Stream<List<int>>.value(original), photoPath);
      await writer.write(
        Stream<List<int>>.value(<int>[1, 2, 3]),
        'projects/${fixture.project.folderName}/${audio.relativePath}',
      );
      final CountingOcr ocr = CountingOcr('must not run');
      final ScriptedExtraction provider = ScriptedExtraction(<String>[
        '{"fields":{}}',
      ], transcript: 'A recorded observation');
      final ProcessingStageWorker worker = ProcessingStageWorker(
        db: fixture.db,
        clock: fixture.clock,
        deviceId: 'device-a',
        ids: fixture.ids,
        storageRoot: fixture.storageRoot,
        files: files,
        writer: writer,
        isBrowser: true,
        ocr: ocr,
        providers: ProviderRegistry.keyless(proxy: provider),
        settings: SettingsStore.fake(),
      );
      final ProcessingJob job = await fixture.job();
      for (final JobStage stage in JobStage.values) {
        await worker.perform(stage, job, CancellationToken());
      }
      expect(ocr.reads, 0);
      expect(provider.requests, hasLength(1));
      final String compressed = provider.requests.single.imagePaths.single;
      expect(compressed, startsWith('.cache/upload/'));
      expect(
        img.decodeJpg(
          (await files.read('$compressed.ocr.jpg') as Success<Uint8List>).value,
        ),
        isNotNull,
      );
      expect(provider.transcriptions.single.clipPath, startsWith('projects/'));
      expect(
        (await files.read(photoPath) as Success<Uint8List>).value,
        original,
      );
      await worker.perform(JobStage.online, job);
      expect(provider.transcriptions, hasLength(1));
      expect(
        await worker.egressSummary(job),
        isA<({int imageCount, int payloadBytes})>(),
      );
    },
  );
}
