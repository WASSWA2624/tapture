import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:tapture/core/constants/app_constants.dart';
import 'package:tapture/core/db/app_database.dart';
import 'package:tapture/core/errors/failure.dart';
import 'package:tapture/core/errors/result.dart';
import 'package:tapture/core/files/evidence_purge.dart';
import 'package:tapture/core/files/storage_root.dart';
import 'package:tapture/core/time/clock.dart';
import 'package:tapture/features/records/data/record_purge_store.dart';
import 'package:tapture/features/records/domain/purge_candidate.dart';
import 'package:tapture/features/records/domain/purge_job.dart';
import 'package:tapture/features/records/domain/purge_report.dart';

import '../../../core/db/record_rows.dart';
import '../fakes/record_results.dart';

final DateTime _now = DateTime.utc(2026, 9, 27, 9);

/// Unix seconds [days] whole days before [_now], as drift stores instants.
int _secondsAgo(int days) =>
    _now.subtract(Duration(days: days)).millisecondsSinceEpoch ~/ 1000;

DateTime _instantAgo(int days) => _now.subtract(Duration(days: days));

const String _operatorReason = 'Deleted by the operator.';
const String _projectDeleted = 'Project deleted';

void main() {
  test('a recent deletion survives a purge run and an unmerged tombstone is '
      'skipped', () async {
    final _Purge purge = await _Purge.open();
    await purge.project('p2', folder: 'site-b');
    // Project p2 exchanges packages: a bundle left before its deletion.
    await purge.export('x1', projectId: 'p2', daysAgo: 60);

    await purge.binned('old', daysAgo: 40);
    await purge.photo('ph-old', recordId: 'old');
    await purge.binned('recent', daysAgo: 5);
    await purge.photo('ph-recent', recordId: 'recent');
    await purge.binned('conflicted', daysAgo: 90);
    await seedField(
      purge.db,
      'f-conflicted',
      recordId: 'conflicted',
      fieldKey: 'serial',
      raw: 'S-1',
    );
    await purge.conflict('c1', entityId: 'f-conflicted');
    await purge.photo('ph-conflicted', recordId: 'conflicted');
    await purge.binned('untravelled', projectId: 'p2', daysAgo: 40);
    await purge.photo(
      'ph-untravelled',
      recordId: 'untravelled',
      projectId: 'p2',
      folder: 'site-b',
    );

    final PurgeReport report = okOf(await purge.job().run());

    expect(
      report,
      const PurgeReport(
        purged: 1,
        skippedRecent: 1,
        skippedMergeNeeded: 2,
        filesRemoved: 6,
      ),
    );
    expect(await purge.ids('records'), <String>[
      'conflicted',
      'recent',
      'untravelled',
    ]);
    expect(purge.photoFiles('ph-old').where(purge.exists), isEmpty);
    for (final String kept in <String>['ph-recent', 'ph-conflicted']) {
      expect(purge.photoFiles(kept).every(purge.exists), isTrue, reason: kept);
    }
    expect(
      purge.photoFiles('ph-untravelled', folder: 'site-b').every(purge.exists),
      isTrue,
    );
    expect(await purge.ids('tombstones', column: 'entity_id'), <String>[
      'conflicted',
      'recent',
      'untravelled',
    ]);

    // A second run finds the survivors where they were.
    expect(
      okOf(await purge.job().run()),
      const PurgeReport(skippedRecent: 1, skippedMergeNeeded: 2),
    );
  });

  test('the bin lists each deleted record once, oldest first, with its '
      'deletion time and whether a merge needs it', () async {
    final _Purge purge = await _Purge.open();
    await purge.binned('newer', daysAgo: 3);
    await purge.binned('older', daysAgo: 45);
    await purge.binned('needed', daysAgo: 20);
    await purge.conflict('c1', entityId: 'needed');

    final List<PurgeCandidate> candidates = okOf(
      await purge.store.candidates(),
    );

    expect(candidates, <PurgeCandidate>[
      PurgeCandidate(
        recordId: 'older',
        projectId: 'p1',
        deletedAt: _instantAgo(45),
      ),
      PurgeCandidate(
        recordId: 'needed',
        projectId: 'p1',
        deletedAt: _instantAgo(20),
        mergeNeeded: true,
      ),
      PurgeCandidate(
        recordId: 'newer',
        projectId: 'p1',
        deletedAt: _instantAgo(3),
      ),
    ]);
    expect(candidates.first.deletedAt.isUtc, isTrue);
  });

  test('a purged record takes every row it owns, its files, its thumbnails '
      'and its search document, and leaves the rest', () async {
    final _Purge purge = await _Purge.open();
    await purge.ownedRecord('old');
    await purge.liveRecord('live');
    expect(await searchDoc(purge.db, 'old'), isNotNull);
    expect(await searchRecords(purge.db, 'Autoclave'), <String>['old']);

    final PurgeReport report = okOf(await purge.job().run());

    // Two photos with five cached copies each, and one audio file.
    expect(report, const PurgeReport(purged: 1, filesRemoved: 13));
    expect(await purge.ids('records'), <String>['live']);
    expect(await purge.ids('record_fields'), <String>['f-live']);
    expect(await purge.ids('field_evidence'), <String>['ev-live-doc']);
    expect(await purge.ids('photos'), <String>['ph-live']);
    expect(await purge.ids('captions'), <String>['cr-live']);
    expect(await purge.ids('attachments'), <String>['att-shared', 'doc-cited']);
    expect(await purge.ids('attachment_owners'), <String>['aos-live']);
    for (final String table in <String>[
      'processing_jobs',
      'processing_results',
      'variances',
      'duplicates',
      'meetings',
      'attendees',
      'meeting_actions',
      'ocr_cache',
      'tombstones',
      'merge_conflicts',
    ]) {
      expect(await purge.ids(table), isEmpty, reason: table);
    }
    expect(await purge.ids('version_vectors'), <String>['vv-live']);
    expect(await purge.ids('audit_log'), <String>['au-live']);
    expect(await searchDoc(purge.db, 'old'), isNull);
    expect(await searchRecords(purge.db, 'Autoclave'), isEmpty);
    expect(await searchRecords(purge.db, 'Boiler'), <String>['live']);
    expect(
      await purge.ids('record_search_pending', column: 'record_id'),
      isEmpty,
    );
    expect(
      await purge.count('SELECT COUNT(*) AS n FROM record_search_hold'),
      0,
    );

    for (final String photo in <String>['ph-old', 'phx-old']) {
      expect(purge.photoFiles(photo).where(purge.exists), isEmpty);
    }
    expect(purge.exists('projects/site-a/audio/att-old.m4a'), isFalse);
    expect(purge.exists('projects/site-a/audio/att-shared.m4a'), isTrue);
    expect(purge.exists('projects/site-a/documents/doc-cited.pdf'), isTrue);
    expect(purge.photoFiles('ph-live').every(purge.exists), isTrue);
  });

  test('a record whose deletion has left in a bundle is purged, and one '
      'whose deletion has not is kept however old', () async {
    final _Purge purge = await _Purge.open();
    await purge.project('p2', folder: 'site-b');
    await purge.project('p3', folder: 'site-c');
    await purge.project('p4', folder: 'site-d');
    // p1: a package came in, and a bundle left after the deletion.
    await purge.session('s1', projectId: 'p1', daysAgo: 60);
    await purge.export('x1', projectId: 'p1', daysAgo: 10);
    await purge.binned('sent', daysAgo: 40);
    // p2: a package came in and nothing has left since.
    await purge.session('s2', projectId: 'p2', daysAgo: 60);
    await purge.binned('unsent', projectId: 'p2', daysAgo: 400);
    // p3: only a spreadsheet left after the deletion; that is no bundle.
    await purge.export('x3', projectId: 'p3', daysAgo: 120);
    await purge.export('x4', projectId: 'p3', daysAgo: 10, formats: '["xlsx"]');
    await purge.binned('sheet-only', projectId: 'p3', daysAgo: 40);
    // p4: no exchange at all, and a conflict that was settled.
    await purge.binned('settled', projectId: 'p4', daysAgo: 40);
    await purge.conflict('c4', entityId: 'settled', resolution: 'mine');
    // A session whose counts are not JSON never breaks the bin.
    await seedRow(purge.db, 'merge_sessions', <String, Object?>{
      'id': 's-bad',
      'bundle_name': 'broken.tapture',
      'source_device': 'device-b',
      'imported_at': _secondsAgo(5),
      'counts': 'not json',
      'status': 'applied',
      'undo_snapshot_path': '',
    });

    final PurgeReport report = okOf(await purge.job().run());

    expect(report, const PurgeReport(purged: 2, skippedMergeNeeded: 2));
    expect(await purge.ids('records'), <String>['sheet-only', 'unsent']);
  });

  test('records removed with their project are never purged', () async {
    final _Purge purge = await _Purge.open();
    await purge.project('p9', folder: 'site-z');
    await purge.tombstone('projects', 'p9', daysAgo: 100, reason: 'Removed');
    // Tombstoned by the project delete; the status never changed.
    await seedRecord(purge.db, 'with-project', status: 'captured');
    await purge.tombstone(
      'records',
      'with-project',
      daysAgo: 100,
      reason: _projectDeleted,
    );
    await purge.binned('project-reason', daysAgo: 100, reason: _projectDeleted);
    await purge.binned('dead-project', projectId: 'p9', daysAgo: 100);
    await purge.photo(
      'ph-dead',
      recordId: 'dead-project',
      projectId: 'p9',
      folder: 'site-z',
    );
    // A tombstone on a record that was never moved to deleted.
    await seedRecord(purge.db, 'not-deleted', status: 'approved');
    await purge.tombstone('records', 'not-deleted', daysAgo: 100);
    await purge.binned('plain', daysAgo: 100);

    final List<PurgeCandidate> candidates = okOf(
      await purge.store.candidates(),
    );
    final PurgeReport report = okOf(await purge.job().run(ignoreWindow: true));

    expect(candidates.map((PurgeCandidate c) => c.recordId), <String>['plain']);
    expect(report, const PurgeReport(purged: 1));
    expect(await purge.ids('records'), <String>[
      'dead-project',
      'not-deleted',
      'project-reason',
      'with-project',
    ]);
    expect(
      purge.photoFiles('ph-dead', folder: 'site-z').every(purge.exists),
      isTrue,
    );
  });

  test("a live record's tombstoned photo keeps its row, tombstone and "
      'file, however old', () async {
    final _Purge purge = await _Purge.open();
    await seedRecord(purge.db, 'live');
    await purge.photo('ph-removed', recordId: 'live');
    await purge.tombstone('photos', 'ph-removed', daysAgo: 400);
    await purge.binned('old', daysAgo: 40);
    await purge.photo('ph-old', recordId: 'old');

    okOf(await purge.job().run());

    expect(await purge.ids('photos'), <String>['ph-removed']);
    expect(await purge.ids('tombstones', column: 'entity_id'), <String>[
      'ph-removed',
    ]);
    expect(purge.photoFiles('ph-removed').every(purge.exists), isTrue);
  });

  test('a file or hash another surviving row still names is kept', () async {
    final _Purge purge = await _Purge.open();
    await purge.project('p2', folder: 'site-b');
    await purge.binned('old', daysAgo: 40);
    await purge.photo('ph-old', recordId: 'old', sha: 'shared-sha');
    // The same picture filed on a live record in another project.
    await seedRecord(purge.db, 'live', projectId: 'p2');
    await purge.photo(
      'ph-live',
      recordId: 'live',
      projectId: 'p2',
      folder: 'site-b',
      sha: 'shared-sha',
    );
    // An unfiled photo row that names the same stored file.
    await seedRow(purge.db, 'photos', <String, Object?>{
      ..._photoRow('loose', recordId: null, sha: 'loose-sha'),
      'relative_path': 'photos/ph-old.jpg',
    });
    await purge.ocr('ocr-shared', sha: 'shared-sha');

    final PurgeReport report = okOf(await purge.job().run());

    // Only the copies keyed by the purged photo's own id went.
    expect(report, const PurgeReport(purged: 1, filesRemoved: 2));
    expect(purge.exists('projects/site-a/photos/ph-old.jpg'), isTrue);
    expect(purge.exists('.cache/thumbs/shared-sha_96'), isTrue);
    expect(purge.exists('.cache/thumbs/ph-old_96'), isFalse);
    expect(purge.exists('.cache/capture-src/ph-old'), isFalse);
    expect(await purge.ids('ocr_cache'), <String>['ocr-shared']);
    expect(await purge.ids('photos'), <String>['loose', 'ph-live']);
  });

  test('a stored file that is already gone counts as removed', () async {
    final _Purge purge = await _Purge.open();
    await purge.binned('old', daysAgo: 40);
    await purge.photo('ph-old', recordId: 'old', onDisk: false);

    final PurgeReport report = okOf(await purge.job().run());

    expect(report, const PurgeReport(purged: 1, filesRemoved: 1));
    expect(await purge.ids('photos'), isEmpty);
  });

  test('one failing purge does not stop the others', () async {
    final _Purge purge = await _Purge.open();
    await purge.binned('broken', daysAgo: 50);
    // A stored path that would leave the project folder is never deleted.
    await seedRow(purge.db, 'photos', <String, Object?>{
      ..._photoRow('ph-broken', recordId: 'broken', sha: 'broken-sha'),
      'relative_path': '../../escape.jpg',
    });
    await purge.binned('old', daysAgo: 40);
    await purge.photo('ph-old', recordId: 'old');
    await purge.binned('older', daysAgo: 60);

    final PurgeReport report = okOf(await purge.job().run());

    expect(report, const PurgeReport(purged: 2, failed: 1, filesRemoved: 6));
    expect(await purge.ids('records'), <String>['broken']);
    expect(await purge.ids('photos'), <String>['ph-broken']);
    expect(await purge.ids('tombstones', column: 'entity_id'), <String>[
      'broken',
    ]);
    final PurgeCandidate broken = okOf(await purge.store.candidates()).single;
    expect(
      failureOf(await purge.store.purge(broken)),
      isA<ValidationFailure>(),
    );
  });

  test('a file that cannot be removed keeps every row of its record', () async {
    const StorageFailure refused = StorageFailure(
      message: 'The photo could not be removed.',
      recoveryAction: 'Try again later.',
    );
    final _Purge purge = await _Purge.open(
      files: (EvidencePurge real) => _RefusingPurge(real, refused),
    );
    await purge.ownedRecord('old');

    final PurgeCandidate candidate = okOf(
      await purge.store.candidates(),
    ).single;
    expect(failureOf(await purge.store.purge(candidate)), refused);
    final PurgeReport report = okOf(await purge.job().run());

    expect(report, const PurgeReport(failed: 1));
    expect(await purge.ids('records'), <String>['old']);
    expect(await purge.ids('photos'), <String>['ph-old', 'phx-old']);
    expect(await purge.ids('record_fields'), <String>['f-old']);
    expect(await searchDoc(purge.db, 'old'), isNotNull);
    expect(purge.photoFiles('ph-old').every(purge.exists), isTrue);
  });

  test('a row that cannot be deleted keeps every row; the next run finishes '
      'the record', () async {
    final _Purge purge = await _Purge.open();
    await purge.ownedRecord('old');
    await purge.db.customStatement(
      'CREATE TRIGGER keep_variances BEFORE DELETE ON variances '
      "BEGIN SELECT RAISE(ABORT, 'kept'); END",
    );

    final PurgeReport failedRun = okOf(await purge.job().run());

    expect(failedRun, const PurgeReport(failed: 1));
    expect(await purge.ids('records'), <String>['old']);
    expect(await purge.ids('photos'), <String>['ph-old', 'phx-old']);
    expect(await purge.ids('audit_log'), <String>[
      'au-old',
      'au-old-caption',
      'au-old-photo',
    ]);
    expect(await searchDoc(purge.db, 'old'), isNotNull);
    // Files go first, so they are already gone; the rows wait for the next
    // run, which counts the missing stored files (two photos, three
    // attachments) as removed.
    expect(purge.photoFiles('ph-old').where(purge.exists), isEmpty);

    await purge.db.customStatement('DROP TRIGGER keep_variances');
    final PurgeReport secondRun = okOf(await purge.job().run());

    expect(secondRun, const PurgeReport(purged: 1, filesRemoved: 5));
    expect(await purge.ids('records'), isEmpty);
  });

  test('a record restored after it was listed is not purged, nor one '
      'deleted again since', () async {
    final _Purge purge = await _Purge.open();
    await purge.binned('restored', daysAgo: 40);
    await purge.photo('ph-restored', recordId: 'restored');
    await purge.binned('again', daysAgo: 40);
    final List<PurgeCandidate> listed = okOf(await purge.store.candidates());

    // Restored from the bin, and deleted again today.
    await purge.db.customStatement(
      "UPDATE records SET status = 'captured' WHERE id = 'restored'",
    );
    await purge.db.customStatement(
      "DELETE FROM tombstones WHERE entity_id = 'restored'",
    );
    await purge.db.customStatement(
      'UPDATE tombstones SET deleted_at = ? WHERE entity_id = ?',
      <Object?>[_secondsAgo(0), 'again'],
    );

    for (final PurgeCandidate candidate in listed) {
      expect(
        failureOf(await purge.store.purge(candidate)),
        isA<ValidationFailure>(),
        reason: candidate.recordId,
      );
    }
    expect(await purge.ids('records'), <String>['again', 'restored']);
    expect(purge.photoFiles('ph-restored').every(purge.exists), isTrue);
  });

  test('a merge that starts needing a record after it was listed stops its '
      'purge', () async {
    final _Purge purge = await _Purge.open();
    await purge.binned('old', daysAgo: 40);
    await purge.photo('ph-old', recordId: 'old');
    final PurgeCandidate listed = okOf(await purge.store.candidates()).single;
    await purge.conflict('c1', entityId: 'ph-old');

    expect(
      failureOf(await purge.store.purge(listed)),
      isA<ValidationFailure>(),
    );
    expect(await purge.ids('records'), <String>['old']);
    expect(purge.photoFiles('ph-old').every(purge.exists), isTrue);
  });

  test('nothing leaves storage without an explicit action or an expired '
      'window', () async {
    final _Purge purge = await _Purge.open();
    for (final int days in <int>[0, 10, 29]) {
      await purge.binned('r$days', daysAgo: days);
      await purge.photo('ph-r$days', recordId: 'r$days');
    }
    await purge.binned('needed', daysAgo: 400);
    await purge.photo('ph-needed', recordId: 'needed');
    await purge.conflict('c1', entityId: 'needed');
    await purge.liveRecord('live');
    final Set<String> filesBefore = purge.allFiles();
    final Map<String, List<String>> rowsBefore = await purge.allRows();

    final PurgeReport windowed = okOf(await purge.job().run());

    expect(
      windowed,
      const PurgeReport(skippedRecent: 3, skippedMergeNeeded: 1),
    );
    expect(purge.allFiles(), filesBefore);
    expect(await purge.allRows(), rowsBefore);

    // Emptying the bin is the explicit action: it ignores the window, and
    // still leaves what a merge needs and every live record.
    final PurgeReport emptied = okOf(await purge.job().run(ignoreWindow: true));

    expect(
      emptied,
      const PurgeReport(purged: 3, skippedMergeNeeded: 1, filesRemoved: 18),
    );
    expect(await purge.ids('records'), <String>['live', 'needed']);
    expect(purge.photoFiles('ph-needed').every(purge.exists), isTrue);
    expect(purge.photoFiles('ph-live').every(purge.exists), isTrue);
  });

  test('lists watching the database hear the purge', () async {
    final _Purge purge = await _Purge.open();
    await purge.binned('old', daysAgo: 40);
    final Stream<List<String>> ids = purge.db
        .select(purge.db.records)
        .watch()
        .map(
          (List<RecordRow> rows) => <String>[
            for (final RecordRow row in rows) row.id,
          ],
        );
    final Future<void> heard = expectLater(
      ids,
      emitsInOrder(<Object>[
        <String>['old'],
        isEmpty,
      ]),
    );
    await pumpEventQueue();

    okOf(await purge.job().run());
    await heard;
  });

  test('a bin that cannot be read fails the run and removes nothing', () async {
    final _Purge purge = await _Purge.open();
    await purge.binned('old', daysAgo: 40);
    await purge.photo('ph-old', recordId: 'old');
    await purge.db.customStatement('DROP TABLE merge_sessions');

    expect(failureOf(await purge.store.candidates()), isA<StorageFailure>());
    expect(failureOf(await purge.job().run()), isA<StorageFailure>());
    expect(purge.photoFiles('ph-old').every(purge.exists), isTrue);
  });
}

