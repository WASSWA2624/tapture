import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/ids/uuid_service.dart';
import 'package:tapture/core/location/location_service.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/capture/domain/auto_fields.dart';
import 'package:tapture/features/capture/domain/caption_apply.dart';
import 'package:tapture/features/capture/domain/capture_reset.dart';
import 'package:tapture/features/capture/domain/capture_session.dart';
import 'package:tapture/features/capture/domain/gps_capture.dart';
import 'package:tapture/features/capture/domain/identifier_lookup.dart';
import 'package:tapture/features/capture/domain/image_quality.dart';
import 'package:tapture/features/capture/domain/photo_draft.dart';
import 'package:tapture/features/capture/domain/photo_rotate.dart';
import 'package:tapture/features/capture/domain/record_number.dart';
import 'package:tapture/features/capture/domain/save_and_analyse.dart';
import 'package:tapture/features/capture/domain/save_raw.dart';
import 'package:tapture/features/capture/domain/transcript_store.dart';
import 'package:tapture/features/processing/domain/processing_repository.dart';

void main() {
  group('image_quality', () {
    test('dark blurry overexposed smallText clean', () {
      expect(
        ImageQuality.score(Uint8List.fromList(List<int>.filled(200, 10))),
        ImageQualityFinding.dark,
      );
      expect(
        ImageQuality.score(Uint8List.fromList(List<int>.filled(200, 240))),
        ImageQualityFinding.overexposed,
      );
      expect(
        ImageQuality.score(Uint8List.fromList(List<int>.filled(200, 120))),
        ImageQualityFinding.blurry,
      );
      final Uint8List busy = Uint8List(512);
      for (int i = 0; i < busy.length; i++) {
        busy[i] = (i % 2 == 0) ? 30 : 220;
      }
      expect(ImageQuality.score(busy), isNot(ImageQualityFinding.clean));
      final Uint8List mid = Uint8List(512);
      for (int i = 0; i < mid.length; i++) {
        mid[i] = 100 + (i % 20);
      }
      expect(
        ImageQuality.score(mid),
        anyOf(
          ImageQualityFinding.clean,
          ImageQualityFinding.smallText,
          ImageQualityFinding.blurry,
        ),
      );
    });
  });

  group('photo_rotate', () {
    test('metadata only', () {
      const PhotoDraft photo = PhotoDraft(
        id: '1',
        projectId: 'p',
        relativePath: 'a.jpg',
        sha256: 'h',
      );
      final PhotoDraft rotated = PhotoRotate.apply(photo, 90);
      expect(rotated.rotationDegrees, 90);
      expect(rotated.sha256, photo.sha256);
      expect(rotated.relativePath, photo.relativePath);
      expect(PhotoRotate.revert(rotated).rotationDegrees, 0);
    });
  });

  group('caption targets', () {
    const List<String> tray = <String>['a', 'b', 'c'];

    test('one photo is its own target', () {
      expect(
        CaptionApply.targets(
          visibleIds: const <String>['a'],
          selectedIds: const <String>{},
        ),
        <String>['a'],
      );
    });

    test('with none selected every visible photo is a target', () {
      expect(
        CaptionApply.targets(visibleIds: tray, selectedIds: const <String>{}),
        tray,
      );
    });

    test('a selection narrows the targets and keeps tray order', () {
      expect(
        CaptionApply.targets(
          visibleIds: tray,
          selectedIds: const <String>{'c', 'a', 'gone'},
        ),
        <String>['a', 'c'],
      );
    });

    test('shared text is the caption all targets hold', () {
      const Map<String, String> captions = <String, String>{
        'a': 'Site',
        'b': 'Site',
        'c': 'Pump',
      };
      expect(
        CaptionApply.sharedText(
          ids: const <String>['a', 'b'],
          captions: captions,
        ),
        'Site',
      );
      expect(CaptionApply.sharedText(ids: tray, captions: captions), '');
      expect(
        CaptionApply.sharedText(ids: const <String>[], captions: captions),
        '',
      );
      expect(
        CaptionApply.sharedText(
          ids: const <String>['a', 'x'],
          captions: captions,
        ),
        '',
      );
    });
  });

  group('caption_apply', () {
    test('append replace independence', () {
      final List<CaptionWrite> writes = CaptionApply.apply(
        photoIds: <String>['a', 'b'],
        text: 'new',
        mode: CaptionApplyMode.append,
        existing: const <String, String>{'a': 'old'},
      );
      expect(writes, hasLength(2));
      expect(writes[0].text, 'old\nnew');
      expect(writes[1].text, 'new');
      final List<CaptionWrite> replaced = CaptionApply.apply(
        photoIds: <String>['a'],
        text: 'x',
        mode: CaptionApplyMode.replace,
        existing: const <String, String>{'a': 'old'},
      );
      expect(replaced.single.previousText, 'old');
      expect(replaced.single.text, 'x');
    });
  });

  group('identifier_lookup', () {
    test('record reference none duplicates', () {
      expect(
        IdentifierLookup.resolve(
          identifier: 'A',
          recordIds: <String>['r1'],
        ).kind,
        IdentifierOutcomeKind.record,
      );
      expect(
        IdentifierLookup.resolve(
          identifier: 'A',
          recordIds: const <String>[],
          referenceKey: 'ref',
        ).kind,
        IdentifierOutcomeKind.reference,
      );
      expect(
        IdentifierLookup.resolve(
          identifier: 'A',
          recordIds: const <String>[],
        ).kind,
        IdentifierOutcomeKind.none,
      );
      expect(
        IdentifierLookup.resolve(
          identifier: 'A',
          recordIds: <String>['r1', 'r2'],
        ).kind,
        IdentifierOutcomeKind.duplicates,
      );
    });
  });

  group('auto_fields record_number gps', () {
    test('auto fields with frozen clock', () {
      final DateTime now = DateTime.utc(2026, 9, 22, 12, 0, 0);
      final Map<String, Object?> values = AutoFields.build(
        nowUtc: now,
        operatorId: 'op',
        deviceId: 'dev',
        autoFill: const <String, bool>{'gpsLat': false},
        gpsLat: 1,
        gpsLon: 2,
      );
      expect(values['operator'], 'op');
      expect(values['device'], 'dev');
      expect(values.containsKey('gpsLat'), isFalse);
    });

    test('record numbers consecutive', () {
      expect(RecordNumber.allocateRange(0, 20), hasLength(20));
      expect(RecordNumber.allocateRange(0, 20).toSet(), hasLength(20));
      expect(RecordNumber.next(5), 6);
    });

    test('gps off makes no location call', () async {
      final List<String> calls = <String>[];
      final Result<GeoFix?> result = await GpsCapture.maybeFix(
        gpsEnabled: false,
        location: LocationService.fake(calls: calls),
      );
      expect(result.getOrElse(() => null), isNull);
      expect(calls, isEmpty);
    });
  });

  group('save paths', () {
    test('failed enqueue leaves captured record', () async {
      final Result<SaveAndAnalyseResult> result = await SaveAndAnalyse.run(
        session: const CaptureSession(
          id: 's',
          templateId: 't',
          contextSnapshot: <String, String>{},
          photos: <PhotoDraft>[
            PhotoDraft(
              id: 'p',
              projectId: 'proj',
              relativePath: 'a.jpg',
              sha256: 'h',
            ),
          ],
        ),
        persist: (CaptureSession _) async => const Success<String>('rec1'),
        enqueue: (String _) async => const FailureResult<ProcessingJob>(
          StorageFailure(message: 'offline', recoveryAction: 'retry'),
        ),
      );
      expect(
        result
            .fold((Failure _) => null, (SaveAndAnalyseResult r) => r)
            ?.recordId,
        'rec1',
      );
      expect(
        result
            .fold((Failure _) => null, (SaveAndAnalyseResult r) => r)
            ?.enqueueFailed,
        isTrue,
      );
    });

    test('raw save silent', () async {
      var outbound = 0;
      final Result<String> result = await SaveRaw.run(
        session: const CaptureSession(
          id: 's',
          templateId: 't',
          contextSnapshot: <String, String>{},
          captions: <String, String>{'': 'note'},
        ),
        persist: (CaptureSession _) async {
          outbound++;
          return const Success<String>('rec');
        },
      );
      expect(result.getOrElse(() => ''), 'rec');
      expect(outbound, 1);
    });
  });

  group('reset transcript', () {
    test('reset keeps context template', () {
      final CaptureSession next = CaptureReset.next(
        previous: const CaptureSession(
          id: 'old',
          projectId: 'p',
          templateId: 't1',
          contextSnapshot: <String, String>{'site': 'A'},
          photos: <PhotoDraft>[
            PhotoDraft(
              id: 'ph',
              projectId: 'p',
              relativePath: 'a.jpg',
              sha256: 'h',
            ),
          ],
        ),
        ids: UuidV7Service.sequence(FixedClock(DateTime.utc(2026))),
      );
      expect(next.id, isNot('old'));
      expect(next.photos, isEmpty);
      expect(next.templateId, 't1');
      expect(next.contextSnapshot['site'], 'A');
    });

    test('transcript unchanged by refinement', () {
      const TranscriptStore raw = TranscriptStore(
        text: 'hello',
        languageTag: 'en',
        confidence: 0.9,
      );
      expect(raw.unchangedByRefinement.text, 'hello');
    });
  });
}
