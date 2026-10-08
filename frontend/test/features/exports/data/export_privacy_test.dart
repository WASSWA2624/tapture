import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:tapture/core/bundle/bundle.dart';
import 'package:tapture/core/concurrency/cancellation_token.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/export/export_request.dart';
import 'package:tapture/core/export/image_redaction.dart';
import 'package:tapture/core/files/document_picker.dart';
import 'package:tapture/features/cloud/data/export_upload_guard.dart';
import 'package:tapture/features/exports/domain/deliverable_repository.dart';
import 'package:tapture/features/exports/domain/export_repository.dart';

import 'export_privacy_fixture.dart';

void main() {
  test(
    'required consent omits and names records; provider approval cannot supply it',
    () async {
      final ExportPrivacyFixture fixture = await ExportPrivacyFixture.open();
      await fixture.record('allowed', consent: true);
      await fixture.record('held', consent: false);
      final PreparedDeliverable prepared = await fixture.prepare();
      expect(prepared.request.omittedRecordIds, <String>['held']);
      expect(prepared.request.records.map((row) => row.id), <String>[
        'allowed',
      ]);
      final DeliverableEntry written = privacyValue(
        await fixture.reports.write(
          prepared.request.copyWith(
            scope: (
              kind: ExportScopeKind.context,
              context: '12.345678',
              from: null,
              to: null,
              filter: <String, Object?>{
                'context': <String, Object?>{
                  'site': <String>['Kasubi'],
                  'gps_latitude': <String>['12.345678'],
                  'survey_fix': <String>['45.987654'],
                },
              },
            ),
          ),
          cancel: CancellationToken(),
        ),
      );
      final Archive archive = ZipDecoder().decodeBytes(
        fixture.file(written.path).readAsBytesSync(),
      );
      final ArchiveFile data = archive.files.singleWhere(
        (ArchiveFile file) => file.name == 'outputs/records.json',
      );
      final Map<String, Object?> json =
          jsonDecode(utf8.decode(data.content)) as Map<String, Object?>;
      expect(jsonEncode(json), contains('allowed'));
      expect(jsonEncode(json), isNot(contains('held')));
      expect(jsonEncode(json), isNot(contains('survey_fix')));
      expect(jsonEncode(json), isNot(contains('12.345678')));
      expect(jsonEncode(json), isNot(contains('45.987654')));
      final ArchiveFile manifest = archive.files.singleWhere(
        (ArchiveFile file) => file.name == 'manifest.json',
      );
      expect(utf8.decode(manifest.content), isNot(contains('12.345678')));
      expect(utf8.decode(manifest.content), isNot(contains('45.987654')));
      expect(
        jsonEncode(
          privacyValue(await fixture.reports.replay(written.id)).scope.filter,
        ),
        contains('12.345678'),
      );
      expect(
        privacyValue(
          await fixture.reports.privacySummary(written.id),
        ).omittedRecordIds,
        <String>['held'],
      );
    },
  );

  test(
    'real package and workbook carry protected pixels and no GPS rows or audit values',
    () async {
      final ExportPrivacyFixture fixture = await ExportPrivacyFixture.open(
        blurFaces: true,
        detector: const FixedPrivacyFaces(),
      );
      await fixture.record('allowed', consent: true);
      await fixture.record('held', consent: false);
      final Uint8List original = await fixture.photo('photo-1', 'allowed');
      await fixture.photo('private-photo', 'held');
      privacyValue(
        await fixture.privacy.setMarks('photo-1', const <ImageRect>[
          (x: 0.125, y: 0.125, width: 0.25, height: 0.25),
        ]),
      );
      final ExportedPackage written = privacyValue(
        await fixture.packages.exportProject(
          fixture.project.id,
          cancel: CancellationToken(),
        ),
      );
      final StoredBundle stored = written.package as StoredBundle;
      final File artifact = fixture.file(stored.relativePath);
      final InspectedBundle inspected = privacyValue(
        await BundleReader.inspect(
          PickedFile(artifact, 'protected.zip', artifact.lengthSync()),
        ),
      );
      addTearDown(inspected.close);
      expect(inspected.rowsOf('records').map((row) => row['id']), <String>[
        'allowed',
      ]);
      expect(inspected.rowsOf('photos'), hasLength(1));
      expect(
        jsonEncode(inspected.rowsOf('records')),
        isNot(contains('12.345678')),
      );
      expect(
        jsonEncode(inspected.rowsOf('records')),
        isNot(contains('45.987654')),
      );
      expect(
        jsonEncode(inspected.rowsOf('record_fields')),
        isNot(contains('12.345678')),
      );
      expect(
        inspected
            .rowsOf('record_fields')
            .any((row) => row['field_key'] == 'position'),
        isFalse,
      );
      final Map<String, Object?> photo = inspected.rowsOf('photos').single;
      expect(photo['gps_lat'], isNull);
      expect(photo['gps_lon'], isNull);
      final Uint8List sent = privacyValue(
        await inspected.readEntry(photo['relative_path']! as String),
      );
      final img.Image pixels = img.decodeImage(sent)!;
      final img.Image clear = img.decodeImage(original)!;
      expect(pixels.getPixel(1, 1).r, 0);
      expect(pixels.getPixel(4, 4).r, isNot(clear.getPixel(4, 4).r));
      expect(pixels.getPixel(0, 0).r, clear.getPixel(0, 0).r);
      expect(
        fixture.file(fixture.photoPath('photo-1')).readAsBytesSync(),
        original,
      );
      expect(
        jsonEncode(inspected.rowsOf('audit_log')),
        isNot(contains('12.345678')),
      );
      final Map<String, Object?> summary =
          jsonDecode(
                utf8.decode(
                  privacyValue(
                    await inspected.readEntry('privacy-summary.json'),
                  ),
                ),
              )
              as Map<String, Object?>;
      expect(summary['omittedRecordIds'], <Object?>['held']);
      expect(summary['photoFaceCounts'], <String, Object?>{'photo-1': 1});
      final Archive workbook = ZipDecoder().decodeBytes(
        privacyValue(await inspected.readEntry(BundleFormat.workbook)),
      );
      final String xml = workbook.files
          .where((ArchiveFile file) => file.name.endsWith('.xml'))
          .map((ArchiveFile file) => utf8.decode(file.content))
          .join();
      expect(xml, contains(photo['relative_path']));
      expect(xml, isNot(contains('12.345678')));
    },
  );

  test(
    'saved artifact and cloud retry are refused after a new mark; replay reapplies it',
    () async {
      final ExportPrivacyFixture fixture = await ExportPrivacyFixture.open();
      await fixture.record('allowed', consent: true);
      final Uint8List original = await fixture.photo('photo-1', 'allowed');
      final DeliverableEntry first = privacyValue(
        await fixture.reports.write(
          (await fixture.prepare()).request,
          cancel: CancellationToken(),
        ),
      );
      expect(await fixture.reports.allowShare(first.id), isA<Success<void>>());
      privacyValue(
        await fixture.privacy.setMarks('photo-1', const <ImageRect>[
          (x: 0, y: 0, width: 0.5, height: 0.5),
        ]),
      );
      expect(
        await fixture.reports.allowShare(first.id),
        isA<FailureResult<void>>(),
      );
      final ExportUploadGuard guard = ExportUploadGuard(
        db: fixture.db,
        storage: fixture.storage,
        policy: fixture.reports,
      );
      expect(
        await guard.check(fixture.file(first.path).path),
        isA<FailureResult<void>>(),
      );
      final DeliverableEntry second = privacyValue(
        await fixture.reports.write(
          privacyValue(await fixture.reports.replay(first.id)),
          cancel: CancellationToken(),
        ),
      );
      final Archive archive = ZipDecoder().decodeBytes(
        fixture.file(second.path).readAsBytesSync(),
      );
      final ArchiveFile photo = archive.files.singleWhere(
        (ArchiveFile file) => file.name.startsWith('photos/'),
      );
      expect(
        img.decodeImage(Uint8List.fromList(photo.content))!.getPixel(2, 2).r,
        0,
      );
      expect(
        fixture.file(fixture.photoPath('photo-1')).readAsBytesSync(),
        original,
      );
    },
  );

  test(
    'unsupported detector fails closed and never records a clear export',
    () async {
      final ExportPrivacyFixture fixture = await ExportPrivacyFixture.open(
        blurFaces: true,
      );
      await fixture.record('allowed', consent: true);
      await fixture.photo('photo-1', 'allowed');
      expect(
        await fixture.packages.exportProject(
          fixture.project.id,
          cancel: CancellationToken(),
        ),
        isA<FailureResult<ExportedPackage>>(),
      );
      expect(await fixture.db.select(fixture.db.exports).get(), isEmpty);
    },
  );

  test(
    'an edit during archive publication discards the obsolete artifact',
    () async {
      final ExportPrivacyFixture fixture = await ExportPrivacyFixture.open();
      await fixture.record('allowed', consent: true);
      await fixture.photo('photo-1', 'allowed');
      Future<Result<void>>? edit;
      final Result<DeliverableEntry> result = await fixture.reports.write(
        (await fixture.prepare()).request,
        cancel: CancellationToken(),
        onProgress: (DeliverableProgress step) {
          if (step.stage == 'archive' && step.fraction == 1 && edit == null) {
            edit = fixture.privacy.setMarks('photo-1', const <ImageRect>[
              (x: 0, y: 0, width: 0.5, height: 0.5),
            ]);
          }
        },
      );
      await edit;
      expect(result, isA<FailureResult<DeliverableEntry>>());
      expect(await fixture.db.select(fixture.db.exports).get(), isEmpty);
    },
  );
}