/// A deleted record, its database and its storage folder, over an
/// in-memory database and a temporary storage root.
final class _Purge {
  _Purge._(this.db, this.root, this.store);

  final AppDatabase db;
  final Directory root;
  final RecordPurgeStore store;

  static Future<_Purge> open({
    EvidencePurge Function(EvidencePurge real)? files,
  }) async {
    final AppDatabase db = AppDatabase.memory();
    addTearDown(db.close);
    final Directory documents = Directory.systemTemp.createTempSync(
      'tapture-record-purge-',
    );
    addTearDown(() {
      if (documents.existsSync()) {
        documents.deleteSync(recursive: true);
      }
    });
    final StorageRoot storage = StorageRoot.fake(documentsDirectory: documents);
    final Directory root = okOf(await storage.resolve());
    final EvidencePurge real = EvidencePurge(storageRoot: storage);
    final _Purge purge = _Purge._(
      db,
      root,
      RecordPurgeStore(db: db, files: files == null ? real : files(real)),
    );
    await purge.project('p1', folder: 'site-a');
    return purge;
  }

  /// The launch job over this store, 30 days' retention, at [_now].
  PurgeJob job() {
    return PurgeJob(store: store, clock: FixedClock(_now), retentionDays: 30);
  }

  Future<void> project(String id, {required String folder}) {
    return seedRow(db, 'projects', <String, Object?>{
      'id': id,
      'name': 'Project $id',
      'status': 'active',
      'folder_name': folder,
      'settings': '{}',
    });
  }

