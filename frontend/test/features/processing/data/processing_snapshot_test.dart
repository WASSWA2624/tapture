import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/db/tables/captions.dart';
import 'package:tapture/features/processing/data/processing_snapshot.dart';
import 'package:tapture/features/processing/data/record_bundle.dart';

import '../../../support/processing_fixture.dart';

void main() {
  late ProcessingFixture fixture;
  setUp(() async {
    fixture = await ProcessingFixture.open();
    await fixture.addField('serial', required: true);
  });

  Future<String> revision({
    String provider = 'backend',
    String privacy = 'false',
    double cap = 0,
  }) async {
    final RecordBundle bundle = await fixture.bundle();
    return ProcessingSnapshot.revision(
      bundle,
      privacyRevision: privacy,
      sources: const <Map<String, Object?>>[
        <String, Object?>{
          'id': 'caption:c1',
          'kind': 'caption',
          'text': 'pump',
        },
      ],
      provider: provider,
      model: 'default',
      language: 'en',
      holdImages: false,
      maxCost: cap,
    );
  }

  test(
    'unchanged content has one identity despite queue lifecycle changes',
    () async {
      final String before = await revision();
      await fixture.job();
      expect(await revision(), before);
      expect(before, matches(RegExp(r'^[a-f0-9]{64}$')));
    },
  );

  test(
    'template requirements and context edits invalidate extraction',
    () async {
      final String first = await revision();
      await fixture.addField('year', required: true);
      final String fields = await revision();
      expect(fields, isNot(first));
      await fixture.setContext('{"room":"Workshop"}');
      expect(await revision(), isNot(fields));
    },
  );

  test('caption edits preserve originals and invalidate extraction', () async {
    final Photo photo = await fixture.db.select(fixture.db.photos).getSingle();
    final Caption caption = (await insertCaption(
      fixture.db,
      row: CaptionsCompanion(
        ownerType: const Value<CaptionOwnerType>(CaptionOwnerType.photo),
        ownerId: Value<String>(photo.id),
        textRaw: const Value<String>('pump'),
        inputMode: const Value<CaptionInputMode>(CaptionInputMode.typed),
      ),
      clock: fixture.clock,
      deviceId: 'device-a',
      ids: fixture.ids,
    )).getOrThrow();
    final String original = await revision();
    (await writeCaptionRefined(
      fixture.db,
      id: caption.id,
      textRefined: 'The pump',
      clock: fixture.clock,
      deviceId: 'device-a',
      ids: fixture.ids,
    )).getOrThrow();
    expect(await revision(), isNot(original));
    expect(
      (await fixture.db.select(fixture.db.captions).getSingle()).textRaw,
      'pump',
    );
  });

  test(
    'photo content privacy provider and approved spending change identities',
    () async {
      final String original = await revision();
      expect(await revision(provider: 'personal-openai'), isNot(original));
      expect(await revision(privacy: 'protected'), isNot(original));
      expect(await revision(cap: 1), isNot(original));
      await (fixture.db.update(
        fixture.db.photos,
      )).write(const PhotosCompanion(sha256: Value<String>('changed-photo')));
      expect(await revision(), isNot(original));
    },
  );

  test(
    'crash resumes reuse identity while batches repairs and approved retries differ',
    () {
      String id({int generation = 0, int batch = 0, int repair = 0}) =>
          ProcessingSnapshot.requestId(
            revision: 'snapshot',
            recordId: 'record',
            generation: generation,
            batch: batch,
            repair: repair,
          );
      expect(id(), id());
      expect(<String>{
        id(),
        id(batch: 1),
        id(repair: 1),
        id(generation: 1),
      }, hasLength(4));
    },
  );
}
