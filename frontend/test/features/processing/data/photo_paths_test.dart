import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/ai/ocr_service.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/features/processing/data/photo_paths.dart';
import 'package:tapture/features/processing/data/record_bundle.dart';
import 'package:tapture/features/processing/data/record_bundle_loader.dart';

import '../../../support/factories.dart';

void main() {
  test('paths resolve under the root and the original is only read', () async {
    final AppDatabase db = await seededDatabase(records: 1);
    addTearDown(db.close);
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture_photo_paths_',
    );
    addTearDown(() {
      if (documents.existsSync()) {
        documents.deleteSync(recursive: true);
      }
    });
    final RecordRow record = await db.select(db.records).getSingle();
    final File original = File(
      '${documents.path}/Tapture/projects/seeded-project/'
      'photos/${record.id}/img-0.jpg',
    );
    await original.parent.create(recursive: true);
    final List<int> originalBytes = paintOcrPlate('SN1');
    await original.writeAsBytes(originalBytes);
    final RecordBundle bundle = await RecordBundleLoader(
      db: db,
    ).load(record.id);
    final PhotoPaths paths = PhotoPaths(
      storageRoot: StorageRoot.fake(documentsDirectory: documents),
    );
    final Photo photo = bundle.photos.single;

    final String source = await paths.source(bundle, photo);
    final List<String> compressed = await paths.compressed(bundle);
    final String prepared = await paths.prepared(bundle, photo);
    final Directory root = await paths.root();

    expect(File(source).absolute.path, original.absolute.path);
    expect(compressed, hasLength(1));
    expect(File(compressed.single).existsSync(), isTrue);
    expect(
      compressed.single,
      '${root.path}/${await paths.compressedRelative(bundle, photo)}',
    );
    expect(prepared, '${compressed.single}.ocr.jpg');
    expect(await original.readAsBytes(), originalBytes);
  });
}