  /// A record in the recycle bin: status deleted and a records tombstone
  /// written [daysAgo].
  Future<void> binned(
    String id, {
    String projectId = 'p1',
    required int daysAgo,
    String reason = _operatorReason,
  }) async {
    await seedRecord(db, id, projectId: projectId, status: 'deleted');
    await tombstone('records', id, daysAgo: daysAgo, reason: reason);
  }

  Future<void> tombstone(
    String entityType,
    String entityId, {
    required int daysAgo,
    String reason = 'Removed while editing the record.',
  }) {
    return seedRow(db, 'tombstones', <String, Object?>{
      'id': 'tomb-$entityId',
      'entity_type': entityType,
      'entity_id': entityId,
      'deleted_at': _secondsAgo(daysAgo),
      'deleted_by_device': 'device-a',
      'reason': reason,
    });
  }

  /// A photo row filed on [recordId] and, when [onDisk], its stored file
  /// with every cached copy the app makes of it ([photoFiles]).
  Future<void> photo(
    String id, {
    required String recordId,
    String projectId = 'p1',
    String folder = 'site-a',
    String? sha,
    bool onDisk = true,
  }) async {
    await seedRow(
      db,
      'photos',
      _photoRow(id, recordId: recordId, projectId: projectId, sha: sha),
    );
    if (onDisk) {
      write(photoFiles(id, folder: folder, sha: sha));
    }
  }

  /// The stored file and the five cached copies of photo [id].
  List<String> photoFiles(String id, {String folder = 'site-a', String? sha}) {
    final String hash = sha ?? 'sha-$id';
    final int thumb = AppConstants.images.thumbnailEdge;
    return <String>[
      'projects/$folder/photos/$id.jpg',
      '.cache/thumbs/${hash}_$thumb',
      '.cache/thumbs/${hash}_${AppConstants.images.previewEdge}',
      '.cache/upload/${hash}_${AppConstants.images.longEdge}',
      '.cache/thumbs/${id}_$thumb',
      '.cache/capture-src/$id',
    ];
  }

  Future<void> export(
    String id, {
    required String projectId,
    required int daysAgo,
    String formats = '["bundle","xlsx"]',
  }) {
    return seedRow(db, 'exports', <String, Object?>{
      'id': id,
      'created_at': _secondsAgo(daysAgo),
      'project_id': projectId,
      'version': daysAgo,
      'formats': formats,
      'filters': '{}',
      'record_count': 1,
      'file_path': 'exports/$id.zip',
      'file_hash': 'hash-$id',
      'created_by': 'Ada',
    });
  }

  Future<void> session(
    String id, {
    required String projectId,
    required int daysAgo,
  }) {
    return seedRow(db, 'merge_sessions', <String, Object?>{
      'id': id,
      'bundle_name': 'peer.tapture',
      'source_device': 'device-b',
      'imported_at': _secondsAgo(daysAgo),
      'counts': '{"project_id":"$projectId","records":1}',
      'status': 'applied',
      'undo_snapshot_path': '',
    });
  }

  Future<void> conflict(
    String id, {
    required String entityId,
    String? resolution,
  }) {
    return seedRow(db, 'merge_conflicts', <String, Object?>{
      'id': id,
      'session_id': 's1',
      'entity_type': 'records',
      'entity_id': entityId,
      'field_key': 'status',
      'mine_value': 'deleted',
      'theirs_value': 'approved',
      'mine_meta': '{"kind":"deletedHere"}',
      'theirs_meta': '{}',
      'resolution': resolution,
      'resolved_at': resolution == null ? null : 1,
      'resolved_by': resolution == null ? null : 'Ada',
    });
  }

  Future<void> ocr(String id, {required String sha}) {
    return seedRow(db, 'ocr_cache', <String, Object?>{
      'id': id,
      'content_hash': sha,
      'perceptual_hash': '',
      'recognised_text': 'Serial 123',
      'blocks_json': '[]',
    });
  }

  /// Deleted record [id], 40 days ago, owning one row of every kind the
  /// purge removes: a value with evidence, a live and a tombstoned photo,
  /// captions, attachments (one its own, one shared with `live`, one cited
  /// by `live`'s value), a processing run, a variance, a duplicate pair, a
  /// meeting, OCR text, tombstones, version vectors, a settled conflict and
  /// audit rows. Call [liveRecord] with `live` to complete the shared rows.
  Future<void> ownedRecord(String id) async {
    await binned(id, daysAgo: 40);
    await seedField(
      db,
      'f-$id',
      recordId: id,
      fieldKey: 'name',
      raw: 'Autoclave',
    );
    await photo('ph-$id', recordId: id);
    await photo('phx-$id', recordId: id);
    await tombstone('photos', 'phx-$id', daysAgo: 60);
    await seedEvidence(db, 'ev-$id', fieldId: 'f-$id', photoId: 'ph-$id');
    await seedCaption(
      db,
      'cr-$id',
      ownerType: 'record',
      ownerId: id,
      text: 'Record caption',
    );
    await seedCaption(
      db,
      'cp-$id',
      ownerType: 'photo',
      ownerId: 'ph-$id',
      text: 'Photo caption',
    );
    await tombstone('captions', 'cp-$id', daysAgo: 45);
    await _attachment('att-$id', folder: 'audio', extension: 'm4a');
    await _owner('ao-$id', attachmentId: 'att-$id', type: 'record', id: id);
    await _attachment('att-shared', folder: 'audio', extension: 'm4a');
    await _owner(
      'aos-$id',
      attachmentId: 'att-shared',
      type: 'photo',
      id: 'ph-$id',
    );
    await _attachment('doc-cited', folder: 'documents', extension: 'pdf');
    await _owner('aod-$id', attachmentId: 'doc-cited', type: 'record', id: id);
    await seedRow(db, 'processing_jobs', <String, Object?>{
      'id': 'job-$id',
      'record_id': id,
      'stage': '',
      'status': 'completed',
      'queued_at': 1,
    });
    await seedRow(db, 'processing_results', <String, Object?>{
      'id': 'res-$id',
      'job_id': 'job-$id',
      'request_summary': '{"kind":"transcript"}',
      'raw_response': 'Spoken words',
      'parsed_ok': 1,
    });
    await seedRow(db, 'variances', <String, Object?>{
      'id': 'var-$id',
      'project_id': 'p1',
      'record_id': id,
      'field_key': 'name',
      'status': 'open',
    });
    await seedRow(db, 'duplicates', <String, Object?>{
      'id': 'dup-$id',
      'project_id': 'p1',
      'left_record_id': 'live',
      'right_record_id': id,
      'signal': 'identity',
      'score': 0.9,
      'status': 'unresolved',
    });
    await seedRow(db, 'meetings', <String, Object?>{
      'id': 'm-$id',
      'record_id': id,
      'title': 'Site meeting',
      'start_at': 1,
      'agenda': '',
      'transcript_raw': '',
    });
    await seedRow(db, 'attendees', <String, Object?>{
      'id': 'at-$id',
      'meeting_id': 'm-$id',
      'name': 'Ada',
      'signature_present': 0,
    });
    await seedRow(db, 'meeting_actions', <String, Object?>{
      'id': 'ma-$id',
      'meeting_id': 'm-$id',
      'action': 'Replace the seal',
      'owner_name': 'Ada',
      'due_date': 1,
      'status': 'open',
    });
    await ocr('ocr-$id', sha: 'sha-ph-$id');
    await _vector('vv-$id', entityType: 'records', entityId: id);
    await _vector('vvp-$id', entityType: 'photos', entityId: 'ph-$id');
    await conflict('mc-$id', entityId: id, resolution: 'mine');
    await _audit('au-$id', entityType: 'records', entityId: id);
    await _audit('au-$id-caption', entityType: 'captions', entityId: id);
    await _audit('au-$id-photo', entityType: 'photos', entityId: 'ph-$id');
  }

  /// A live record [id] with a value, a photo, a caption, a link to the
  /// shared attachment, a value citing the cited document, a version
  /// vector and an audit row.
  Future<void> liveRecord(String id) async {
    await seedRecord(db, id);
    await seedField(db, 'f-$id', recordId: id, fieldKey: 'name', raw: 'Boiler');
    await photo('ph-$id', recordId: id);
    await seedCaption(
      db,
      'cr-$id',
      ownerType: 'record',
      ownerId: id,
      text: 'Live caption',
    );
    await _owner('aos-$id', attachmentId: 'att-shared', type: 'record', id: id);
    await seedRow(db, 'field_evidence', <String, Object?>{
      'id': 'ev-$id-doc',
      'record_field_id': 'f-$id',
      'source_type': 'document',
      'document_id': 'doc-cited',
    });
    await _vector('vv-$id', entityType: 'records', entityId: id);
    await _audit('au-$id', entityType: 'records', entityId: id);
  }

  Future<void> _attachment(
    String id, {
    required String folder,
    required String extension,
  }) async {
    final String relative = '$folder/$id.$extension';
    await seedRow(db, 'attachments', <String, Object?>{
      'id': id,
      'project_id': 'p1',
      'relative_path': relative,
      'mime_type': 'application/octet-stream',
      'file_size': 3,
      'sha256': 'sha-$id',
      'kind': folder == 'audio' ? 'audio' : 'document',
    });
    write(<String>['projects/site-a/$relative']);
  }

  Future<void> _owner(
    String ownerRowId, {
    required String attachmentId,
    required String type,
    required String id,
  }) {
    return seedRow(db, 'attachment_owners', <String, Object?>{
      'id': ownerRowId,
      'attachment_id': attachmentId,
      'owner_type': type,
      'owner_id': id,
    });
  }

  Future<void> _vector(
    String id, {
    required String entityType,
    required String entityId,
  }) {
    return seedRow(db, 'version_vectors', <String, Object?>{
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'device_id': 'device-b',
      'seen_rev': 1,
    });
  }

  Future<void> _audit(
    String id, {
    required String entityType,
    required String entityId,
  }) {
    return seedRow(db, 'audit_log', <String, Object?>{
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': 'created',
      'operator': '',
      'device': 'device-a',
      'at': 1,
    });
  }

  /// Writes a small file at each of [paths], relative to the storage root.
  void write(Iterable<String> paths) {
    for (final String path in paths) {
      File('${root.path}/$path')
        ..createSync(recursive: true)
        ..writeAsBytesSync(<int>[1, 2, 3]);
    }
  }

  bool exists(String path) => File('${root.path}/$path').existsSync();

  /// Every file under the storage root, relative to it.
  Set<String> allFiles() {
    final String prefix = '${root.path.replaceAll(r'\', '/')}/';
    return <String>{
      for (final FileSystemEntity entity in root.listSync(recursive: true))
        if (entity is File)
          entity.path.replaceAll(r'\', '/').substring(prefix.length),
    };
  }

  /// Ids in [table]'s [column], sorted.
  Future<List<String>> ids(String table, {String column = 'id'}) async {
    final List<QueryRow> rows = await db
        .customSelect('SELECT $column AS id FROM $table ORDER BY $column')
        .get();
    return <String>[for (final QueryRow row in rows) row.read<String>('id')];
  }

  Future<int> count(String sql) async {
    final QueryRow row = await db.customSelect(sql).getSingle();
    return row.read<int>('n');
  }

  /// Every row id of every table the purge can touch.
  Future<Map<String, List<String>>> allRows() async {
    return <String, List<String>>{
      for (final String table in _purgedTables) table: await ids(table),
      'record_search_docs': await ids(
        'record_search_docs',
        column: 'record_id',
      ),
    };
  }
}

const List<String> _purgedTables = <String>[
  'records',
  'record_fields',
  'field_evidence',
  'photos',
  'captions',
  'attachments',
  'attachment_owners',
  'processing_jobs',
  'processing_results',
  'variances',
  'duplicates',
  'meetings',
  'attendees',
  'meeting_actions',
  'ocr_cache',
  'tombstones',
  'version_vectors',
  'merge_conflicts',
  'audit_log',
];

/// A photo row filed on [recordId] (or unfiled when null), stored at
/// `photos/<id>.jpg` in its project folder.
Map<String, Object?> _photoRow(
  String id, {
  required String? recordId,
  String projectId = 'p1',
  String? sha,
}) {
  return <String, Object?>{
    'id': id,
    'project_id': projectId,
    'record_id': recordId,
    'capture_session_id': 'session-1',
    'original_filename': '$id.jpg',
    'stored_filename': '$id.jpg',
    'relative_path': 'photos/$id.jpg',
    'photo_type': 'front',
    'sort_order': 0,
    'width': 2,
    'height': 2,
    'file_size': 3,
    'mime_type': 'image/jpeg',
    'sha256': sha ?? 'sha-$id',
    'captured_at': 1,
  };
}

/// The device purge, except that every photo removal is refused with
/// [_failure]: a file the platform will not delete.
final class _RefusingPurge implements EvidencePurge {
  _RefusingPurge(this._real, this._failure);

  final EvidencePurge _real;
  final Failure _failure;

  @override
  Future<Result<int>> removePhotos(List<PurgePhoto> photos) async {
    return FailureResult<int>(_failure);
  }

  @override
  Future<Result<int>> removeFiles(List<String> storagePaths) {
    return _real.removeFiles(storagePaths);
  }
}
